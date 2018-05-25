function TF = mkdirto(path)
%MKDIRTO Quietly makes all directories to path that do not currently exist.
% Usage:
%   mkdirto(path)
%   TF = mkdirto(path) % returns true if a folder was created
%
% See also: mkdir

warning('off','MATLAB:MKDIR:DirectoryExists')
if ~isempty(get_ext(path)); path = fileparts(path); end
TF = mkdir(path);
warning('on','MATLAB:MKDIR:DirectoryExists')
if nargout < 1; clear TF; end
end

