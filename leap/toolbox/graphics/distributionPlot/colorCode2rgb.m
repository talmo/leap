function rgbVec = colorCode2rgb(c)
%COLORCODE2RGB converts a color code to an rgb vector
%

% SYNOPSIS rgbVec = colorCode2rgb(c)
%
% INPUT c : color code
%       The following colors are supported:
%        'y' 'yellow'
%        'm' 'magenta'
%        'c' 'cyan'
%        'r' 'red'
%        'g' 'green'
%        'b' 'blue'
%        'w' 'white'
%        'k' 'black'
% 
% OUTPUT rgbVec : vector with the rgb value
%
% EXAMPLE 
%    rgb = colorCode2rgb('r')
%    rgb =
%          [1 0 0]

if iscell(c) 
    rgbVec = cell2mat(cellfun(@colorCode2rgb,c,'uni',false));
    return
end

switch c
case {'y','yellow'}, rgbVec = [1,1,0];
case {'m','magenta'}, rgbVec = [1,0,1];
case {'c','cyan'}, rgbVec = [0,1,1];
case {'r','red'}, rgbVec = [1,0,0];
case {'g','green'}, rgbVec = [0,1,0];
case {'b','blue'}, rgbVec = [0,0,1];
case {'w','white'}, rgbVec = [1,1,1];
case {'k','black'}, rgbVec = [0,0,0];
otherwise, error('unknown color code %s',c)
end;
