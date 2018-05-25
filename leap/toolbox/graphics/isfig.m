function TF = isfig(h)
%ISFIG Checks whether the handle(s) specified are existing figures.
% Usage:
%   TF = isfig(h)
%
% See also: isax, isgraphics

% Check if they are existing graphics object handles
TF = ~isempty(h) && ishghandle(h);

% Check if they are figures
TF(TF) = strcmp(get(h(TF), 'type'), 'figure');

end

