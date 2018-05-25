function [sz, maxSize] = h5size(filepath, dataset, dim)
%H5SIZE Returns the size of the specified dataset.
% Usage:
%   [size, maxSize] = h5size(filepath, dataset)
%   [size, maxSize] = h5size(filepath, dataset, dim)

if nargin < 3; dim = []; end

if nargout > 1
    info = h5info(filepath, dataset);

    sz = info.Dataspace.Size;
    maxSize = info.Dataspace.MaxSize;

    if ~isempty(dim)
        sz = sz(dim);
        maxSize = maxSize(dim);
    end
else
    sz = size(h5file(filepath, dataset));
    if ~isempty(dim)
        sz = sz(dim);
    end
end
end

