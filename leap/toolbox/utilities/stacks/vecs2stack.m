function S = vecs2stack(X,sz)
%VECS2STACK Convert observation-by-features matrix to stack.
% Usage:
%   X = stack2vecs(S)
% 
% Args:
%   X: 2-d array of size [n, (h * w * c)]
%   sz: [h w c] or [h w c n]
% 
% Returns:
%   S: 4-d array of size [h, w, c, n]
% 
% See also: stack2vecs

if numel(sz) < 3; sz(3) = 1; end
if numel(sz) < 4; sz(4) = size(X,1); end

S = reshape(X',sz);


end
