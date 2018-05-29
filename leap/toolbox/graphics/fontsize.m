function fontsize(size, h)
%FONTSIZE Sets the fontsize across a graphics object.
% Usage:
%   fontsize(size) % default: gca
%   fontsize(size, fig)
%   fontsize(size, ax)
% 
% See also: fontname

if nargin < 2; h = gca; end

set(findobj(h,'-property','FontSize'),'FontSize',size)

end
