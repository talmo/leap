function S = h5att2struct(filename, location)
%H5ATT2STRUCT Reads a set of HDF5 attributes into a named structure.
% Usage:
%   S = h5att2struct(filename, location)
%
% Returns:
%   S: structure with fields corresponding to the attribute names, or empty
%      if no attributes are found

if nargin < 2; location = '/'; end
if location(1) ~= '/'; location = ['/' location]; end

info = h5info(filename, location);

S = struct();
if isempty(info.Attributes)
    return
end

% Pull out data
fieldnames = {info.Attributes.Name};
values = {info.Attributes.Value};

% Wrap cell arrays with {} to ensure they are scalar fields
is_cell_arr = ~cellfun(@isscalar,values);
values(is_cell_arr) = cf(@(x){x},values(is_cell_arr));

% Create structure
S = horz([horz(fieldnames); horz(values)]);
S = struct(S{:});

end

