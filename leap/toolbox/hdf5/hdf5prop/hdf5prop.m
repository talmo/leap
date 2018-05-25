classdef hdf5prop < handle
% HDF5PROP Class for transparent file data access.
% Matlab class to create and access HDF5 datasets transparently as Matlab
% variable. Data can be accessed and written with subscript referencing and
% assignment methods, just like a matlab variable, only size must be
% explicitly set or changed.
%
%   prop = hdf5prop(file, dataset)
%     Creates a 'hdf5prop' object for the given dataset in the given HDF5
%     file.
%
%   prop = hdf5prop(file, dataset, mode)
%     Specify the access mode, 
%       mode = 'r' : readonly access (default)
%       mode = 'rw': readwrite access
%
%   prop = hdf5prop(file, dataset, parameter, value, ...)
%     Creates a 'hdf5prop' object for a new dataset with given parameters.
%
%     parameter
%       'size'        - size of the dataset. Necessary.
%       'chunk_size'  - size of the chunks of the dataset.
%       'compression' - 0-9  compression level.
%       'type'        - type of the dataset to create.  This can be a string
%                       such as 'double', in which case the datatype maps to
%                       'H5T_NATIVE_DOUBLE', or it can be a derived HDF5 
%                       datatype.
%       'max_size'    - the maximum size of the dataset to create.
%       'fill'        - the fill value.

% copyleft 2011, Piers Titus van der Torren

  % TODO: replace all H5 calls to direct mex calls for speed
  properties( SetAccess = protected )
    file
    dataset
    mode = 'H5F_ACC_RDONLY'
    propsize
  end
  properties( SetAccess = protected, Transient = true )
    dataset_id
  end
  
  methods
    function self = hdf5prop(file,dataset,varargin)
      
      self.file = file;
      self.dataset = dataset;
      if nargin>2
        switch varargin{1}
          case {'H5F_ACC_RDWR','rw'}
            self.mode = 'H5F_ACC_RDWR';
            varargin = varargin(2:end);
          case {'H5F_ACC_RDONLY','r'}
            varargin = varargin(2:end);
          otherwise            
        end
      end
      if ~exist(file, 'file')
        % create file
        file_id = H5F.create(file, 'H5F_ACC_EXCL', 'H5P_DEFAULT', 'H5P_DEFAULT');
        self.mode = 'H5F_ACC_RDWR';
      else
        file_id = H5F.open(self.file, self.mode, 'H5P_DEFAULT');
      end
      try
        self.dataset_id = H5D.open(file_id,self.dataset);
        if ~isempty(varargin)
          error('hdf5prop:exists', 'dataset already exists, even though creation parameters are given')
        end
      catch ex
        if strcmp(ex.identifier, 'hdf5prop:exists')
          rethrow(ex);
        end
        % create dataset
        
        if strcmp(self.mode, 'H5F_ACC_RDONLY')
          self.mode = 'H5F_ACC_RDWR';
          H5F.close(file_id);
          file_id = H5F.open(self.file, self.mode, 'H5P_DEFAULT');
        end
        
        self.dataset_id = h5datacreate(file_id, self.dataset, varargin{:});
        
      end
      
      space = H5D.get_space(self.dataset_id);
      [ans, dims] = H5S.get_simple_extent_dims(space);
      self.propsize = fliplr(dims);
    end
    
    function open( self )
      if ~isa(self.dataset_id, 'H5ML.id') || self.dataset_id.identifier < 0
        
        file_id=H5F.open(self.file,self.mode,'H5P_DEFAULT');
        self.dataset_id=H5D.open(file_id,self.dataset);

        % get size of dataset
        % TODO: size is not valid when file is changed elsewhere while open
        space = H5D.get_space(self.dataset_id);
        [ndims, dims] = H5S.get_simple_extent_dims(space);
        self.propsize = fliplr(dims);
      end
    end
    
    function close( self )
      % CLOSE Close file if open.
      if isa(self.dataset_id, 'H5ML.id') 
        H5D.close(self.dataset_id);
      end
    end
    
    function set_extent( self, sz)
      % SET_EXTENT Allocate space
      %
      %   hdf5prop.set_extent(sz)
      %     Extend allocated space to size sz.
      self.open();
      H5D.extend(self.dataset_id, fliplr(sz));
      %H5D.set_extent(self.dataset_id, fliplr(sz));
      self.propsize = sz;
    end
    
    function set_mode( self, mode )
      self.close()
      switch mode
        case {'H5F_ACC_RDWR','rw'}
          self.mode = 'H5F_ACC_RDWR';
        case {'H5F_ACC_RDONLY','r'}
          self.mode = 'H5F_ACC_RDONLY';
        otherwise
          error('unknown mode')
      end
      self.open()
    end
    
    function lock( self )
      self.close()
      self.mode = 'H5F_ACC_RDONLY';
      self.open()
    end
  end
  
  methods( Hidden=true )  
    
    function varargout = subsref(self, S)
      switch S(1).type
        case {'.', '{}'}
          [varargout{1:nargout}] = builtin('subsref',self,S);
        case '()'
          [varargout{1:nargout}] = self.get_data(S(1).subs{:});
