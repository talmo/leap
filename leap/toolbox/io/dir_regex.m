function matches = dir_regex(path, expression, return_paths)
%DIR_REGEX Returns contents in the path matching a regular expression.
% Usage:
%   matches = dir_regex(path, expression)
%   matches = dir_regex(path, expression, true) % returns full paths
%
% See also: regexp, dir_ext, dir_paths

% Default: returns just filenames
if nargin < 3; return_paths = false; end

% Get directory listing
listing = dir_paths(path);

% Test regex
matches = listing(~areempty(regexp(listing, expression)));

% Singleton output
if iscell(matches) && numel(matches) == 1
    matches = matches{1};
end

% Return just the filenames
if ~return_paths
    matches = get_filename(matches);
end

end
