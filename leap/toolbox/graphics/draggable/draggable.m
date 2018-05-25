function draggable(h,varargin)
% DRAGGABLE - Make it so that a graphics object can be dragged in a figure.
%   This function makes an object interactive by allowing it to be dragged
%   accross a set of axes, following or not certain constraints. This
%   allows for intuitive control elements which are not buttons or other
%   standard GUI objects, and which reside inside an axis. Typical use
%   involve markers on an axis, whose position alters the output of a
%   computation or display
% 
%   >> draggable(h);
%   
%   makes the object with handle "h" draggable. Use the "Position" property
%   of the object to retrieve its position, by issuing a get(h,'Position')
%   command.
% 
%   If h is a vector of handles, then draggable is called on each handle
%   using the same following arguments, if any.
%
%   >> draggable(h,...,motionfcn)
%
%   where "motionfcn" is a function handle, executes the given function
%   while the object is dragged. Handle h is passed to motionfcn as an
%   argument. Argument "motionfcn" can be put anywhere after handle "h".
%
%   >> draggable(h,...,constraint,p);
%
%   enables the object with handle "h" to be dragged, with a constraint.
%   Arguments "constraint" (a string) and "p" (a vector) can be put
%   anywhere after handle "h".
%
%   >> draggable(h,...,'endfcn',endfcn);
%
%   where "endfcn" is a function handle, executes the given function AFTER
%   the object is dragged (more specifically, on the next WindowButtonUp 
%   event). The function handle must come after the string 'endfcn', to 
%   avoid ambiguity with the "motionfcn" argument (above). Handle h is 
%   passed to endfcn as an argument.
%
%   >> draggable(h,'off')
%
%   returns object h to its original, non-draggable state.
%
%   CONSTRAINTS
%
%   The argument "constraint" may be one of the following strings:
%
%       'n' or 'none':          The object is unconstrained (default).
%       'h' or 'horizontal':    The object can only be moved horizontally.
%       'v' or 'vertical':      The object can only be moved vertically.
%       'd' or 'diagonal':      The object can only be moved along an
%                               arbitrary line of a given slope.
%
%   The argument "p" is an optional parameter which depends upon the
%   constraint type:
%
%   Constraint      p                   Description
%   -----------------------------------------------------------------------
%
%   'none'          [x1 x2 y1 y2]       Drag range (for the object's outer
%                                       limits, from x1 to x2 on the x-axis
%                                       and from y1 to y2 on the y-axis).
%                                       Default is the current axes range.
%                                       Use "inf" if no limit is desired.
%
%   'horizontal'    [xmin xmax]         Drag range (for the object's outer
%                                       limits). Default is the x-axis
%                                       range. Use "inf" if no limit is
%                                       desired. Note that full limits of
%                                       the form [x1 x2 y1 y2] can also be
%                                       used.
%
%   'vertical'      [ymin ymax]         Drag range (for the object's outer
%                                       limits). Default is the y-axis
%                                       range. Use "inf" if no limit is
%                                       desired. Note that full limits of
%                                       the form [x1 x2 y1 y2] can also be
%                                       used.
%
%   'diagonal'      [m x1 x2 y1 y2]     Slope m of the line along which the
%                                       movement is constrained (default is
%                                       1); x1 x2 y1 y2 as in 'none'.
%
%   -----------------------------------------------------------------------
%



% VERSION INFORMATION:
% 2003-11-20:   Initially submitted to MatlabCentral.Com
% 2004-01-06:   Addition of the renderer option, as proposed by Ohad Gal
%               as a feedback on MatlabCentral.Com.
% 2004-02-18:   Bugfix: now works with 1-element plots and line objects
% 2004-03-04:   Bugfix: sanitized the way the object's new position is
%               computed; it now always follow the mouse even after the
%               mouse pointer was out of the axes.
% 2004-03-05:   Bugfix: movement when mouse is out of the axes is now
%               definitely correct ;)
% 2006-05-23:   Bugfix: fix a rendering issue using Matlab 7 & +
%               Deprecated the rendering options: rendering seems ok with
%               every renderer.
% 2010-01-11:   Bugfix by Gilles Fortin (odd jumping on limits caused by
%               round-off error due to successive addition then subtraction
%               of the same value)
% 2010-02-26:   endfcn code by Steven Bierer included.
%               Some suggested M-Lint fixes performed.
% 2012-01-18:   - Refactoring
%               - Limits of the form [x1 x2 y1 y2] can be used for 'h' and
%                 'v' constraint types;
%               - Support for text objects;
%               - Added diagonal constraint type
% 2012-01-20:   - Tested
%               - Added support for h as a vector of handles
%               - 'sliders' demo added in dragdemo
% 2013-01-10:   Bugfix: finding the figure's handle through gcbf in order 
%               to fix a bug when axes are embedded into a Panel. 
%               (Bug found by Esmerald Aliai)


