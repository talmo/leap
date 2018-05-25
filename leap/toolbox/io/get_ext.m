function ext = get_ext(path, no_dot)
%GET_EXT Returns the extension in a path. The path need not exist.
% Usage:
%   ext = get_ext(path)
%   ext = get_ext(paths) % cell array of paths
%   ext = get_ext(_, no_dot) % if true, returns ext without dot (default: false)
%
% Notes:
%   - Extension returned will be the characters after the LAST dot.
%   - Returns '' if path has no extension.
%
% See also: get_filename, fileparts

% Default
if nargin < 2
    no_dot = false;
end

% Regular expression
pattern = '\.[^\\/\.]+$';
if no_dot
    pattern = '(?<=\.)[^\\/.]+$';
end

% Get matches
ext = regexp(path, pattern, 'match', 'once');

end

