function varargout = alims(X)
%ALIMS Alias for arange.
% Usage:
%   R = alims(X)
%   [min_val, max_val] = alims(X)
%
% See also: arange

varargout = wrap(@() arange(X), 1:max(1, nargout));

end

