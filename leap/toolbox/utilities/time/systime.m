function secs = systime
%SYSTIME Returns precise system time in seconds.
% Usage:
%   secs = systime
%
% Note: This is just a wrapper for GetSystemTimePreciseAsFileTime
%
% See also: GetSystemTimePreciseAsFileTime

if ispc
    [~,win_ver] = system('ver');
    % Ref: https://en.wikipedia.org/wiki/Ver_(command)
    if contains(win_ver,'Version 10')
        secs = GetSystemTimePreciseAsFileTime;
        return
    end
end

% Fallback
secs = now * 86400 - 50522817600; % same units

end

