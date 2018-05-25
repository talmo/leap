function varargout = h5file(varargin)
	varargout{1:nargout} = hdf5prop(varargin{:});
end
