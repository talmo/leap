function h = plotpts(pts, varargin)
%PLOTPTS Convenience wrapper for plotting scatters. Same syntax as plot().
% Usage:
%   plotpts(pts)
%   plotpts(pts, ...)
%   h = plotpts(_)
%
% See also: plot, scatter

if nargin < 2; varargin = {'.'}; end

h = plot(pts(:,1), pts(:,2), varargin{:});

if isempty(get(gcf,'KeyPressFcn'))
    set(gcf,'KeyPressFcn',@KeyPressFcn_cb)
end

if nargout < 1; clear h; end

end

function KeyPressFcn_cb(h,evt)
if strcmp(evt.Key,'q')
    delete(h)
end
end