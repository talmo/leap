function S = nameval2struct(C)
%NAMEVAL2STRUCT Converts a cell array of name-value pairs to a struct.
% Usage:
%   struct = nameval2struct(nameval_cell)
%
% See also: struct2nameval

C = C(:);

% Check input
validateattributes(C, {'cell'}, {'vector', 'nonempty'})
assert(iseven(length(C)), ...
    'Cell arrays of name-value pairs must have an even number of elements.')
assert(all(cellfun(@ischar, C(1:2:end))), ...
    ['Cell arrays of name-value pairs must be in the format: ' ...
    '{''Name1'', Val1, ..., ''NameN'', ValN}'])

% Fix non-array inputs
N = cellfun(@numel, C(2:2:end));
if numel(unique(N)) ~= 1
    C(2:2:end) = cf(@(x) {x}, C(2:2:end));
end

% Convert to structure
S = struct(C{:});

end