% IMPLEMENTATION NOTES:
%
% This function uses the dragged object's "ButtonDownFcn" function and set
% it so that the objec becomes draggable. Any previous "ButtonDownFcn" is 
% thus lost during operation, but is retrieved after issuing the 
% draggable(h,'off') command.
%
% Information about the object's behavior is also stored in the object's
% 'UserData' property, using setappdata() and getappdata(). The original
% 'UserData' property is restored after issuing the draggable(h,'off')
% command.
%
% The corresponding figure's "WindowButtonDownFcn", "WindowButtonUpFcn" and
% "WindowButtonMotionFcn" functions.  During operation, those functions are
% set by DRAGGABLE; however, the original ones are restored after the user
% stops dragging the object.
%
% By default, DRAGGABLE also switches the figure's renderer to 'zbuffer'
% during operation: 'painters' is not fast enough and 'opengl' sometimes
% produce curious results. However there may be a need to switch to another
% renderer, so the user can now specify a specific figure renderer during
% object drag (thanks to Ohad Gal for the suggestion).
%
% The "motionfcn" function handle is called at each displacement, after the
% object's position is updated, using "feval(motionfcn,h)", where h is the
% object's handle.

% =========================================================================
% Copyright (C) 2003-2012
% Francois Bouffard
% fbouffard@gmail.com
% =========================================================================

% =========================================================================
% Input arguments management
% =========================================================================

% If h is a vector of handle, applying draggable on each object and
% returning.
if length(h) > 1
    for k = 1:length(h)
        draggable(h(k),varargin{:});
    end
    return
end

% Initialization of some default arguments
user_renderer = 'zbuffer';
user_movefcn = [];
constraint = 'none';
p = [];
user_endfcn = [];       % added by SMB (see 'for k' loop below)
endinput = 0;

% At least the handle to the object must be given
Narg = nargin;
if Narg == 0
    error('Not engough input arguments');
elseif numel(h)>1
    error('Only one object at a time can be made draggable');
end;

% Fetching informations about the parent axes
axh = get(h,'Parent');
if iscell(axh)
    axh = axh{1};
end;
%fgh = get(axh,'Parent'); % This fails if the axes are embedded in a Panel
fgh = gcbf; % This should always work
ax_xlim = get(axh,'XLim');
ax_ylim = get(axh,'YLim');

% Assigning optional arguments
Noptarg = Narg - 1;
for k = 1:Noptarg
   current_arg = varargin{k};
   if isa(current_arg,'function_handle') && endinput
       user_endfcn = current_arg; % added by SMB
       endinput = 0;              % 'movefcn' can still be a later argument
   elseif isa(current_arg,'function_handle')
       user_movefcn = current_arg;
   end;
   if ischar(current_arg);
       switch lower(current_arg)
           case {'off'}
               set_initial_state(h);
               return;
           case {'painters','zbuffer','opengl'}
               warning('DRAGGABLE:DEPRECATED_OPTION', ...
                       'The renderer option is deprecated and will not be taken into account');
               user_renderer = current_arg;
           case {'endfcn'} % added by SMB
               endinput = 1;
           otherwise
               constraint = current_arg;
       end;
   end;
   if isnumeric(current_arg);
       p = current_arg;
   end;
end;

