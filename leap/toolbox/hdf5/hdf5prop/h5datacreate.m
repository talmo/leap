function datasetId = h5datacreate(h5file,varname,varargin)
%H5datacreate  Create HDF5 dataset.
%
%   H5DATACREATE(HFILE,VARNAME,parameter,value,...) creates a dataset
%   named VARNAME.  HFILE may be either a path to the HDF5 file or a file 
%   ID to an already opened file.  
%
%   If VARNAME is a full pathname, all 
%   intermediate groups are created if they don't already exist.
%
%   parameter
%     'size'        - size of the dataset
%     'chunk_size'  - size of the chunks of the dataset
%     'compression' - 0-9  compression level
%     'type'        - type of the dataset to create.  This can be a string
%                     such as 'double', in which case the datatype maps to
%                     'H5T_NATIVE_DOUBLE', or it can be a derived HDF5 
%                     datatype.
%     'max_size'    - the maximum size of the dataset to create
%     'fill'        - the fill value
%
%
%   Example:  create a 10x20 single precision dataset named 'DS1'.
%       h5filecreate('myfile.h5');
%       h5datacreate('myfile.h5','DS1','type','single','size',[10 20]);
%
%   Example:  create a 4x1 string dataset where each string has length
%   8 and is null-terminated.
%       mytype = H5T.copy('H5T_C_S1');
%       H5T.set_size(mytype,8);
%       H5T.set_strpad(mytype,'H5T_STR_NULLTERM');
%       h5datacreate('myfile.h5','/path/to/DS2','type',mytype,'size',4);
%
%   Credit where credit is due:  Philip Top at LLNL
%
%   See also h5filecreate.

%   Copyright 2010 The MathWorks, Inc.

p = inputParser;
p.addParamValue('size',0,@isnumeric);
p.addParamValue('chunk_size',0,@isnumeric);
p.addParamValue('compression',0,@isnumeric);
p.addParamValue('type',H5T.copy('H5T_NATIVE_DOUBLE'),@(x)ischar(x) || isa(x,'H5ML.id'));
p.addParamValue('max_size',0,@isnumeric);
p.addParamValue('fill',0,@isnumeric);
p.parse(varargin{:});
params = p.Results;
params = validate_params(h5file,varname,params);


flags = 'H5F_ACC_RDWR';
fapl  = 'H5P_DEFAULT'; 

if ischar(h5file)
    file_id = H5F.open(h5file,flags,fapl);
else
    file_id=h5file;
end



params = set_dataspace_id (params);
params = set_datatype_id (params);
params = set_dcpl(params);

datasetId = set_data_id(file_id,varname,params);

H5S.close(params.dataspaceId);
H5T.close(params.datatypeId);
H5P.close(params.dcpl);


if ischar(h5file)
    H5F.close(file_id);
end





%==========================================================================
function params = set_dcpl(params)
% Setup the dataset creation property list.  

params.dcpl = H5P.create('H5P_DATASET_CREATE'); % create property list
if (~isequal(params.chunk_size,0))
    % set chunk size
    H5P.set_chunk(params.dcpl,fliplr(params.chunk_size)); 
end
if (params.compression~=0)
    % set gzip compression level
    H5P.set_deflate(params.dcpl,params.compression);
end
if (params.fill~=0)
    % set fill value
    H5P.set_fill_value(params.dcpl, params.datatypeId, params.fill.*ones(params.type));
end
return







 
%==========================================================================
% SET_DATASET_ID
%
% Setup the dataet ID.  We need to check as to whether or not the dataset
% already exists.
function datasetID = set_data_id(fid,dataname,params)

v = version('-release');
switch(v)
	case { '2007b', '2008a', '2008b' }
		% Give it our best shot.
		datasetID = H5D.create(fid,dataname,...
                       params.datatypeId, params.dataspaceId, ...
                       params.dcpl);

	otherwise
	
		% create any intermediate groups along the way.
		params.lcpl = H5P.create('H5P_LINK_CREATE');
		H5P.set_create_intermediate_group(params.lcpl,1);
		dapl = 'H5P_DEFAULT';


		% need to use the 1.8.x version of H5D.create for this.
		datasetID = H5D.create(fid,dataname,...
                       params.datatypeId, params.dataspaceId, ...
                       params.lcpl,params.dcpl,dapl);

