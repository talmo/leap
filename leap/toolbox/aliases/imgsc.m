function h = imgsc(I, varargin)
%IMGSC Alias for imagesc for images.
% Usage:
%   imgsc(I)
%   imgsc(I, ...)
%
% See also: imagesc, sc

% figure('KeyPressFcn',@KeyPressFcn_cb)
figclosekey
h = imagesc(I, varargin{:});
H = size(I,1); W = size(I,2);
if  max([H W]) / min([H W]) < 2 || all([H W] < 25)
    axis image
end
colorbar

if nargout < 1; clear h; end

end