% Assigning defaults for constraint parameter
switch lower(constraint)
    case {'n','none'}
        constraint = 'n';
        if isempty(p); p = [ax_xlim ax_ylim]; end;
    case {'h','horizontal'}
        constraint = 'h';
        if isempty(p) 
            p = ax_xlim;
        elseif length(p) == 4
            p = p(1:2);
        end
    case {'v','vertical'}
        constraint = 'v';
        if isempty(p)
            p = ax_ylim; 
        elseif length(p) == 4
            p = p(3:4);
        end
    case {'d','diagonal','l','locked'}
        constraint = 'd';
        if isempty(p)
            p = [1 ax_xlim ax_ylim]; 
        elseif length(p) == 1
            p = [p ax_xlim ax_ylim];
        end;
    otherwise
        error('Unknown constraint type');
end;

% =========================================================================
% Saving initial state and parameters, setting up the object callback
% =========================================================================

% Saving object's and parent figure's initial state
setappdata(h,'initial_userdata',get(h,'UserData'));
setappdata(h,'initial_objbdfcn',get(h,'ButtonDownFcn'));
setappdata(h,'initial_renderer',get(fgh,'Renderer'));
setappdata(h,'initial_wbdfcn',get(fgh,'WindowButtonDownFcn'));
setappdata(h,'initial_wbufcn',get(fgh,'WindowButtonUpFcn'));
setappdata(h,'initial_wbmfcn',get(fgh,'WindowButtonMotionFcn'));

% Saving parameters
setappdata(h,'constraint_type',constraint);
setappdata(h,'constraint_parameters',p);
setappdata(h,'user_movefcn',user_movefcn);
setappdata(h,'user_endfcn',user_endfcn);        % added by SMB
setappdata(h,'user_renderer',user_renderer);

% Setting the object's ButtonDownFcn
set(h,'ButtonDownFcn',@click_object);

% =========================================================================
% FUNCTION click_object
%   Executed when the object is clicked
% =========================================================================

function click_object(obj,eventdata)
% obj here is the object to be dragged and gcf is the object's parent
% figure since the user clicked on the object
setappdata(obj,'initial_position',get_position(obj));
setappdata(obj,'initial_extent',compute_extent(obj));
setappdata(obj,'initial_point',get(gca,'CurrentPoint'));
set(gcf,'WindowButtonDownFcn',{@activate_movefcn,obj});
set(gcf,'WindowButtonUpFcn',{@deactivate_movefcn,obj});
activate_movefcn(gcf,eventdata,obj);

% =========================================================================
% FUNCTION activate_movefcn
%   Activates the WindowButtonMotionFcn for the figure
% =========================================================================

function activate_movefcn(obj,eventdata,h)
% We were once setting up renderers here. Now we only set the movefcn
set(obj,'WindowButtonMotionFcn',{@movefcn,h});

% =========================================================================
% FUNCTION deactivate_movefcn
%   Deactivates the WindowButtonMotionFcn for the figure
% =========================================================================

function deactivate_movefcn(obj,eventdata,h)
% obj here is the figure containing the object
% Setting the original MotionFcn, DuttonDownFcn and ButtonUpFcn back
set(obj,'WindowButtonMotionFcn',getappdata(h,'initial_wbmfcn'));
set(obj,'WindowButtonDownFcn',getappdata(h,'initial_wbdfcn'));
set(obj,'WindowButtonUpFcn',getappdata(h,'initial_wbufcn'));
% Executing the user's drag end function
user_endfcn = getappdata(h,'user_endfcn');
if ~isempty(user_endfcn)
    feval(user_endfcn,h);           % added by SMB, modified by FB
end

% =========================================================================
% FUNCTION set_initial_state
%   Returns the object to its initial state
% =========================================================================

function set_initial_state(h)
initial_objbdfcn = getappdata(h,'initial_objbdfcn');
initial_userdata = getappdata(h,'initial_userdata');
set(h,'ButtonDownFcn',initial_objbdfcn);
set(h,'UserData',initial_userdata);

% =========================================================================
% FUNCTION movefcn
%   Actual code for dragging the object
% =========================================================================

function movefcn(obj,eventdata,h)
% obj here is the *figure* containing the object

