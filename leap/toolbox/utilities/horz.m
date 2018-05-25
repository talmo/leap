function V = horz(X)
%HORZ Returns the array as a horizontal vector.
% Usage:
%   V = horz(X) % size(V) = [1, numel(X)]

V = X(:)';

end