end

return

%===============================================================================
% SET_DATASPACE_ID
%
% Setup the dataspace ID.

function params = set_dataspace_id (params)

params.dataspaceId=H5S.create('H5S_SIMPLE');
H5S.set_extent_simple(params.dataspaceId,length(params.size),...
    fliplr(params.size),fliplr(params.max_size));
return



%===============================================================================
% SET_DATATYPE_ID
%
% We need to choose an appropriate HDF5 datatype
function params = set_datatype_id (params)
if ischar(params.type)
    switch params.type
        case 'double'
            params.datatypeId = H5T.copy('H5T_NATIVE_DOUBLE');
        case {'single','float'}
            params.datatypeId = H5T.copy('H5T_NATIVE_FLOAT');
        case 'int64'
            params.datatypeId = H5T.copy('H5T_NATIVE_LLONG');
        case 'uint64'
            params.datatypeId = H5T.copy('H5T_NATIVE_ULLONG');
        case {'int32','int'}
            params.datatypeId = H5T.copy('H5T_NATIVE_INT');
        case {'uint32','uint'}
            params.datatypeId = H5T.copy('H5T_NATIVE_UINT');
        case {'int16','short'}
            params.datatypeId = H5T.copy('H5T_NATIVE_SHORT');
        case 'uint16'
            params.datatypeId = H5T.copy('H5T_NATIVE_USHORT');
        case 'int8'
            params.datatypeId = H5T.copy('H5T_NATIVE_SCHAR');
        case 'uint8'
            params.datatypeId = H5T.copy('H5T_NATIVE_UCHAR');
        case 'complex'
            % special case for complex data.  We'll actually create 3 
            % datasets.  One to hold the real data, one to hold the 
            % complex data, and one to hold references to both.
            params.datatypeId = H5T.copy('H5T_STD_REF_OBJ');
        otherwise
            error('hdf5tools:H5DATACREATE:unsupportedDatatype', ...
                '''%s'' is not a supported H5DATACREATE datatype.\n', params.type );
    end
    return
end

if isa(params.type,'H5ML.id')
    params.datatypeId = H5T.copy(params.type);
    return
end



%--------------------------------------------------------------------------
function params = validate_params(hfile,varname,params)

if (params.size == 0 )
    error('hdf5tools:h5datacreate:zeroSize', ...
        'Size must be specified and be greater than zero.');
end


if ~ischar(hfile)
    if ~isequal(class(hfile),'H5ML.id')
        error('hdf5tools:H%DATACREATE:badDatatype', ...
            'Filename input argument must have datatype char.' );
        
    end
end

if ~ischar(varname)
    error('hdf5tools:H5DATACREATE:badDatatype', ...
        'VARNAME input argument must have datatype char.' );
end



if (~isequal(params.chunk_size,0))
    if (numel(params.chunk_size)~=numel(params.size))
        error('dataset size and chunk size have different dimensions');
    end
end

if (~isequal(params.max_size,0))
    if (isequal(params.chunk_size,0))
        error('chunk size must be specified if max size is different from size')
    end
    if (numel(params.max_size)~=numel(params.size))
        error('dataset max size and initial size have different dimensions');
    elseif (any(isinf(params.max_size)))
        mxs=cell(size(params.max_size));
        for kk=1:length(params.max_size)
            if (isinf(params.max_size(kk)))
                mxs{kk}='H5S_UNLIMITED';
            else
                mxs{kk}=params.max_size(kk);
            end
        end
        params.max_size = mxs;
    end
        
else
    params.max_size=params.size;
end

if ((params.compression<0)||(params.compression>9))
    error('invalid compression level');
    
else
    if (params.compression>0)
        if (isequal(params.chunk_size,0))
            params.chunk_size=params.size;
        end
    end
end
return







