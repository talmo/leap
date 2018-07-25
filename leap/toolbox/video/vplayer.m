classdef vplayer < matlab.mixin.SetGet
    %VPLAYER Image video/stack player class.
    % Usage:
    %   vplayer(S)
    %
    %   See also: imstacksc
    
    properties (SetAccess = immutable)
        numFrames, numChannels, frameSize
    end
    properties
        S % stack
        matField % variable name of stack in MatFile
        getFrameFcn % function that returns frame
        ndims = 4
        
        fig, ax, img % graphics objects
        ui = struct() % uix components
        closeWithPlayer = {} % other graphics object to delete when closing
        clims, cmap % color scaling
        title = ''
        scale = true % scale to colormap
        
        frame % current frame
        idx % current frame index within S
        channel % current channel
        
        doCache = false % whether caching is enabled
        cached % logical indicator
        cache % cell array for storage
        
        isPlaying = false
        fps = 25
        stride = 1
        pb_timer
        
        doSave = false % set to true to save frames on draw
        saved = {}
        
        params = struct()
        callbacks = {}
        hotkeys = [] %table([],[],[],'VariableNames',{'Key','Modifiers','Callback'})
        bookmarks = [] % indices
        seekbar
    end
    
    events
        NewFrame
    end
    
    methods
        function h = vplayer(S, varargin)
            % Input formats
            if iscell(S); S = cellcat(S,4); end
            if ischar(S)
                if endsWith(S,'.mat')
                    S = matfile(S);
                elseif endsWith(S,'fg.h5')
                    S = h5file(S,'/fg');
                elseif endsWith(S,'processed.h5')
                    S = h5file(S,'/video/data');
                elseif endsWith(S,'.h5') && nargin > 1 && varargin{1}(1) == '/'
                    S = h5file(S,varargin{1});
                    varargin(1) = [];
                elseif endsWith(S,'.h5')
                    dsets = h5getdatasets(S);
                    if any(strcmp(dsets,'/box'))
                        S = h5file(S,'/box');
                    end
                end
            end
