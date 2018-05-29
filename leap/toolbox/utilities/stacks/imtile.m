function T = imtile(I, varargin)
%IMTILE Tiles a stack or set of images.
% Usage:
%   T = imtile(stack)
%   T = imtile(I1, I2, ...)
%   T = imtile(stack, cols)
% 
% Args:
%   stack: 3-d, 4-d or cell array of images
%   I1, I2, ...: 2-d images
%   cols: number of columns to use
%
% Returns:
%   T: single tiled image
%
% See also: catpadarr, montage

if ~iscell(I) && ismatrix(I)
   I = {I}; 
end
if ndims(I) == 3
    I = arr2cell(I,3);
end
if ndims(I) == 4
    I = stack2cell(I);
end

cols = [];
if nargin > 1
    if isscalar(varargin{end})
        cols = varargin{end};
        varargin(end) = [];
    end
    I = [horz(I) varargin];
end

N = numel(I);
if isempty(cols); cols = ceil(sqrt(N)); end
rows = ceil(N / cols);

if N < cols*rows
    I((N+1):(cols*rows)) = {zeros(size(I{1}),'like',I{1})};
end

I = reshape(I,cols,rows)';

T = af(@(r)cellcat(I(r,:),2),1:rows);
T = cellcat(T,1);

if nargout < 1; imgsc(T); clear T; end


end