% Retrieving data saved in the figure
% Reminder: "position" refers to the object position in the axes
%           "point" refers to the location of the mouse pointer
initial_point = getappdata(h,'initial_point');
constraint = getappdata(h,'constraint_type');
p = getappdata(h,'constraint_parameters');
user_movefcn = getappdata(h,'user_movefcn');

% Getting current mouse position
current_point = get(gca,'CurrentPoint');

% Computing mouse movement (dpt is [dx dy])
cpt = current_point(1,1:2);
ipt = initial_point(1,1:2);
dpt = cpt - ipt;

% Dealing with the pathetic cases of zero or infinite slopes
if strcmpi(constraint,'d')
    if p(1) == 0
        constraint = 'h';
        p = p(2:end);
    elseif isinf(p(1))
        constraint = 'v';
        p = p(2:end);
    end
end

% Computing movement range and imposing movement constraints
% (p is always [xmin xmax ymin ymax])
switch lower(constraint)
    case 'n'
        range = p;
    case 'h'
        dpt(2) = 0;
        range = [p -inf inf];
    case 'v'
        dpt(1) = 0;
        range = [-inf inf p];
    case 'd'
        % Multiple options here as to how we use dpt to move the object
        % along a diagonal. 
        % We could use the largest of abs(dpt) for judging movement, but
        % this causes weird behavior in some cases. E.g. when the slope
        % is gentle (<1) and dy is the largest, the object will move
        % rapidly far away from the mouse pointer.
        % Another option (see below) is to follow dx when the 
        % slope is <1 and dy when the slope is >= 1.
 
        %if abs(p(1)) >=1
        %    dpt = [dpt(2)/p(1) dpt(2)];
        %else
        %    dpt = [dpt(1) p(1)*dpt(1)];
        %end
        
        % Projecting dpt along the diagonal seems to work really well.
        v = [1; p(1)];
        Pv = v*v'/(v'*v);
        dpt = dpt*Pv;
        
        range = p(2:5);
end

% Computing new position.
% What we want is actually a bit complex: we want the object to adopt the 
% new position, unless it gets out of range. If it gets out of range in a 
% direction, we want it to stick to the limit in that direction. Also, if 
% the object is out of range at the beginning of the movement, we want to 
% be able to move it back into range; movement must then be allowed.

% For debugging purposes only; setting debug to 1 shows range, extents,
% dpt, corrected dpt and in-range status of the object in the command
% window. Note: this will clear the command window.
debug = 0;
idpt = dpt;

% Computing object extent in the [x y w h] format before and after moving
initial_extent = getappdata(h,'initial_extent');
new_extent = initial_extent + [dpt 0 0];

% Verifying if old and new objects breach the allowed range in any
% direction (see the function is_inside_range below)
initial_inrange = is_inside_range(initial_extent,range);
new_inrange = is_inside_range(new_extent,range);

% Modifying dpt to stick to range limit if range violation occured,
% but the movement won't get restricted if the object was out of
% range to begin with.
%
% We use if/ends and no elseif's because once an object hits a range limit,
% it is still free to move along the other axis, and another range limit
% could be hit aftwards. That is, except for diagonal constraints, in 
% which a first limit hit must completely lock the object until the mouse
% is inside the range.

% In-line correction functions to dpt due to range violations
xminc = @(dpt) [range(1) - initial_extent(1) dpt(2)];
xmaxc = @(dpt) [range(2) - (initial_extent(1) + initial_extent(3)) dpt(2)];
yminc = @(dpt) [dpt(1) range(3) - initial_extent(2)];
ymaxc = @(dpt) [dpt(1) range(4) - (initial_extent(2) + initial_extent(4))];

% We build a list of corrections to apply
corrections = {};
if initial_inrange(1) && ~new_inrange(1)
    % was within, now out of xmin range -- add xminc
    corrections = [corrections {xminc}];
end
if initial_inrange(2) && ~new_inrange(2)
    % was within, now out of xmax range -- add xmaxc
    corrections = [corrections {xmaxc}];
end
if initial_inrange(3) && ~new_inrange(3)
    % was within, now out of ymin range -- add yminc
    corrections = [corrections {yminc}];
