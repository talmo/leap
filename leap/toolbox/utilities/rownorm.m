function n = rownorm(X, p)
%ROWNORM Returns the row-wise norm of a matrix X.
% Usage:
%   n = rownorm(X)
%   n = rownorm(X, p)
% 
% Args:
%   X: MxN numeric matrix
%   p: degree of norm or 'fro' (default: 2)
% 
% Returns:
%   n: Mx1 vector of norms
% 
% See also: norm, rownorm2

if nargin < 2; p = 2; end

n = sum(X.^p,2).^(1/p);

end
