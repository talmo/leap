function varargout = ff(varargin)
    N = max(nargout,1);
	varargout{1:N} = fullfile(varargin{:});
end
