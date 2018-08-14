function preds = predict_box(box, modelPath, saveConfmaps)
%PREDICT_BOX Evaluates model predictions on a stack of frames. Wrapper for predict_box.py.
% Usage:
%   preds = predict_box(box, modelPath)
%   preds = predict_box(box, modelPath, saveConfmaps)
%
% Args:
%   box: 4-D array or path to HDF5 file with '/box' dataset
%   modelPath: path to model weights
%   saveConfmaps: if true, returns full confidence maps in addition to
%                 peaks (default: false). Very slow and memory intensive!
%   
% Returns:
%   preds: struct containing results from model prediction
%        .positions_pred: 3-D array of (parts x [X Y] x frames) indicating
%                         peak positions for each confidence map in image coordinates
%        .conf_pred: 2-D array of (parts x frames) with the confidence map
%                    value at the peak pixel for detecting bad predictions
%        .confmaps: 4-D array of confidence maps returned if saveConfmaps
%                   is set true

if nargin < 3 || isempty(saveConfmaps); saveConfmaps = false; end

% Process args
delete_box = false;
is_singleton = false;
if ischar(box)
    boxPath = box;
else
    boxPath = [tempname '.h5'];
    
    if numel(size(box)) < 4
        box = repmat(box,[1 1 1 2]);
        is_singleton = true;
    end
    
    h5save(boxPath, box)
    delete_box = true;
end

% Generate temporary output filename
outPath = [tempname '.h5'];

% Build command line args
cmd = {
    'python'
    ['"' ff(funpath(true), 'predict_box.py') '"']
    ['"' boxPath '"']
    ['"' modelPath '"']
    ['"' outPath '"']
    };
if saveConfmaps
    cmd{end+1} = '--save-confmaps';
end
disp(strjoin(cmd))

% Predict
try
    exit_code = system(strjoin(cmd));
catch ME
    if delete_box && exists(boxPath); delete(boxPath); end
    rethrow(ME)
end
if delete_box && exists(boxPath); delete(boxPath); end


% Read data back in
try
    preds = h5readgroup(outPath);
catch ME
    if exists(outPath); delete(outPath); end
    rethrow(ME)
end
if exists(outPath); delete(outPath); end

% Adjust for 0-based indexing
preds.positions_pred = single(preds.positions_pred) + 1;

% Rescale confidence maps to correct range prior to quantization
if saveConfmaps && isfield(preds.Attributes, 'confmaps')
    c_min = preds.Attributes.confmaps.range_min;
    c_max = preds.Attributes.confmaps.range_max;
    preds.confmaps = rescale(single(preds.confmaps) / 255, c_min, c_max);
end

% Adjust for singleton input
if is_singleton
    preds.positions_pred = preds.positions_pred(:,:,1);
    preds.conf_pred = preds.conf_pred(:,1);
    if isfield(preds,'confmaps')
        preds.confmaps = preds.confmaps(:,:,:,1);
    end
end

end
