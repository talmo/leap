function [min_val, max_val] = arange(X)
%ARANGE Returns the range (min and max) of an entire array.
% Usage:
%   R = arange(X)
%   [min_val, max_val] = arange(X)
%
% See also: alims, amin, amax

min_val = min(X(:));
max_val = max(X(:));

if nargout < 2
    min_val = [min_val, max_val];
end
end