%             if ischar(S) && strcmpi(get_ext(S),'.mat'); S = matfile(S); end
%             if ischar(S) && strcmpi(get_ext(S),'.h5')
%                 if strcmpi(get_filename(S),'processed.h5') || endsWith(get_filename(S),'.lz4.h5')
%                     S = h5file(S,'/video/data');
%                 elseif strcmpi(get_filename(S),'fg.h5')
%                     S = h5file(S,'/fg');
%                 end
%             end
            h.S = S;
            def_stackName = inputname(1);
            default_clims = [];
            switch class(h.S)
                case 'matlab.io.MatFile' % assumes 4-D numeric stack
                    % Check inputs
                    if nargin < 2 || ~ischar(varargin{1})
                        error(['Variable name must be specified if playing from MatFile.\\n' ...
                            '   Example: vplayer(matfile(path),''mov'')']);
                    end
                    h.matField = varargin{1};
                    varargin(1) = [];
                    
                    % Check variable name
                    vars = who(h.S);
                    if ~ismember(h.matField,vars); error('Variable ''%s'' is not in MatFile.', h.matField); end
                    
                    % Check size
                    sz = size(h.S,h.matField);
                    if numel(sz) ~= 4; error('Stack variable ''%s'' must be numeric 4-D array.', h.matField); end
                    
                    % Setup
                    h.numFrames = sz(4);
                    h.getFrameFcn = @getFrame_MatFile;
                    h.doCache = true;
                    def_stackName = h.matField;
                case {'hdf5prop','hdf5file'}
                    % Ref: http://www.mathworks.com/matlabcentral/fileexchange/31703-hdf5-diskmap-class
                    sz = size(h.S);
                    h.ndims = numel(sz);
                    h.numFrames = sz(end);
                    h.getFrameFcn = @getFrame_stack;
                    h.doCache = false; % hdf5prop does caching already
                    def_stackName = h.S.dataset;
                case 'struct'
                    fields = fieldnames(h.S);
                    if ~any(ismember({'sz','size'},fields)) || ...
                        ~any(ismember({'ind','idx'},fields))
                        error('Structure array must have ''idx'' and ''size'' fields (see ind2im).')
                    end
                    h.numFrames = numel(h.S);
                    h.getFrameFcn = @getFrame_struct;
                    h.doCache = true;
                otherwise
                    if ~isnumeric(h.S) && ~islogical(h.S); error('Invalid stack format specified.'); end
                    if ndims(h.S) == 3; h.S = permute(h.S, [1 2 4 3]); end
                    if ndims(h.S) < 4; error('Numeric stack must be 4-D array.'); end
                    default_clims = alims(h.S);
                    h.numFrames = size(h.S,4);
                    h.getFrameFcn = @getFrame_stack;
            end
            
            % Initialize caching
            h.cached = false(1,h.numFrames);
            h.cache = cell(1,h.numFrames);
            
            % Initialize saving container
            h.saved = cell(1,h.numFrames);
            
            % Shortcut args
            default_cmap = [];
            if numel(varargin) > 0
                p = varargin{1};
                if ischar(p) && any(strcmpi(p,{'parula','gray','jet','hot'}))
                    default_cmap = p;
                    varargin(1) = [];
                end
            end
            if numel(varargin) > 0
                p = varargin{1};
                
                % Parse frame draw callbacks from args
                if iscell(p) && ~isempty(p) && all(cellfun(@(x)isa(x, 'function_handle'),p)) % callbacks
                    h.callbacks = p;
                    varargin(1) = [];
                elseif isa(p, 'function_handle') % single callback
                    h.callbacks = {p};
                    varargin(1) = [];
                end
            end
            
            % Parameters
            defaults = struct();
            defaults.colormap = default_cmap;
            defaults.clims = default_clims;
            defaults.scale = []; % heuristic default below
            defaults.stackName = def_stackName;
            defaults.position = [];
            defaults.initialFrame = 1;
            defaults.initialChannel = 1;
            defaults.autoplay = false;
            defaults.fps = 25;
            defaults.stride = 1;
            defaults.save = false;
            defaults.saveTarget = 'ax'; % 'fig' or 'ax'
            defaults.clear = true; % clear graphics objects on axes between frames
            defaults.colorbar = false;
            defaults.tight = true;
            defaults.autotile = false; % tiles channels
            defaults.bookmarks = [];
            defaults.seekbar = false;
            defaults.zoom = 1;
            h.params = parse_params(varargin, defaults);
            
            
            if isempty(h.params.colormap)
                if isa(h.S,'uint8') || isa(h.S,'hdf5prop') || isa(h.S,'hdf5file')
                    h.params.colormap = 'gray';
                else
                    h.params.colormap = 'parula';
                end
            end
            
            % Update properties with params
            h.cmap = h.params.colormap;
            h.doSave = h.params.save;
            h.fps = h.params.fps;
            h.stride = h.params.stride;
            h.bookmarks = h.params.bookmarks;
            h.seekbar = h.params.seekbar;
            
            % Load first frame
            h.frame = h.getFrame(h.params.initialFrame);
            
            % Image metadata
            h.numChannels = size(h.frame,3);
            h.frameSize = size(h.frame(:,:,1));
            h.idx = h.params.initialFrame;
            h.channel = h.params.initialChannel;
            
            % Set color limits
            h.clims = h.params.clims;
            if isempty(h.clims)
                if isa(h.frame,'uint8')
                    h.clims = [0 255];
                elseif isfloat(h.frame) && (isa(h.S,'hdf5prop') || isa(h.S,'hdf5file'))
                    h.clims = [0 1];
                else
                    h.clims = alims(h.frame);
                end
            end
            if ~isnumeric(h.clims); h.clims = double(h.clims); end
            
            % Color scaling
            if isempty(h.params.scale)
                h.scale = h.numChannels ~= 3; % size(S,3) == 3
                h.channel = 1:h.numChannels;
            else
                % User provided parameter
                h.scale = h.params.scale;
            end
            
            % Add hotkeys
            h.addHotkey('leftarrow', @()h.seek(-1))
            h.addHotkey('rightarrow', @()h.seek(+1))
            h.addHotkey('leftarrow', @()h.seek(-5),'shift')
            h.addHotkey('rightarrow', @()h.seek(+5),'shift')
            h.addHotkey('leftarrow', @()h.seek(-50),'control')
            h.addHotkey('rightarrow', @()h.seek(+50),'control')
            h.addHotkey('leftarrow', @()h.seek(-500),{'control','shift'})
            h.addHotkey('rightarrow', @()h.seek(+500),{'control','shift'})
            h.addHotkey('leftarrow', @()h.prevBookmark,'alt')
            h.addHotkey('rightarrow', @()h.nextBookmark,'alt')
