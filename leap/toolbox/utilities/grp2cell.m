function [C, grps, G] = grp2cell(X, G, dim)
%GRP2CELL Splits an array into a cell using a grouping variable.
% Usage:
%   C = grp2cell(X, G)
%   C = grp2cell(X, G, dim)
%   [C, grps] = grp2cell(_)
% 
% Args:
%   X: array with at least one dimension of the same size as G
%   G: grouping variable vector
%   dim: dimension along which to slice X (default: [])
%        if empty, first dimension of the same size as G is used
%
% Returns:
%   C: cell array with as many cells as unique elements in G
%   grps: values in G that correspond to the grouping in C
%
% Example:
%   >> C = grp2cell(X,G,dim);
%   >> isequal(cellcat(C, dim), X)
%   ans =
%     logical
%      1
% 
% See also: arr2cell, cellcat, celljoin

if nargin < 3; dim = []; end
if isscalar(G)
    % Default to first non-singleton dimension
    dim = find(size(X) > 1, 1);
    if isempty(dim); dim = 1; end % or 1
    
    % Create grouping vector
    G = ceil((1:size(X,dim)) / G);
end

if isempty(dim)
    dim = find(size(X) == numel(G),1);
end

subs = af(@(x) 1:x, size(X));

grps = unique(G);
C = cell1(numel(grps),dim);
for i = 1:numel(grps)
    subs_i = subs;
    subs_i{dim} = find(G == grps(i));
    
    C{i} = X(subs_i{:});
end


end
