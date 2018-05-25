function h = plot_joints_single(pts, segments, markerSize, lineWidth)
%PLOT_JOINTS_SINGLE Plot joints on a single frame.
% Usage:
%   plot_joints_single(pts, segments)
%   plot_joints_single(pts, segments, markerSize, lineWidth)
% 
% Args:
%   pts: 
%   segments (or skeleton): table with line segments or struct containing it
%   markerSize: default: 20
%   lineWidth: default: 2
% 
% See also: 

if isfield(segments,'segments'); segments = segments.segments; end
if nargin < 3 || isempty(markerSize); markerSize = 20; end
if nargin < 4 || isempty(lineWidth); lineWidth = 2; end

h = gobjects(numel(segments.joints_idx),1);
for i = 1:numel(segments.joints_idx)
    h(i) = plotpts(pts(segments.joints_idx{i},:),'.-', ...
        'Color',segments.color{i},'MarkerSize',markerSize,'LineWidth',lineWidth);
end

if nargout < 1; clear h; end

end
