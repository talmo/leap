function timer_id = stic
%STIC TIC equivalent using precise system time.
% Usage:
%   stic
%   timer_id = tic
%
% See also: stoc, systime

global stic_timers;

timer_id = numel(stic_timers) + 1;
stic_timers(timer_id) = systime;

if nargout < 1
    clear timer_id
end

end

