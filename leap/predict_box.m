function preds = predict_box(box, model_path, save_confmaps)
%PREDICT_BOX Wrapper for predict_box.py.
% Usage:
%   preds = predict_box(box, model_path, save_confmaps)

if nargin < 3; save_confmaps = false; end

delete_box = false;
is_singleton = false;
if ischar(box)
    box_path = box;
else
    box_path = [tempname '.h5'];
    
    if numel(size(box)) < 4
        box = repmat(box,[1 1 1 2]);
        is_singleton = true;
    end
    
    h5save(box_path, box)
    delete_box = true;
end

out_path = [tempname '.h5'];

cmd = {
    'python'
    ['"' ff(funpath(true), 'predict_box.py') '"']
    ['"' box_path '"']
    ['"' model_path '"']
    ['"' out_path '"']
    };
if save_confmaps
    cmd{end+1} = '--save-confmaps';
end
disp(strjoin(cmd))

try
    exit_code = system(strjoin(cmd));
catch ME
    if delete_box; delete(box_path); end
    rethrow(ME)
end
if delete_box; delete(box_path); end


try
    preds = h5readgroup(out_path);
catch ME
    delete(out_path)
    rethrow(ME)
end
delete(out_path)

preds.positions_pred = single(preds.positions_pred) + 1; % adjust for 0-based indexing

if is_singleton
    preds.positions_pred = preds.positions_pred(:,:,1);
    preds.conf_pred = preds.conf_pred(:,1);
    if isfield(preds,'confmaps')
        preds.confmaps = preds.confmaps(:,:,:,1);
    end
end

end
