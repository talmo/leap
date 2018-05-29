function [ax, b, p] = plotExplainedVar(explained)
%PLOTEXPLAINEDVAR Pretty plot PCA explained variance.
% Usage:
%   plotExplainedVar(explained)
%   [ax, b, p] = plotExplainedVar(explained)
%
% See also: pareto2, plotyy

if isstruct(explained) && isfield(explained,'explained'); explained = explained.explained; end

[ax, b, p] = pareto2(explained, 'Component (%)', 'Cumulative (%)');
% b.FaceColor = [0.85 0.325  0.098];
b.FaceColor = [1 1 1] * 0.7;
% b.FaceColor = min(b.FaceColor .* 1.2,1);
% b.FaceAlpha = 0.4;
% p.Color = [1 1 1] .* 0.4;
linkaxes(ax,'x')
xlabel('Principal Components')
title('PCA Explained Variance')

figclosekey
if nargout < 1
    clear ax b p
end
end