%             h.addHotkey('space', @()play(h,true))
            h.addHotkey('space', @()h.play())
            h.addHotkey('uparrow',   @()set(h,'fps',h.fps + 5))
            h.addHotkey('downarrow', @()set(h,'fps',h.fps - 5))
            
            h.addHotkey('add', @()set(h,'stride',h.stride + 1))
            h.addHotkey('subtract', @()set(h,'stride',h.stride - 1))
            h.addHotkey('uparrow', @()set(h,'stride',h.stride + 1),'shift')
            h.addHotkey('downarrow', @()set(h,'stride',h.stride - 1),'shift')
            
            h.addHotkey('add', @()h.zoom(2),'control')
            h.addHotkey('subtract', @()h.zoom(0.5),'control')
            h.addHotkey('uparrow', @()h.zoom(2),'control')
            h.addHotkey('downarrow', @()h.zoom(0.5),'control')
            
            h.addHotkey('pageup', @()set(h,'channel',mod(h.channel-1 +1,h.numChannels)+1))
            h.addHotkey('pagedown', @()set(h,'channel',mod(h.channel-1 -1,h.numChannels)+1))
            h.addHotkey('uparrow', @()set(h,'channel',mod(h.channel-1 +1,h.numChannels)+1),'alt')
            h.addHotkey('downarrow', @()set(h,'channel',mod(h.channel-1 -1,h.numChannels)+1),'alt')
            
            h.addHotkey('home', @()plot(h,1))
            h.addHotkey('end', @()plot(h,h.numFrames))
            h.addHotkey('a', @()autoAdjust(h,true)) % frame
            h.addHotkey('a', @()autoAdjust(h,false),'shift') % default
            h.addHotkey('a', @()stretchLims(h),'control') % stretchlim
            h.addHotkey('q', @()delete(h.fig))
            
            % Initialize graphics
            h.show();
            
            % Redraw initial frame to trigger callbacks and etc.
            h.plot(h.idx);
            
            % Initial zoom
            h.zoom(h.params.zoom);
            h.plot(h.idx);
            
            h.pb_timer = timer(...
                'BusyMode','drop',...
                'ExecutionMode','fixedRate',...
                'Name','vp_playback',...
                'Period',1/h.fps,...
                'TimerFcn',@(tmr,evt)pb_callback(h,tmr,evt) ...
                );
            
        end
        
        function show(h)
            if ishghandle(h.fig); delete(h.fig); end
            
            % Show figure
            h.fig = figure('KeyPressFcn', @(~,evt)KeyPressCB(h,evt), ...
                'CloseRequestFcn', @(~,~)OnClose(h), ...
                'DeleteFcn', @(~,~)OnClose(h), ...
                'NumberTitle', 'off', 'Name', h.params.stackName);
            borderStyle = 'loose'; if h.params.tight; borderStyle = 'tight'; end
            
            h.ui.grid = uix.GridFlex('Parent', h.fig, 'Spacing', 1);
            
            h.ax = axes('Parent',uicontainer('Parent',h.ui.grid,'BackgroundColor',[0 0 0]));
            h.ui.img_ax = h.ax;
            h.img = imshow(h.frame, 'Border',borderStyle, 'Parent',h.ax);
            h.ui.img_h = h.img;
            
            if h.seekbar
                h.ui.seekbar_ax = axes('Parent',uicontainer('Parent',h.ui.grid));
                h.ui.seekbar_img = imagesc(zeros(1,h.numFrames,'uint8'),'Parent',h.ui.seekbar_ax);
            
                noticks(h.ui.seekbar_ax);
            end
            function constrained_pos = seekbar_constraint(new_pos)
                constrained_pos = new_pos;
                constrained_pos(:,1) = min(max(constrained_pos(:,1),0.5),h.numFrames+0.5);
                constrained_pos(:,2) = [0.5 1.5];
                constrained_pos(:,1) = round(mean(constrained_pos(:,1)));
            end
            function seekbar_update(new_pos)
                h.plot(max(1,min(round(new_pos(1)),h.numFrames)));
            end
            if h.seekbar
                h.ui.seekbar_line = imline(h.ui.seekbar_ax, [1 1], [0.5 1.5], ...
                    'PositionConstraintFcn',@seekbar_constraint);
                h.ui.seekbar_line.setColor('r');
                h.ui.seekbar_line.addNewPositionCallback(@seekbar_update);
                h.callbacks{end+1} = @(h,idx)h.ui.seekbar_line.setConstrainedPosition([idx 0.5; idx 1.5]);
            end
