function varargout = loadvar(mat_file, var_name, varargin)
%LOADVAR Loads one or more variables from a MAT file.
% Usage:
%   X = loadvar(mat_file) % returns first variable in MAT file
%   X = loadvar(mat_file, var_name)
%   [X1, X2, ..., XN] = loadvar(mat_file, var_name1, var_name2, ..., var_nameN)
%   C = loadvar(mat_file, var_names) % variable names in cell; cell output
%
% Notes:
%   - This is a shortcut for loading variables from MAT files without creating
%   a temporary variable to contain the MAT file structure.
%   - The MAT file does not need to have the .mat extension.
% 
% See also: load, who

if ~exists(mat_file); error('MAT file does not exist.'); end

if nargin < 2
    mat_vars = who('-file', mat_file);
    var_name = mat_vars{1};
end

% Check variable names input
var_names = [var_name varargin];
if ~iscellstr(var_names)
    error('Variable names must be specified as strings.')
end

% Load variables from MAT file
X = load(mat_file, '-mat', var_names{:});

% Return output
varargout = cf(@(v) X.(v), var_names);
if nargout ~= numel(varargout)
    varargout = {varargout};
end
end

