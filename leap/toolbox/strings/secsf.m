function str = secsf(format, numSecs)
%SECSF Yet another seconds formatting function.
% Usage:
%   str = secsf(format, numSecs)
%
% Args:
%   format: formatted string with any of these tokens:
%       No leading zero: %h, %m, %s
%       Leading zero: %H, %M, %S
%       Fractional seconds: %s.ms or %S.ms
%
% See also: secs2str, secs2hms, secstr

if nargin < 2
    [format, numSecs] = swap(format, '%hh %mm %ss');
end    

[h,m,s] = secs2hms(numSecs);

str = format;

str = regexprep(str, '%h', num2str(round(h),'%d'));
str = regexprep(str, '%H', num2str(round(h),'%02d'));

str = regexprep(str, '%m', num2str(round(m),'%d'));
str = regexprep(str, '%M', num2str(round(m),'%02d'));

str = regexprep(str, '%s\.ms', num2str(s,'%f'));
ms = num2str(s-round(s),'%f'); ms = ms(2:end); % '.#####'
str = regexprep(str, '%S\.ms', [num2str(s,'%02d') ms]);

str = regexprep(str, '%s', num2str(round(s),'%d'));
str = regexprep(str, '%S', num2str(round(s),'%02d'));

end

