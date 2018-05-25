function idx = argmin(X, dim)
%ARGMAX Returns the index at which the min is found.
% Usage:
%   idx = argmin(X)
%   idx = argmin(X, dim)

if isvector(X)
    [~, idx] = min(X);
else
    if nargin < 2; dim = 1; end
    [~, idx] = min(X, [], dim);
end

end

