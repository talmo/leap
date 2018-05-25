function TF = iseven(X)
%ISEVEN Returns true if the input is divisible by 2, false otherwise.
% Usage:
%   TF = iseven(X)
%
% See also: mod, rem

TF = logical(mod(X, 2) == 0);

end

