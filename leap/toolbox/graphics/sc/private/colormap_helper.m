function map = colormap_helper(map, len, lims)
%COLORMAP_HELPER  Helper function for colormaps
%
% Examples:
%   map = colormap_helper(map);
%   map = colormap_helper(map, len);
%   B = colormap_helper(map, A);
%   B = colormap_helper(map, A, lims);
%
% Given a concise colormap table (i.e. one that contains all the
% information required to create a full colormap, without any redundancy),
% this function can return a colormap of the desired length, or convert a
% real-valued array into truecolor array using the colormap.
%
% IN:
%   map - KxJ colormap table. J = 3, except in the non-linear case, when
%         J = 4, map(1:end-1,4) giving the relative sizes of the 
%         inter-color bins.
%   len - Scalar length of the output colormap. If len == Inf the concise
%         table is returned. Default: len = size(get(gcf, 'Colormap'), 1);
%   A - Non-scalar numeric array of real values to be converted into
%       truecolor.
%   lims - 1x2 array of saturation limits to be used on A. Default:
%          [min(A(:)) max(A(:))].
%
% OUT:
%   map - (len)xJ colormap table. J = 3, except in the concise case, when
%         J = 4, map(1:end-1,4) giving the relative sizes of the 
%         inter-color bins.
%   B - size(A)x3 truecolor array.

% $Id: colormap_helper.m,v 1.4 2009/04/13 12:16:22 ojw Exp $
% Copyright: Oliver Woodford, 2009

if nargin < 2
   len = size(get(gcf, 'Colormap'), 1);
end
if isscalar(len)
    if len == Inf
        % Return the concise colormap table
        return
    end
    len = 1:len;
    sz = numel(len);
    lims = [1 sz];
else
    sz = size(len);
    if nargin < 3
        lims = [];
    end
end
map = reshape(real2rgb(len(:), map, lims), [sz 3]);