%             screen_size = get(0,'ScreenSize');
%             set(h.ui.grid, 'Widths', [-1], 'Heights', [min(screen_size(end),h.frameSize(1)) 20]);
            if h.seekbar
                set(h.ui.grid, 'Widths', [-1], 'Heights', [-1 20]);
            else
                set(h.ui.grid, 'Widths', [-1], 'Heights', [-1]);
            end
            
            if h.scale
                caxis(h.ax,h.clims);
                colormap(h.ax, h.cmap);
            end
            if ~isempty(h.params.position); h.fig.Position = h.params.position; end
            if h.params.colorbar; h.ui.img_colorbar = colorbar(h.ax); end
            
            if h.seekbar
                caxis(h.ui.seekbar_ax,[0 1]);
                colormap(h.ui.seekbar_ax, 'parula');
                h.ui.seekbar_ax.Units = 'normalized';
                h.ui.seekbar_ax.Position = [0 0 1 1];
            end
            h.ax.Units = 'normalized';
            h.ax.Position = [0 0 1 1];
            
            if h.seekbar
                seekbar_pos = getpixelposition(h.ui.seekbar_ax.Parent);
                h.fig.Position(4) = h.fig.Position(4) + seekbar_pos(4);
            end
            
        end
        
        function hide(h)
            if ishghandle(h.fig); delete(h.fig); end
        end
        function set.scale(h,val)
            if isempty(val); return; end
            h.scale = val;
            if ~isempty(h.img) && ishghandle(h.img)
                if h.scale
                    set(h.img,'CDataMapping','scaled');
                else
                    h.channel = 1:h.numChannels;
                    set(h.img,'CDataMapping','direct');
                end
            end
        end
        function set.clims(h,val)
            if isempty(val); return; end
            if ~isnumeric(val); val = double(val); end
            h.clims = val;
            if ~isempty(h.ax) && ishghandle(h.ax) && numel(h.clims) == 2
                caxis(h.ax,h.clims);
            end
        end
        function autoAdjust(h,frameOnly)
            if nargin < 2; frameOnly = true; end
            if frameOnly
                h.clims = alims(h.frame);
            else
                h.clims = h.params.clims;
            end
        end
        function stretchLims(h)
%             disp(alims(h.frame))
%             disp(horz(stretchlim(h.frame)))
            lims = horz(stretchlim(h.frame));
            if isa(h.frame,'uint8'); lims = lims .* 255; end
            h.clims = lims;
        end
        
        
        function zoom(h,factor,relativeToFull)
            if nargin < 2; factor = 1; end
            if nargin < 3; relativeToFull = false; end
            
            pos = h.fig.Position;
            if relativeToFull
                new_sz = round(h.frameSize([2 1]) .* factor);
            else
                new_sz = round(pos(3:4) .* factor);
            end
            delta = pos(3:4) - new_sz;
            
