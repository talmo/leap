function dir_path = lastdir(new_path)
%LASTDIR Remembers the last directory used for use in UI browsing dialogs.
% Usage:
%   dir_path = lastdir
%   lastuidir(new_path)
%
% Args:
%   new_path: relative or absolute path to a folder or file.
%       Saves parent folder if path to a file is specified.
%
% Returns:
%   dir_path: absolute path to the last used directory (defaults to current
%       directory)

persistent last_dir;
cache_file = fullfile(fileparts(funpath()), '.lastdir');

%% Update last directory
if nargin > 0
    % Get absolute path (pwd if invalid path)
    new_path = GetFullPath(new_path);
    
    % Get folder from path
    if ~isdir(new_path)
        new_path = fileparts(new_path);
    end
    
    % Check if it exists
    if ~exists(new_path)
        error('Specified path does not exist.')
    end
    
    % Check if we changed anything before updating
    path_updated = isequal(last_dir, new_path);
    
    % Update to new path
    last_dir = new_path;
    
    % Write to cache
    if path_updated || ~exists(cache_file)
        try
            f = fopen(cache_file, 'w');
            fprintf(f, '%s', last_dir);
            fclose(f);
        catch
        end
    end
    return
end

%% Get the last directory
if isempty(last_dir) || ~ischar(last_dir) || ~exists(last_dir)
    % Reset to current folder by default
    last_dir = pwd;
    
    % Use last directory from cache file if it exists
    if exists(cache_file)
        cache = fileread(cache_file);
        
        if exists(cache)
            last_dir = cache;
        end
    end
end

%% Return last directory
if nargout > 0
    dir_path = last_dir;
end

%% Output last directory to console
if nargout == 0
    fprintf('Last saved directory: %s\n', last_dir)
end
end

