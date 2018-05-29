function I = ind2im(ind, sz, vals, fillval)
%IND2IM Create image from a set of linear indices.
% Usage:
%   I = ind2im(ind, sz)
%   I = ind2im(ind, sz, vals)
%   I = ind2im(ind, sz, vals, fillval)
%   I = ind2im(BW, vals)
%   I = ind2im(BW, vals, fillval)
%   I = ind2im(S)
% 
% Args:
%   ind: linear indices of the image
%   sz: size of the output image
%   vals: values to fill in with (default: true)
%   S: structure with the fields 'sz, 'vals' and 'ind'
%   fillval: value to fill the rest of the array with
%
% Output:
%   I: image of size sz, the same type as vals, and values filled in at ind
% 
% See also: im2ind, mask2im, ind2sub

if nargin < 4 || isempty(fillval); fillval = 0; end
if nargin < 3 || isempty(vals); vals = []; end
if nargin >= 2 && islogical(ind) && numel(sz) == sum(ind(:))
    if nargin == 3; fillval = vals; end
    vals = sz;
    sz = size(ind);
end
if nargin == 1 && isstruct(ind)
    if isfield(ind,'sz'); sz = ind.sz; end
    if isfield(ind,'size'); sz = ind.size; end
    
    if isfield(ind,'val'); vals = ind.val; end
    if isfield(ind,'vals'); vals = ind.vals; end
    
    if isfield(ind,'ind'); ind = ind.ind; end
    if isfield(ind,'idx'); ind = ind.idx; end
end
if isempty(vals); vals = true; end


I = zeros(sz, 'like', vals);
I(:) = fillval;
I(ind) = vals;

end
