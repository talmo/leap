function TF = exists(path, dir_only)
%EXISTS Returns true if the specified path exists in the filesystem.
% Usage:
%   TF = exists(path)
%   TF = exists(paths)
%   TF = exists(_, dir_only)
%
% Args:
%   path: string path
%   paths: cell array of paths or scalar structure where fields are paths
%   dir_only: if true, returns true only if the path is a folder (default: false)
%
% Notes:
%   - This function differs from exist() in that it returns true only if
%     the path exists in the filesystem.
%     The exist function may return 2 if the path is a file and a function
%     exists in the MATLAB search path but the file does not exist.
%   - Existence is checked using the dir() function.
%
% See also: exist, isfile, isfolder

narginchk(1, 2)
validateattributes(path, {'char', 'cell', 'struct'}, {'nonempty'})

if nargin < 2
    dir_only = false;
end

% Single path specified
if ischar(path)
    path = {path};
end

% Structure of paths specified
struct_output = false;
if isstruct(path)
    fields = fieldnames(path);
    path = struct2cell(path);
    struct_output = true;
end

% Convert [] to ''
path(areempty(path)) = {''};

% Check input
if ~iscellstr(path)
    error('Expected input to be string, cell array of strings or structure of paths.')
end

% Check if paths exist
TF = cellfun(@(p) ~isempty(dir(p)), path);

% Only paths to directories
if dir_only
    TF = TF & isfolder(path);
end

% Return structure
if struct_output
    TF = cell2struct(num2cell(TF), fields);
end

end

