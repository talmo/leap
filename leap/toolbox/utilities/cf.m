function out = cf(func,varargin)
%CF Convenience wrapper for cellfun with non-uniform output.
% Usage:
%   out = cf(func, C); % equivalent to out = cellfun(func, C, 'UniformOutput, false)

out = cellfun(func, varargin{:}, 'UniformOutput', false);

end

