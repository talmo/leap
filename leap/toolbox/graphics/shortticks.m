function shortticks(ax)
%SHORTTICKS Make the axis ticks short.
% Usage:
%   shortticks
%   shortticks(ax)
% 
% See also: noticks

if nargin < 1; ax = gca; end

set(findobj(ax,'-property','TickLength'),'TickLength',[0 0])

end
