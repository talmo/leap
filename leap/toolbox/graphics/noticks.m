function noticks(ax, whichAxes)
%NOTICKS Hides ticks in the axes.
% Usage:
%   noticks
%   noticks('x') % hides only x-ticks
%   noticks(ax, ...)

if nargin == 1
    if ischar(ax)
        whichAxes = ax;
        clear ax
    end
end

% Defaults
if ~exist('whichAxes', 'var'); whichAxes = 'xyz'; end
if ~exist('ax', 'var'); ax = gca; end

for i = 1:numel(ax)
    if any(whichAxes == 'x')
        ax(i).XAxis.TickLength = [0 0];
        ax(i).XAxis.TickLabelsMode = 'manual';
        ax(i).XAxis.TickLabels = {};
    end

    if any(whichAxes == 'y')
        ax(i).YAxis.TickLength = [0 0];
        ax(i).YAxis.TickLabelsMode = 'manual';
        ax(i).YAxis.TickLabels = {};
    end

    if any(whichAxes == 'z')
        ax(i).ZAxis.TickLength = [0 0];
        ax(i).ZAxis.TickLabelsMode = 'manual';
        ax(i).ZAxis.TickLabels = {};
    end
end
end

