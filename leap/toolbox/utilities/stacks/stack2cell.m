function C = stack2cell(S)
%STACK2CELL Returns a cell array with one slice of the stack in each cell.
%   C = stack2cell(S)
%
% See also: cat, validate_stack, num2cell, mat2cell

S = validate_stack(S);

C = squeeze(num2cell(S,[1 2 3]));


end

