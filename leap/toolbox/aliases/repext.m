function varargout = repext(varargin)
	varargout{1:max(nargout,1)} = extrep(varargin{:});
end
