function [ax, b, p] = pareto2(X, leftYLabel, rightYLabel)
%PARETO2 Prettier pareto function.
% Usage:
%   pareto2(X)
%   pareto2(X, leftYLabel, rightYLabel)
%   [ax, b, p] = pareto2(...)
%
% See also: pareto, plotExplainedVar

% Plot
[ax, b, p] = plotyy(1:numel(X), X, 1:numel(X), cumsum(X), 'bar', 'plot');

% Y axes labels
if nargin >= 2; ylabel(ax(1), leftYLabel); end
if nargin >= 3; ylabel(ax(2), rightYLabel); end

% Make it prettier :)
p.LineWidth = 2.0;
axis(ax, 'tight')
grid on

% Fix Y ticks
ax(1).YTickMode = 'auto';
ax(2).YTickMode = 'auto';

if nargout < 1
    clear ax b p
end

end

