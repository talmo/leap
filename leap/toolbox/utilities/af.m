function out = af(func,varargin)
%AF Convenience wrapper for arrayfun with non-uniform output.
% Usage:
%   out = af(func, A); % equivalent to out = arrayfun(func, A, 'UniformOutput, false)

out = arrayfun(func, varargin{:}, 'UniformOutput', false);

end

