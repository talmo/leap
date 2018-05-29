function figclosekey(h, key)
%FIGCLOSEKEY Add a hotkey for closing the figure.
% Usage:
%   figclosekey(h, key)
% 
% Args:
%   h: figure handle (default: gcf)
%   key: hotkey to use (default: 'q')
% 
% See also: event, addlistener

if nargin < 2 || isempty(key); key = 'q'; end
if nargin == 1 && ischar(h); [h,key] = swap(h,key); end
if nargin < 1 || isempty(h); h = gcf(); end

if isfield(h.UserData,'hasCloseKey')
    h = figure();
end

set(h, 'KeyPressFcn',@(h,evt)KeyPressFcn_cb(h,evt,key));
h.UserData.hasCloseKey = true;

end

function KeyPressFcn_cb(h,evt,key)
    if strcmp(evt.Key,key)
        delete(h)
    end
end