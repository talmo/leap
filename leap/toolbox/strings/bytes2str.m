function [str, x_bytes, unit] = bytes2str(bytes, precision)
%BYTES2STR Returns the number of bytes in a more readable format.
% Usage:
%   bytes2str(bytes)
%   str = bytes2str(bytes)
%   str = bytes2str(filename)
%   str = bytes2str(_, precision)
%   [str, x_bytes, unit] = bytes2str(...)

if ischar(bytes)
    bytes = get_filesize(bytes);
end
if nargin < 2
    precision = 3;
end

units = {'bytes', 'KB', 'MB', 'GB', 'TB', 'PB'};

% Find closest units
base = floor(log(bytes) / log(1024));

% Convert to new units
x_bytes = bytes * (1024 ^ -base);

% Convert to string
unit = units{base + 1};
str = sprintf('%s %s', num2str(x_bytes, precision), unit);

end

