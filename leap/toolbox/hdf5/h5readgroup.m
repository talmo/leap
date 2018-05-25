function data = h5readgroup(filepath, group)
%H5READGROUP Reads a group into a structure containing all the data in the group.
% Usage:
%   data = h5readgroup(filepath, group)
% 
% Args:
%   filepath: path to the HDF5 file
%   group: name or path to the group
%
% 
% 
% See also: h5read, h5save, h5att2struct

if nargin < 2; group = '/'; end
if group(1) ~= '/'; group = ['/' group]; end

data = struct();
info = h5info(filepath, group);

if ~isempty(info.Groups)
    groups = {info.Groups.Name};
    for i = 1:numel(groups)
        grp_path = strsplit(groups{i},'/');
        field_name = matlab.lang.makeValidName(grp_path{end});
        data.(field_name) = h5readgroup(filepath,groups{i});
    end
end

if ~isempty(info.Attributes)
    data.Attributes = h5att2struct(filepath, group);
end

if ~isempty(info.Datasets)
    datasets = {info.Datasets.Name};
    for i = 1:numel(datasets)
        dset_path = strsplit(datasets{i},'/');
        field_name = matlab.lang.makeValidName(dset_path{end});
        data.(field_name) = h5read(filepath, [group '/' datasets{i}]);
    end
end

end
