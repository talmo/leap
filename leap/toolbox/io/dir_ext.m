function matches = dir_ext(path, extensions, return_paths)
%DIR_EXT Returns files in a directory with the matching extension.
% Usage:
%   matches = dir_ext(path, extension)
%   matches = dir_ext(path, extensions) % cell array of strings
%   matches = dir_ext(path, _, true) % returns full paths
%
% Note: The leading '.' can be omitted.
%
% See also: dir_regex, dir_paths

if nargin < 2
    extensions = path;
    path = pwd;
end

% Process arguments
if ischar(extensions); extensions = {extensions}; end
if ~iscellstr(extensions)
    error('Extension must be a string or cell array of strings.')
end
if nargin < 3; return_paths = false; end

% Remove leading '.'
extensions = regexprep(extensions, '^\.', '');

% Build regex pattern
pattern = ['\.(' strjoin(extensions, '|') ')$'];

% Test for the extensions
matches = dir_regex(path, pattern, return_paths);

end
