%GETSYSTEMTIMEPRECISEASFILETIME Returns system time with high precision.
% Usage:
%   t = GetSystemTimePreciseAsFileTime
%
% Returns:
%   t: seconds from 00:00:00 UTC, 1/1/1601 with 0.1 ns tick precision
%
% Example:
% >> a = GetSystemTimePreciseAsFileTime
% a =
%    1.3113e+10
% >> b = GetSystemTimePreciseAsFileTime
% b =
%    1.3113e+10
% >> b - a
% ans =
%     4.0448
%
% Reference:
%   https://msdn.microsoft.com/en-us/library/windows/desktop/hh706895(v=vs.85).aspx
%   https://msdn.microsoft.com/en-us/library/windows/desktop/dn553408(v=vs.85).aspx

