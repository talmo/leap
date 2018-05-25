function formatted = printf(str, varargin)
%PRINTF Prints formatted output.
% Usage:
%   printf(str, ...)
%   formatted = printf(str, ...)
%
% Formatting:
%   - Surround text with '*' for bold or '_' for underlining
%   - Set flags by adding '#[flagname]' to the END of the string
%       Flags:
%       '#nonl': Will not print with a newline at the end of the string.
%       '#[color]': Sets the color of the string.
%                   Ex: '#red', '#blue', '#green', '#orange'
%
% Example:
%   printf('*bold* _underlined_ #red')

if nargin < 1; str = ''; end

% Flag defaults
color = 'black';
appendNewline = true;

% Look for tags
[match, tokens] = regexp(str, '(\s?#\w+)+[\\n]*$', 'match', 'tokens');
%   match: whole match, include possible newline
%   tokens: cell with only the capturing group (the tags)

if ~isempty(match)
    flags = tokens{1}{1};
    
    % Remove the tags from the original string
    str = regexprep(str, [match '$'], strrep(match, flags, ''));
    
    % Process flags
    flags = regexp(flags, '#(\w+)', 'tokens');
    for i = 1:numel(flags)
        flag = flags{i}{1};
        switch flag
            case 'nonl'
                appendNewline = false;
            otherwise
                color = flag;
        end
    end
end

% Add bold tags
str = regexprep(str, '\*(.+?)\*', '<strong>$1</strong>');

% Add underlining (empty link)
str = regexprep(str, '\_(.+?)\_', '<a href="">$1</a>');

% Add color
if ~strcmpi(color, 'black')
    str = ['<font color="' color '">' str '</font>'];
end

% Append newline
endsWithNewline = ~isempty(regexp(str, '\\n(</font>)?$', 'once'));
if ~endsWithNewline && appendNewline
    str = [str '\n'];
end

if nargout < 1
    % Print
    fprintf(str, varargin{:})
else
    % Format
    formatted = sprintf(str, varargin{:});
end
end

