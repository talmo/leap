function h = hline(y, varargin)
%HLINE Easy plotting of a horizonal line.
% Usage:
%   hline
%   hline(y)
%   hline(ax, _)
%   hline(_, ...) % plot args (e.g., linespec)
%   h = hline(_)
% 
% Args:
%   y: y-value
% 
% See also: vline

if nargin < 1; y = []; end
ax = [];
if isax(y)
    ax = y;
    y = [];
    if nargin > 1
        arg1 = varargin{1};
        if isnumeric(arg1)
            y = arg1;
            varargin(1) = [];
        end
    end
end

if isempty(ax)
    ax = gca;
end

if isempty(y)
    y = mean(ylim(ax));
end

state = ax.NextPlot;
ax.NextPlot = 'add';

X = xlim(ax) .* ones(numel(y),1);
Y = [1 1] .* y(:);
if isvector(y)
    X = [X NaN(size(X,1),1)]';
    Y = [Y NaN(size(Y,1),1)]';
end

h = plot(ax, X(:), Y(:), varargin{:});

ax.NextPlot = state;

if nargout < 1; clear h; end

end
