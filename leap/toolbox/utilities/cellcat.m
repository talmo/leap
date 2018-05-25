function [X,idx] = cellcat(C, dim)
%CELLCAT Unpacks and concatenates a cell array. Shorthand for: cat(dim, C{:})
% Usage:
%   X = cellcat(C)
%   X = cellcat(C, dim)
%   [X, idx] = cellcat(_)
%
% Args:
%   C: cell array
%   dim: dimension along which to concatenate (default = 1)
%       if empty, finds first dimension along which not all sizes are the same
%
% Returns:
%   X: array resulting from concatenating elements of C
%   idx: vector of the same length as X with the corresponding indices in C
%
% See also: cat

if nargin < 2; dim = 1; end
if isempty(dim)
    maxDims = max(cellfun(@ndims, C));
    for dim = 1:maxDims
        sz = cellfun(@(x)size(x,dim), C);
        if nunique(sz) > 1
            break
        end
    end
end

X = cat(dim, C{:});

if nargout > 1
    N = cellfun(@(x)size(x,dim),C);
    idx = repelem(vert(1:numel(C)),N(:));
end

end

