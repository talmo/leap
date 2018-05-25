function filter_spec = ext2filter_spec(exts)
%EXT2FILTER_SPEC Generates a filter specification from a list of file extensions.
% Usage:
%   filter_spec = ext2filter_spec(ext) % single extension
%   filter_spec = ext2filter_spec(exts)
%
% See also: uigetfile, uigetdir, uibrowse

if ischar(exts)
    exts = {exts};
end

if ~iscellstr(exts)
    error('Expected a string or cell array of strings.')
end

% Keep only characters afte the period
exts = regexprep(exts, '.*\.', '');

% Create filter specification string
filter_spec = ['*.' strjoin(exts, ';*.')];

end

