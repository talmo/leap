function new_path = extrep(filepath, new_ext)
%EXTREP Replace the extension of a file path.
% Usage:
%   newpath = extrep(filepath, old_ext, new_ext)
% 
% Args:
%   filepath: a path to a file with an extension
%   new_ext: new file extension
%
% Returns:
%   new_path: path with extension replaced
% 
% See also: get_ext, dir_ext

if new_ext(1) == '.'; new_ext = new_ext(2:end); end

pattern = '(?<=\.)[^\\/.]+$';
new_path = regexprep(filepath, pattern, new_ext);

end