%             h.fig.Position = h.fig.Position - [-delta delta];
%             h.fig.Position = h.fig.Position - [0 -delta(2) delta];
            h.fig.Position = h.fig.Position - [-delta(1)/2 -delta(2) delta];
%             h.fig.Position = h.fig.Position - [0 0 delta];
            h.fig.Position(1:2) = max(1, h.fig.Position(1:2));
        end
        
        
        function frame = getFrame(h, idx)
            if h.doCache && h.cached(idx) && ~isempty(h.cache{idx})
               frame = h.cache{idx};
               return
            end
            
            % Get frame
            frame = h.getFrameFcn(h,idx);
            
            % Save to cache
            if h.doCache
                h.cached(idx) = true;
                h.cache{idx} = frame;
            end
        end
        function frame = getFrame_stack(h, idx)
            if h.ndims == 3
                frame = h.S(:,:,idx);
            else
                frame = h.S(:,:,:,idx);
            end
        end
        function frame = getFrame_MatFile(h, idx)
            if h.ndims == 3
                frame = h.S.(h.matField)(:,:,idx);
            else
                frame = h.S.(h.matField)(:,:,:,idx);
            end
        end
        function frame = getFrame_struct(h, idx)
            frame = ind2im(h.S(idx));
        end
        
        function clearCache(h)
            h.cache = cell(1,h.numFrames);
            h.cached = false(1,h.numFrames);
        end
        
        function redraw(h)
            h.plot(h.idx);
        end
        function plot(h, idx)
            % Update frame index
            h.idx = mod(idx-1,h.numFrames)+1;
            
            % Get frame image
            h.frame = h.getFrame(h.idx);
            if h.params.autotile, h.frame = imtile(h.frame);
            else; h.frame = h.frame(:,:,h.channel); end
            
            % Update image
            h.img.CData = h.frame;
            
            % Clear old graphics
            if h.params.clear
%                 isImage = arrayfun(@(x) isa(x,'matlab.graphics.primitive.Image'), h.ax.Children);
                delete(h.ax.Children(h.ax.Children ~= h.img))
            end
            
            % Update title
            h.updateTitle();
            
            % Invoke frame drawing callbacks
            h.fig.CurrentAxes = h.ax;
            hold(h.ax,'on');
            for j = 1:numel(h.callbacks)
                cb = h.callbacks{j};
                % Pass inputs
                if nargin(cb) == 1
                    args = {h.frame};
                elseif nargin(cb) == 2
                    args = {h, h.idx};
                else
                    args = {h, h.idx, h.frame};
                end
                
                % Collect outputs
                if nargout(cb) < 1 % simple callback
                    cb(args{:});
                else % update frame if there's anything returned
                    h.frame = cb(args{:});
                    h.img.CData = h.frame;
                end
            end

            % Redraw graphics
            drawnow;
            
            % Save frame
            if h.doSave
                if ischar(h.params.saveTarget)
                    switch h.params.saveTarget
                        case 'fig'
                            h.params.saveTarget = h.fig;
                        case 'ax'
                            h.params.saveTarget = h.ax;
                    end
                end
                h.saved{idx} = frame2im(getframe(h.params.saveTarget));
            end
            
            % Fire event
            h.notify('NewFrame');
        end
        
        % Playback
%         function play(h,toggle)
%             if nargin < 2; toggle = true; end
%             
%             if toggle
%                 h.isPlaying = ~h.isPlaying;
%             else
%                 h.isPlaying = true;
%             end
%             
%             while ishghandle(h.fig) && h.isPlaying
%                 % Draw next frame
%                 h.plot(h.idx + h.stride)
% 
%                 % Wait
% %                 pause(h.stride / h.fps)
%                 pause(1 / h.fps)
%             end
%         end
        
        function play(h,~)
            if h.isPlaying
                h.isPlaying = false;
