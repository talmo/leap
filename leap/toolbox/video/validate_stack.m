function [images, numFrames] = validate_stack(images, no_error)
%VALIDATE_STACK Validates a stack of images and converts to 4-D array.
% Usage:
%   images = validate_stack(images)
%   [images, numFrames] = validate_stack(images)
%   _ = validate_stack(images, true) % doesn't error if invalid stack
%
% Returns a WxHxCxF array.
if nargin < 2; no_error = false; end

if isstruct(images) && isfield(images, 'cdata') % getframe struct array
    images = af(@(x) frame2im(x), images);
    images = cat(4, images{:});
end
if iscell(images)
    images = cat(4, images{:});
end
if ndims(images) == 3
    images = permute(images, [1 2 4 3]);
end
if ndims(images) ~= 4
    if ~no_error
        error('Images must be an MxNxCxF array.')
    else
        warning('Images must be an MxNxCxF array.')
    end
end
numFrames = size(images,4);
    
end

