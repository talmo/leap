function S = varstruct(var1, var2, varargin)
%VARSTRUCT Creates a structure out of a set of variables. Fieldnames are inferred from variable names.
% Usage:
%   S = varstruct(var1, var2, ...)
%   S = varstruct('field1', val1, 'field2', val2, ...) % same as struct()
% 
% Args:
%   var1, var2, ...: variables used to create the struct
%       If the variables are defined (see inputname) rather than just
%       passed by value, their workspace names are used as fieldnames.
%   'field1', val1, 'field2', val2, ...: name-value pairs like struct()
%   
% Returns:
%   S: created structure
%
% Note: The two forms of input can be used in the same call.
%       Variables without a name will be named 'varN' according to their
%       position in the argument list.
%
% Example:
% >> S = varstruct(x, y, 'a', 3, 5, 5)
% S = 
%   struct with fields:
% 
%        x: [5×5 double]
%        y: 2
%        a: 3
%     var5: 5
%     var6: 5
%   
% See also: cell2struct, struct, inputname

% Get input names
N = nargin;
names = cell(1,N);
for i = 1:N
    names{i} = inputname(i);
end

% Concatenate all args
args_in = {var1};
if N > 1; args_in{end+1} = var2; end
args_in = [args_in varargin];

% Let's take care of the defined variables first
noName = areempty(names);
args = horz([names(~noName); args_in(~noName)]);

% Now let's take care of name-val pairs
isChar = cellfun(@ischar, args_in);
isName = isChar(1:end-1) & noName(1:end-1) & noName(2:end); % names in name-val pairs are also not named
isVal = [false isName];  % val cannot be first
isName = [isName false]; % name cannot be last
if any(isName)
    name_vals = horz([args_in(isName); args_in(isVal)]);
    args = [args name_vals];
end

% Now let's take care of unnamed args
isUnnamed = noName & ~(isName | isVal);
if any(isUnnamed)
    orderedNames = strcat('var', strsplit(num2str(find(isUnnamed))));
    unnamed_args = horz([orderedNames; args_in(isUnnamed)]);
    args = [args unnamed_args];
end

% Now just create the structure!
% S = struct(args{:});
S = cell2struct(args(2:2:end),args(1:2:end),2); % prevents cell array issues

end