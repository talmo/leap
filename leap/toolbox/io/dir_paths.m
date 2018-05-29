function [paths, base_path] = dir_paths(path, type)
%DIR_PATHS Returns the full paths of a directory listing.
% Usage:
%   paths = dir_paths % lists paths in pwd
%   paths = dir_paths(path)
%   paths = dir_paths(path, 'files') % 'files', 'folders' or 'both' (default)
%   [paths, base_path] = dir_paths(...)
%
% See also: dir, dir_files, dir_folders

% Process arguments
if nargin < 1; path = pwd; end
if nargin < 2; type = 'both'; end
type = validatestring(type, {'folders', 'files', 'both', 'all'});

% Get directory listing
listing = dir(path);
names = {listing.name}';

% Filter relative names ('.' and '..')
rel_names = cellfun(@(x) isequal(x, '.') || isequal(x, '..'), {listing.name});

% Filter files or folders
folders = [listing.isdir];
files = ~[listing.isdir];
switch type
    case 'folders'
        names = names(folders & ~rel_names);
    case 'files'
        names = names(files & ~rel_names);
    otherwise
        names = names((folders | files) & ~rel_names);
end

% Account for wilcard usage or direct filenames
if instr('*', path) || isfile(path)
    base_path = GetFullPath(fileparts(path)); % get parent directory
else
    base_path = GetFullPath(path);
end
base_path = regexprep(base_path, '[\\/]*$', ''); % remove any trailing slash

% Append base path
paths = fullfile(base_path, names);

end