end
if initial_inrange(4) && ~new_inrange(4)
    % was within, now out of ymax range -- add ymaxc
    corrections = [corrections {ymaxc}];
end

% Applying all corrections, except for objects following a diagonal
% constraint, which must stop at the first one
if ~isempty(corrections)
    if strcmpi(constraint,'d')
        c = corrections{1};
        dpt = c(dpt);
        % Forcing the object to remain on the diagonal constraint
        if isequal(c,xminc) || isequal(c,xmaxc) % horizontal correction
            dpt(2) = p(1)*dpt(1);
        elseif isequal(c,yminc) || isequal(c,ymaxc) % vertical correction
            dpt(1) = dpt(2)/p(1);
        end
    else
        % Just applying all corrections
        for c = corrections
            dpt = c{1}(dpt);
        end
    end
end

% Debug messages
if debug
    if all(new_inrange)
        status = 'OK';
    else
        status = 'RANGE VIOLATION';
    end
    clc
    disp(sprintf('          range: %0.3f %0.3f %0.3f %0.3f', range));
    disp(sprintf(' initial extent: %0.3f %0.3f %0.3f %0.3f', initial_extent))
    disp(sprintf('     new extent: %0.3f %0.3f %0.3f %0.3f', new_extent))
    disp(sprintf('initial inrange: %d %d %d %d', initial_inrange))
    disp(sprintf('    new inrange: %d %d %d %d [%s]', new_inrange, status))
    disp(sprintf('    initial dpt: %0.3f %0.3f', idpt))
    disp(sprintf('  corrected dpt: %0.3f %0.3f', dpt))
end

% Re-computing new position with modified dpt
newpos = update_position(getappdata(h,'initial_position'),dpt);

% Setting the new position which actually moves the object
set_position(h,newpos);

% Calling user-provided function handle
if ~isempty(user_movefcn)
    feval(user_movefcn,h);
end;

% =========================================================================
% FUNCTION get_position
%   Return an object's position: [x y [z / w h]] or [xdata; ydata]
% =========================================================================
function pos = get_position(obj)
props = get(obj);
if isfield(props,'Position')
    pos = props.Position;
elseif isfield(props,'XData')
    pos = [props.XData(:)'; props.YData(:)'];
else
    error('Unable to find position');
end

% =========================================================================
% FUNCTION update_position
%   Adds dpt to a position specification as returned by get_position
% =========================================================================
function newpos = update_position(pos,dpt)
newpos = pos;
if size(pos,1) == 1 % [x y [z / w h]]
    newpos(1:2) = newpos(1:2) + dpt;
else                % [xdata; ydata]
    newpos(1,:) = newpos(1,:) + dpt(1);
    newpos(2,:) = newpos(2,:) + dpt(2);
end

% =========================================================================
% FUNCTION set_position
%   Sets the position of an object obj using get_position's format
% =========================================================================
function set_position(obj,pos)
if size(pos,1) == 1 % 'Position' property
    set(obj,'Position',pos);
else                % 'XData/YData' properties
    set(obj,'XData',pos(1,:),'YData',pos(2,:));
end

% =========================================================================
% FUNCTION compute_extent
%   Computes an object's extent for different object types;
%   extent is [x y w h]
% =========================================================================

function extent = compute_extent(obj)
props = get(obj);
if isfield(props,'Extent')
    extent = props.Extent;
elseif isfield(props,'Position')
    extent = props.Position;
elseif isfield(props,'XData')
    minx = min(props.XData);
    miny = min(props.YData);
    w = max(props.XData) - minx;
    h = max(props.YData) - miny;
    extent = [minx miny w h];
else
    error('Unable to compute extent');
end
    
% =========================================================================
% FUNCTION is_inside_range
%   Checks if a rectangular object is entirely inside a rectangular range
% =========================================================================

function inrange = is_inside_range(extent,range)
% extent is in the [x y w h] format
% range is in the [xmin xmax ymin ymax] format
% inrange is a 4x1 vector of boolean values corresponding to range limits
inrange = [extent(1) >= range(1) ...
           extent(1) + extent(3) <= range(2) ...
           extent(2) >= range(3) ...
           extent(2) + extent(4) <= range(4)];