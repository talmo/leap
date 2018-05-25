function bytes = get_filesize(file_path)
%GET_FILESIZE Returns the size of the specified file in bytes.
% This is a wrapper for dir().
%
% Usage:
%   bytes = get_filesize(file_path)
%
% See also: dir

% Get file attributes
attributes = dir(file_path);
bytes = attributes.bytes;

if nargout == 0
    printf('%s: *%s*', get_filename(file_path), bytes2str(bytes))
    clear bytes
end

end

