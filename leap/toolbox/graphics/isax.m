function TF = isax(h)
%ISAX Check if input is an axes handle.
% Usage:
%   TF = isax(h)
% 
% Args:
%   h: 
% 
% See also: isfig, isgraphics

TF = isa(h,'matlab.graphics.axis.Axes');

end
