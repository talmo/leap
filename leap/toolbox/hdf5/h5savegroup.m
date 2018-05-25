function h5savegroup(filepath, S, grp)
%H5SAVEGROUP Description
% Usage:
%   h5savegroup(filepath, S, grp)
% 
% Args:
%   filepath: 
%   S: 
%   grp: 
% 
% See also: h5readgroup

if nargin < 3; grp = inputname(2); end
if isempty(grp); grp = ''; end
if ~startsWith(grp,'/'); grp = ['/' grp]; end

fns = fieldnames(S);
for i = 1:numel(fns)
    if isstruct(S.(fns{i}))
        h5savegroup(filepath, S.(fns{i}), [grp '/' fns{i}])
    else
        h5save(filepath,S.(fns{i}),[grp '/' fns{i}])
    end
end

end
