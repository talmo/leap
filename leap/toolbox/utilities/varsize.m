function size = varsize(X, units)
%VARSIZE Returns the size of a variable in bytes.
% Usage:
%   size = varsize(X)
%   size = varsize(X, units) % 'bytes' (default), 'KB', 'MB', 'GB'
%
% See also: whos
narginchk(1, 2)
if nargin < 2
    units = 'bytes';
end

% Get variable size in bytes
S = whos('X');
size = S.bytes;

if nargout < 1
    % Just output to console if not storing variable
    disp(bytes2str(size, 4))
    clear size
    return
end

% Convert to units
switch lower(units)
    case {'kb', 'k', 'kilo', 'kilobyte', 'kib'}
        size = size / 1024;
    case {'mb', 'm', 'mega', 'megabyte', 'mib'}
        size = size / 1024 / 1024;
    case {'gb', 'g', 'giga', 'gigabyte', 'gib'}
        size = size / 1024 / 1024 / 1024;
    case {'auto', 'str'}
        size = bytes2str(size, 4);
    otherwise
        return
end

end

