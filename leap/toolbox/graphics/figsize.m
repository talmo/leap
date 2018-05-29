function sz = figsize(h, width, height)
%FIGSIZE Resizes the specified figure while keeping it on screen.
% Usage:
%   figsize([width, height])
%   figsize(width, height)
%   figsize % returns figure [width, height]
%   figsize(h, ...)
% 
% Args:
%   h: handle of figure to resize (default: gcf)
%   width: new width ([] = unchanged)
%   height: new height ([] = unchanged)
%
% Returns:
%   sz: [width, height] of the figure. Returns new size if output 
%       specified, if single figure handle specified, or if no args specified
% 
% See also: movegui

if nargin < 1; h = []; end
if nargin < 2; width = []; end
if nargin < 3; height = []; end

args = {h,width,height};

% Figure out figure handle
isfigarg = cellfun(@isfig,args);
if any(isfigarg)
    fig = args{isfigarg};
    args(isfigarg) = [];
else
    fig = gcf;
end

% Get current size
fig_sz = fig.Position(3:4);

% Validate inputs
N = cellfun(@numel, args);
assert(sum(N) <= 2, 'Invalid function syntax.')

% Figure out new dimensions
sz = fig_sz;
if sum(N) == 2 % vector or 2 scalars specified
    sz = [args{:}];
elseif sum(N) == 1 % only 1 term specified
    w = args{1};
    h = args{2};
    if numel(N) == 3 && N(1) < N(3) % {[], [], h} case
        w = args{2};
        h = args{3};
    end
    if isempty(w); w = fig_sz(1); end
    if isempty(h); h = fig_sz(2); end
    sz = [w,h];
end


if ~isequal(fig.Position(3:4),sz)
    % Resize
    fig.Position(3:4) = sz;

    % Keep on screen
    movegui(fig,'onscreen')
end

% Return new size if output specified, if single figure handle specified,
% or if no args specified
if ~(nargout > 0 || (sum(isfigarg) > 0 && nargin == 1) || nargin == 0)
    clear sz
end

end
