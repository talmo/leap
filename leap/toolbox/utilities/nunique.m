function N = nunique(X)
%NUNIQUE Returns the number of unique elements in an array.
% Usage:
%   N = nunique(X)
%
% See also: unique

N = numel(unique(X));
end