%                 h.pb_timer.stop();
            else
                h.isPlaying = true;
                start(h.pb_timer);
            end
        end
        function pb_callback(h,tmr,evt)
            if h.isPlaying
                h.seek(h.stride);
            else
                stop(tmr);
            end
        end
            
        function stop(h)
            h.isPlaying = false;
        end
        function playTo(h,stop_idx)
            % Plays until specified frame and then stops
            if nargin < 2; stop_idx = h.numFrames; end
            if h.isPlaying; h.play(); end % stop if already playing
            for i = h.idx:h.stride:stop_idx
                h.plot(i);
            end
        end
        function goTo(h,idx)
            % Wrapper for h.plot
            h.plot(idx);
        end
        function seek(h,delta)
            new_idx = h.idx + delta;
            new_idx = mod(new_idx-1,h.numFrames)+1;
            h.plot(new_idx);
        end
        function nextBookmark(h)
            isAfter = h.bookmarks > h.idx;
            if any(isAfter)
                next_idx = h.bookmarks(find(isAfter,1));
                h.plot(next_idx);
            end
        end
        function prevBookmark(h)
            isBefore = h.bookmarks < h.idx;
            if any(isBefore)
                prev_idx = h.bookmarks(find(isBefore,1,'last'));
                h.plot(prev_idx);
            end
        end
        
        function set.fps(h,val)
            h.fps = max(val,0);
            if ishghandle(h.fig)
                if h.fps == 0; h.stop(); else; h.play(false); end
            end
        end
        function set.stride(h,val)
            h.stride = max(val,1);
            if ishghandle(h.fig); h.play(false); end
        end
        function set.channel(h,val)
            h.channel = mod(val-1,h.numChannels) + 1;
            if ishghandle(h.fig); h.redraw(); end
        end
        
        
        function updateTitle(h)
            newTitle = sprintf('%d/%d', h.idx, h.numFrames);
            
            if h.numChannels > 1 && ~h.params.autotile && h.scale
                newTitle = sprintf('%s (C: %d/%d)', newTitle, h.channel, h.numChannels);
            end
            
            if h.doSave
                newTitle = sprintf('%s | Saved: %d', newTitle, sum(~cellfun(@isempty,h.saved)));
            end
            
            if h.isPlaying
                newTitle = sprintf('%s | FPS: %d | Stride: %d', ...
                    newTitle, h.fps, h.stride);
            end
            
            h.title = newTitle;
            if ~isempty(h.params.stackName)
                h.fig.Name = [h.params.stackName ': ' newTitle];
            else
                h.fig.Name = newTitle;
            end
        end
        
        function KeyPressCB(h, evt)
            isKey = strcmpi(h.hotkeys.Key, evt.Key);
            if isempty(evt.Modifier)
                isMod = areempty(h.hotkeys.Modifiers);
            else
                isMod = cellfun(@(x) isequal(sort(evt.Modifier),sort(x)), h.hotkeys.Modifiers);
            end
            
            if any(isKey & isMod)
                f = h.hotkeys.Callback{isKey & isMod};
                
                if nargin(f) == 0; f();
                else; f(h,h.idx); end
            else
                if ~contains(evt.Key,evt.Modifier) && ~contains(evt.Key,'windows')
                    printf('No hotkey bound for: %s', evt.Key)
                end
%                 printf('No hotkey bound for: %s + %s', evt.Modifier, evt.Key)
            end
        end
        function addHotkey(h, key, fun, modifiers)
            if nargin < 4; modifiers = {}; end
            if ~iscell(modifiers); modifiers = {modifiers}; end
            
            hotkey = cell2table({key,{modifiers},fun},'VariableNames',{'Key','Modifiers','Callback'});
            if isempty(h.hotkeys)
                h.hotkeys = hotkey;
            else
                h.hotkeys = [h.hotkeys; hotkey];
            end
            
%             h.hotkeys.(key) = fun;
        end
%         function rmHotkey(h, key)
%             h.hotkeys = rmfield(h.hotkeys, key);
%         end
        
        function closeWith(h,h_fig)
            % Add another figure to close when the player closes
            h.closeWithPlayer{end+1} = h_fig;
        end
        function OnClose(h)
            % Prevent error from quitting while playing
            h.isPlaying = false;
            for i = 1:numel(h.closeWithPlayer)
                delete(h.closeWithPlayer{i})
            end
            delete(h.fig)
            delete(h)
        end
    end
    
end

