function path = funpath(~)
%FUNPATH Returns the path to the calling function.
% Usage:
%   path = funpath()
%   path = funpath(_) % returns the path to the parent directory
%
% See also: get_caller_name, which, dbstack

% Get the path to the calling function
path = get_caller_name('path', true);

% Return the path to the function's parent directory
if nargin > 0
    path = fileparts(path);
end
end

