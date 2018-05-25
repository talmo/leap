function [path, filter_idx]  = uibrowse(filter_spec, start_path, dialog_title, type)
%UIBROWSE Displays a file or folder selection dialog.
% Usage:
%   path = uibrowse
%   path = uibrowse(filter_spec)
%   path = uibrowse(filter_spec, start_path)
%   path = uibrowse(filter_spec, start_path, dialog_title)
%   path = uibrowse(filter_spec, start_path, dialog_title, type)
%   [path, filter_idx] = uibrowse(...)
%
% Args:
%   filter_spec: file filter specification (default = '')
%   start_path: starting path, optionally including filename (default = last
%       used directory)
%   dialog_title: dialog window title (default = 'Select file...')
%   type: 'file': select existing file (default)
%         'savefile': choose filename and location for saving
%         'dir': select folder
%
% Returns:
%   path: absolute path to selection
%   filter_idx: index of the filter specification chosen
%
% Notes:
%   - This function is a wrapper for uigetfile, uiputfile and uigetdir.
%     See the help for those functions for help on filter_spec format, or
%     use ext2filter_spec().
%   - Last directory is remembered between calls to this function.
%   - Error is thrown if the user cancels or does not select a file.
%
% See also: ext2filter_spec, uigetvideo, uigetfile, uigetdir, lastdir

% Default filter specification
if nargin < 1 || isempty(filter_spec)
    filter_spec = '';
end

% Get last directory
if nargin < 2 || isempty(start_path) || ~exists(start_path)
    start_path = lastdir();
end

% Defaults
if nargin < 3; dialog_title = []; end
if nargin < 4; type = 'file'; end
type = validatestring(type, {'file', 'savefile', 'dir'});

% Display browse dialog based on type
switch type
    case 'file'
        if isempty(dialog_title); dialog_title = 'Select file...'; end
        [filename, dir_path, filter_idx] = uigetfile(filter_spec, dialog_title, start_path);
    case 'savefile'
        if isempty(dialog_title); dialog_title = 'Select save location...'; end
        [filename, dir_path, filter_idx] = uiputfile(filter_spec, dialog_title, start_path);
    case 'dir'
        if isempty(dialog_title); dialog_title = 'Select folder...'; end
        dir_path = uigetdir(start_path, dialog_title);
        filename = '';
        filter_idx = [];
end

% Check if user hit Cancel, closed the dialog or didn't select a file
if dir_path == 0
    error('No file or folder selected.')
end

% Save last dir
lastdir(dir_path);

% Return full path to selection
path = fullfile(dir_path, filename);
end

