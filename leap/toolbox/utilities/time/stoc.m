function [dt, timer_id] = stoc(timer_id)
%STIC TOC equivalent using precise system time.
% Usage:
%   stoc
%   stoc(timer_id)
%   [dt, timer_id] = stoc
%
% See also: stic, systime

global stic_timers;

if nargin < 1
    timer_id = numel(stic_timers);
end

if numel(stic_timers) == 0
    error('You must call STIC before calling this function.')
end

if ~isscalar(timer_id) || timer_id ~= round(timer_id) || timer_id > numel(stic_timers) || timer_id < 1
    error('Invalid timer ID specified.')
end

dt = systime - stic_timers(timer_id);
% stic_timers(timer_id) = [];

if nargout == 0
    fprintf('[%d] Elapsed time is %f seconds.\n', timer_id, dt)
    clear dt
end
if nargout < 2
    clear timer_id
end

end

