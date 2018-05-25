function [results, unmatched] = parse_params(args, defaults, varargin)
%PARSE_PARAMS Parses a set of name-value pairs.
% Usage:
%   parsed = parse_params(args, defaults)
%   parsed = parse_params(args, defaults, 'Name', Val, ...)
%   [parsed, unmatched] = parse_params(...)
%
% Args:
%   args: a cell array or structure of name-value pairs
%   defaults: a cell array or structure of name-value pairs
%
% Params:
%   This function takes any public properties of inputParser as parameters,
%   e.g., 'StructExpand'.
%
% Returns:
%   results: a structure containing the parsed results
%   unmatched: a structure containing any args that did not have a default
%
% See also: inputParser, struct2nameval, nameval2struct

% Make sure args are name-val cells
if isstruct(args); args = struct2nameval(args); end

% Make sure defaults are structs
if iscell(defaults); defaults = nameval2struct(defaults); end

% Default inputParser parameters
caller = get_caller_name();
parser_defaults.CaseSensitive = false;
parser_defaults.FunctionName = caller;
parser_defaults.KeepUnmatched = true;
parser_defaults.PartialMatching = true;
parser_defaults.StructExpand = true;

% Parse inputParser parameters
p = inputParser();
p.FunctionName = mfilename;
p = add_params(p, parser_defaults);
p.parse(varargin{:});
parser_params = p.Results;

% Create new inputParser instance
p = inputParser;

% Set inputParser properties from parsed parameters
param_names = fieldnames(parser_params);
for i = 1:numel(param_names)
    p.(param_names{i}) = parser_params.(param_names{i});
end

% Add parameters
p = add_params(p, defaults);

% Parse
p.parse(args{:});

% Return results of parsing
results = p.Results;
unmatched = p.Unmatched;

end

function p = add_params(p, defaults)

% Add defaults as parameters
names = fieldnames(defaults);
for i = 1:numel(names)
    p.addParameter(names{i}, defaults.(names{i}));
end

end
