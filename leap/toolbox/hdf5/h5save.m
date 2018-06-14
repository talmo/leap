function h5save(filepath, X, dset, varargin)
%H5SAVE Create and save a variable to an HDF5 file.
% Usage:
%   h5save(filepath, X)
%   h5save(filepath, X, dset)
% 
% Args:
%   filepath: path to HDF5 file
%   X: variable to save
%   dset: name or path to dataset (optional if variable name can be determined by inputname)
%
% Params:
%   'compress': use GZIP compression filter for dataset (default: false)
%   'chunking': shape to use for dataset chunking or dimension to use as singleton (default: [])
%               if compress is true and this is not specified, chunking
%               will default to the last dimension of the dataset
% 
% See also: h5write, h5att2struct, h5struct2att, inputname

if nargin < 3 || isempty(dset)
    dset = inputname(2);
    if isempty(dset)
        error('Dataset name must be specified if not saving a named variable.')
    end
end

% Make sure dataset starts with '/'
if dset(1) ~= '/'; dset = ['/' dset]; end

% Parse ptional arguments:
defaults = struct('compress',false,'chunking',[]);
[params, unmatched] = parse_params(varargin, defaults);
if isfield(unmatched, 'ChunkSize'); params.chunking = unmatched.ChunkSize; end
if isfield(unmatched, 'Deflate'); params.compress = unmatched.Deflate; end

if params.compress > 0; params.compress = double(params.compress); end

% If compression is enabled, use last dimension as chunking dim
if isempty(params.chunking) && params.compress > 0
    params.chunking = ndims(X);
end

% If chunking is specified as dimension instead of full size, expand to chunk size
if isscalar(params.chunking)
    d = params.chunking;
    params.chunking = size(X);
    params.chunking(d) = 1;
end

% Infer data type from input
dtype = class(X);
if islogical(X)
    X = uint8(X);
end

% Exceptions identifiers:
% MATLAB:imagesci:h5write:datasetDoesNotExist
% MATLAB:imagesci:h5create:datasetAlreadyExists
try
    args = {};
    if ~isempty(params.chunking); args = [args, {'ChunkSize', params.chunking}]; end
    if params.compress; args = [args, {'Deflate', params.compress}]; end
    h5create(filepath, dset, size(X), 'Datatype', class(X), args{:})
    h5writeatt(filepath, dset, 'dtype', dtype)
catch ME
    switch ME.identifier
        case 'MATLAB:imagesci:h5create:datasetAlreadyExists'
            warning('h5save:overwrite','Overwriting existing dataset: %s', dset)
        otherwise
            rethrow(ME)
    end
end

h5write(filepath, dset, X)

end
