function [frames, numFrames] = h5readframes(filepath, dataset, idx)
%H5READFRAMES Reads video frames from an HDF5 file.
% Usage:
%   frames = h5readframes(filepath)
%   frames = h5readframes(filepath, idx)
%   frames = h5readframes(filepath, dataset)
%   frames = h5readframes(filepath, dataset, idx)
%   [frames, numFrames] = h5readframes(_)
%
% See also: h5att2struct, h5struct2att, h5size

if nargin < 2; dataset = []; end
if nargin < 3; idx = []; end

if (isnumeric(dataset) && ~isempty(dataset)) || ischar(idx)
    tmp = idx;
    idx = dataset;
    dataset = tmp;
end

if isempty(dataset)
    dataset = '/video/data';
    if contains(filepath,'fg.h5'); dataset = '/fg'; end
    if contains(filepath,'box'); dataset = '/box'; end
end

if dataset(1) ~= '/'
    dataset = ['/' dataset];
end

if isempty(idx)
    frames = h5read(filepath, dataset);
else
    startFrame = min(idx);
    endFrame = max(idx);

    stride = 1;
    if numel(idx) > 1
        % Find largest stride that hits every frame
        dFrames = diff(idx);
        dFrames = sort(dFrames,'descend');
        for stride = [horz(dFrames) 1]
            if all(rem(dFrames,stride) == 0); break; end
        end
        
        idx0 = idx; % requested indices
        idx = startFrame:stride:endFrame; % indices to be read
    end
    sz = h5size(filepath, dataset);
    if numel(sz) == 3
        stride = [1 1 max([1 stride])];
        start = [1 1 startFrame];
        count = [inf inf numel(idx)];
    else
        stride = [1 1 1 max([1 stride])];
        start = [1 1 1 startFrame];
        count = [inf inf inf numel(idx)];
    end
    
    frames = h5read(filepath, dataset, start, count, stride);
    
    if numel(idx) > 1
        [~,idx_sub] = ismember(idx0,idx);
        if ndims(frames) == 3
            frames = frames(:,:,idx_sub);
        else
            frames = frames(:,:,:,idx_sub);
        end
    end
end
numFrames = size(frames); numFrames = numFrames(end);

end

