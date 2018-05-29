function X = stack2vecs(S)
%STACK2VECS Convert stack to observation-by-features matrix.
% Usage:
%   X = stack2vecs(S)
% 
% Args:
%   S: 4-d array of size [h, w, c, n]
% 
% Returns:
%   X: 2-d array of size [n, (h * w * c)]
% 
% See also: vecs2stack

if ndims(S) == 3; S = permute(S,[1 2 4 3]); end

X = reshape(S,[],size(S,4))';

end
