function C = struct2nameval(S)
%STRUCT2NAMEVAL Converts a structure to a cell array of name-value pairs.
% Usage:
%   nameval_cell = struct2nameval(struct)
%
% See also: nameval2struct

% Check input
validateattributes(S, {'struct'}, {'nonempty', 'scalar'})

% Convert to cell array
names = fieldnames(S);
C = cell(1, numel(names) * 2);
C(1:2:end) = names;
C(2:2:end) = struct2cell(S);

end

