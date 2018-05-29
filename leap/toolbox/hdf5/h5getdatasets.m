function datasets = h5getdatasets(filepath, grp, recurse)
%H5GETDATASETS Returns a list of all datasets in an HDF5 file.
% Usage:
%   datasets = h5getdatasets(filepath)
%   datasets = h5getdatasets(filepath, grp)
% 
% Args:
%   filepath: file path to HDF5 file
%   grp: path to group within HDF5 file (default: '/')
%   recurse: traverse subgroups to find datasets (default: true)
%
% Returns:
%   datasets: cell array of paths to each dataset within the file
%
% See also: h5file, h5info

if nargin < 2 || isempty(grp); grp = '/'; end
if nargin < 3 || isempty(recurse); recurse = true; end

info = h5info(filepath, grp);
datasets = getdsets(info, recurse);

end

function ds = getdsets(G, recurse)
% Recurse through info structure and pull out datasets

ds = {};
if ~isempty(G.Datasets)
    base = G.Name;
    if base(end) == '/'; base = base(1:end-1); end
    ds = strcat(base, '/', {G.Datasets.Name})';
end

if recurse
    for i = 1:numel(G.Groups)
        ds = [ds; getdsets(G.Groups(i),recurse)];
    end
end
end

