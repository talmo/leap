function new_str = get_new_string(str, strings, format)
%GET_NEW_STRING Returns a new string that does not exist in a provided list by incrementing a number.
% Usage:
%   new_str = get_new_string(str, strings)
%   new_str = get_new_string(str, strings, format)
% 
% Args:
%   str: starting string
%   strings: array of strings or cell array of chars
%   format: string format to use (default: '%s_%d')
% 
% See also: get_new_filename, get_new_varname

if nargin < 3 || isempty(format); format = '%s_%d'; end

new_str = str;
i = 0;
while any(strcmp(new_str,strings))
    i = i + 1;
    new_str = sprintf(format, str, i);
end

end
