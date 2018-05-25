function X2 = clip(X, bounds, varargin)
%CLIP Clip values in an array to lower and upper bounds.
% Usage:
%   X2 = clip(X, [lo up])
%   X2 = clip(X, [lo up], 'perc')
% 
% Args:
%   X: numeric array
%   lo: scalar lower bound
%   up: scalar upper bound
%   'perc': use percentiles (0-100)
% 
% See also: rescale, prctile

if nargin > 2; bounds = prctile(X(:),bounds); end

X2 = min(max(X,bounds(1)),bounds(2));

end
