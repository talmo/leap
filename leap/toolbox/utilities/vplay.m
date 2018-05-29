function vp = vplay(mov, varargin)
%VPLAY Play a movie using the vplayer class.
% Usage:
%   vplay(mov)
%   vplay(mov, ...) % name-val params
%   vp = vplay(_)
% 
% Args:
%   mov: 4-d stack, cell array of 2-d images or ind-val structure
% 
% See also: vplayer

vp = vplayer(mov, varargin{:});

if nargout < 1; clear vp; end
end