%         case '{}'
%           error('{} not allowed')
      end
    end
    
    function self = subsasgn(self, S, B)
      switch S(1).type
        case {'.', '{}'}
          builtin('subsasgn',self,S,B);
        case '()'
          self.set_data(S(1).subs, B);
%         case '{}'
%           error('{} not allowed')
      end
    end
    
    function out = get_data(self, varargin)
      
      self.open()
      
      % return all data
      if nargin == 1 || all(strcmp(varargin,':'))
        out = H5D.read(self.dataset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT');
        return;
      end
      
      outsize = [];
      
      propsize = size(self);
      dim = numel(propsize);
      % fill singular dimensions if there's only 1 nonsingular dimension
      if dim > 1 && numel(varargin)==1 && sum(propsize ~= 1) <= 1
        a = varargin;
        varargin = repmat({':'},1,dim);
        if any(propsize ~= 1)
          varargin{propsize ~= 1} = a{1};
        end
        outsize = size(a{1});
        if sum(outsize~=1)==1
          outsize = [];
        end
      end
      assert(dim == numel(varargin),'linear or multidimensional boolean indexing is not yet supported, now use all %d dimensions',dim);
      
      % divide selection into hyperslabs
      start = nan(1,dim);
      count = nan(1,dim);
      stride = nan(1,dim);
      hyperslab = true;
      for n = 1:dim
        sel = varargin{dim+1-n};  % traverse reversed instead of fliplr
        if isa(sel,'char') && sel == ':'
          start(n) = 1;
          count(n) = propsize(dim+1-n);
          stride(n) = 1;
          idxc{n} = sel;
          selc{n} = sel;
        else
          %if isempty(sel)
          %  % if one dimension is empty the result is empty too
          %  out = [];
          %  return
          %end
          
          sel = sel(:);
          if isa(sel,'logical')
            sel = find(sel);
            idxc{n} = ':';
          elseif numel(sel) <= 1 || ( issorted(sel) && min(diff(sel))>0 )
            idxc{n} = ':';
          else
            [sel, ans, idxc{n}] = unique(sel);
          end
          
          selc{n} = sel;
          
          count(n) = numel(sel);

          dsel = diff(sel);
          if isempty(sel)
            start(n) = 1;
            stride(n) = 1;
          elseif numel(sel)==1
            start(n) = sel(1);
            stride(n) = 1;
          elseif all(dsel == dsel(1))
            start(n) = sel(1);
            stride(n) = dsel(1);
          else
            hyperslab = false;
          end
        end
      end

      % TODO: fix datatype 
      if any(count==0)
        out = zeros(fliplr(count));
        return
      end
      
      space=H5D.get_space(self.dataset_id);
      if hyperslab
        %H5ML.hdf5lib2('H5Sselect_hyperslab',space_double,'H5S_SELECT_SET',start,stride,count,[]);
        H5S.select_hyperslab(space,'H5S_SELECT_SET',start-1,stride,count,[]);
      else
        s = find(isnan(start));
        selend = cellfun(@(x) x(end),selc(s));
        sel1 = cellfun(@(x) x(1),selc(s));
        if prod(count(s)) > .1 * prod(selend - sel1)
          % since hyperslab is way faster than select_elements, it is
          % faster to read a full hypeslab and do the selection in
          % matlab. The factor above should match the speed ratio.
          start(s) =  sel1;
          stride(s) = 1;
          count(s) = selend-sel1+1;
          for n=s
            idxc{n} = selc{n}(idxc{n}) - selc{n}(1) + 1;
          end
          H5S.select_hyperslab(space,'H5S_SELECT_SET',start-1,stride,count,[]);
        else
          sel = zeros(dim,prod(count));
          % ndgrid of selc{:}
          for n=1:dim,
            if ischar(selc{n})
              x = (1:count(n))';
            else
              x = selc{n}; % Extract and reshape as a vector.
            end
            s = count; s(n) = []; % Remove i-th dimension
            x = reshape(x(:,ones(1,prod(s))),[length(x) s]); % Expand x
            x = permute(x,[2:dim-n+1 1 dim-n+2:dim]); % Permute to i'th dimension
            sel(n,:) = x(:);
          end
          %warning('using H5S.select_elements, might be slow')
          H5S.select_elements(space,'H5S_SELECT_SET',sel-1);
        end
      end
      
      % reserve space for reading
      mem_space = H5S.create_simple(dim, count, []);

      % read the actual data
      out = H5D.read(self.dataset_id,'H5ML_DEFAULT',mem_space,space,'H5P_DEFAULT');
      
      % shuffle output to match selection
      out=out(idxc{end:-1:1});
      
      if ~isempty(outsize)
        out = reshape(out,outsize);
      end

      H5S.close(space);
      H5S.close(mem_space);
    end
    
    function set_data(self, argin, B)
      
      if ~strcmp(self.mode, 'H5F_ACC_RDWR')
        error('this hdf5prop is read only')
      end
      
      self.open()
      
      propsize = size(self);
      dim = numel(propsize);
      % fill singular dimensions if there's only 1 nonsingular dimension
      if dim > 1 && numel(argin)==1 && sum(propsize ~= 1) <= 1
        a = argin;
        argin = repmat({':'},1,dim);
        if any(propsize ~= 1)
          argin{propsize ~= 1} = a{1};
        end
      end
      assert(dim == numel(argin),'linear or multidimensional boolean indexing is not yet supported, now use all %d dimensions',dim);
      
      colondim = strcmp(argin,':');
      
      % get input indexing dimensions
      indim = 1:dim;
      for n=1:dim
        if colondim(n)
          indim(n) = propsize(n);
        elseif isa(argin{n},'logical')
          indim(n) = sum(argin{n}(:));
        else
          indim(n) = numel(argin{n});
        end
      end
      
      % check if squeezed dimensions match
      indim = max(cellfun(@numel,argin), colondim.*propsize);
      szB = size(B);
      assert(numel(B)==1 || all(indim(indim~=1)==szB(szB~=1)),'Subscripted assignment dimension mismatch.')
      
      if any(indim==0)
        % nothing to be done
        return;
      end
      
      % unsqueeze input
      if numel(B)~=1
        B = reshape(B,indim);
      end
      
      % write all data
      if all(colondim)
        if numel(B) == 1
          B = repmat(B,propsize);
          % H5D.fill ?
        end
        
        H5D.write(self.dataset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',B);
        return;
      end
      
      % divide selection into hyperslabs
      start = zeros(1,dim);
      count = zeros(1,dim);
      stride = zeros(1,dim);
      hyperslab = true;
      for n = 1:dim
        sel = argin{dim+1-n};  % traverse reversed instead of fliplr
        if isa(sel,'char') && sel == ':'
          start(n) = 1;
          count(n) = propsize(dim+1-n);
          stride(n) = 1;
          idxc{n} = sel;
          selc{n} = sel;
        else
          sel = sel(:);
          if isa(sel,'logical')
            sel = find(sel);
            idxc{n} = ':';
          elseif numel(sel) == 1 || ( issorted(sel) && min(diff(sel))>0 )
            idxc{n} = ':';
          else
            % this line is different from get_data
            [sel, idxc{n}] = unique(sel);
          end
          
          selc{n} = sel;
          
          count(n) = numel(sel);
          if hyperslab
            dsel = diff(sel);
            if numel(sel)==1
              start(n) = sel(1);
              stride(n) = 1;
            elseif all(dsel == dsel(1))
              start(n) = sel(1);
              stride(n) = dsel(1);
            else
              hyperslab = false;
            end
          end
        end
      end
      
      space=H5D.get_space(self.dataset_id);
      if hyperslab
        %H5ML.HDF5lib2('H5Sselect_hyperslab',space_double,'H5S_SELECT_SET',start,stride,count,[]);
        H5S.select_hyperslab(space,'H5S_SELECT_SET',start-1,stride,count,[]);
      else
        sel = zeros(dim,prod(count));
        % ndgrid of selc{:}
        for n=1:dim,
          if ischar(selc{n})
            x = (1:count(n))';
          else
            x = selc{n}; % Extract and reshape as a vector.
          end
          s = count; s(n) = []; % Remove i-th dimension
          x = reshape(x(:,ones(1,prod(s))),[length(x) s]); % Expand x
          x = permute(x,[2:dim-n+1 1 dim-n+2:dim]); % Permute to i'th dimension
          sel(n,:) = x(:);
        end
        H5S.select_elements(space,'H5S_SELECT_SET',sel-1);
      end
      
      % reserve space for reading
      mem_space = H5S.create_simple(dim, count, []);

      % prepare input
      if prod(count) > 1
        if numel(B) == 1
          B = repmat(B,count);
        else
          % shuffle input to match selection
          B = B(idxc{end:-1:1});
        end
      end
      
      % write the actual data
      H5D.write(self.dataset_id,'H5ML_DEFAULT',mem_space,space,'H5P_DEFAULT',B);
      
      H5S.close(space);
      H5S.close(mem_space);
    end
    
    function varargout = size(self, dim)
      self.open()
      sz = self.propsize;
      if nargout > 1
        varargout = num2cell(sz);
      elseif nargin > 1
        varargout = {sz(dim)};
      else
        varargout = {sz};
      end
    end
    
    % overloading numel causes problems with builtin subsref
%     function out = numel(self)
%       out = 1;%prod(size(self));
%     end
    
    function out = length(self)
      out = max(size(self));
    end
    
    function out = end(self, dim, n_dim)
      out = size(self,dim);
    end
    
    function out = vertcat(varargin)
      error('array of hdf5prop objects is not allowed')
    end
    
    function out = horzcat(varargin)
      error('array of hdf5prop objects is not allowed')
    end
    
    function out = cat(varargin)
      error('array of hdf5prop objects is not allowed')
    end
    
    function out = double( self )
      out = double(self.get_data());
    end
    
    function out = eq( self, other )
      out = eq(self.get_data(), other());
    end
    
    function out = ne( self, other )
      out = ne(self.get_data(), other());
    end
    
    function out = le( self, other )
      out = le(self.get_data(), other());
    end
    
    function out = ge( self, other )
      out = qe(self.get_data(), other());
    end
    
    function out = lt( self, other )
      out = lt(self.get_data(), other());
    end
    
    function out = gt( self, other )
      out = gt(self.get_data(), other());
    end
  end
end
