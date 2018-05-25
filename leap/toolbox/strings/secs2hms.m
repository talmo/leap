function [h, m, s] = secs2hms(numSecs)
%SECS2HMS Converts a number of seconds to hours, minutes and fractional seconds.
% Usage:
%   hms = secs2hms(numSecs) % numeric vector
%   [h, m, s] = secs2hms(numSecs)
%
% See also: duration, hms, secs2str

[h,m,s] = hms(duration([0 0 numSecs]));

end

