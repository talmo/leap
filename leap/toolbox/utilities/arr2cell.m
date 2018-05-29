function C = arr2cell(X, dim)
%ARR2CELL Splits an array into a cell across the specified dimension.
% Usage:
%   C = arr2cell(X) % default: last dimension
%   C = arr2cell(X, dim)
%
% See also: num2cell, stack2cell

if nargin < 2; dim = ndims(X); end

% Select every other dimension
dims = setdiff(1:ndims(X), dim);

% Convert to cell and squeeze
C = squeeze(num2cell(X,dims));

end

