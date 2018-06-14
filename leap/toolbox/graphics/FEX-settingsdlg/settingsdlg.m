function [settings, button] = settingsdlg(varargin)
% SETTINGSDLG             Default dialog to produce a settings-structure
%
% settings = SETTINGSDLG('fieldname', default_value, ...) creates a modal
% dialog box that returns a structure formed according to user input. The
% input should be given in the form of 'fieldname', default_value - pairs,
% where 'fieldname' is the fieldname in the structure [settings], and
% default_value the initial value displayed in the dialog box.
%
% SETTINGSDLG uses UIWAIT to suspend execution until the user responds.
%
% settings = SETTINGSDLG(settings) uses the structure [settings] to form
% the various input fields. This is the most basic (and limited) usage of
% SETTINGSDLG.
%
% [settings, button] = SETTINGSDLG(settings) returns which button was
% pressed, in addition to the (modified) structure [settings]. Either 'ok',
% 'cancel' or [] are possible values. The empty output means that the
% dialog was closed before either Cancel or OK were pressed.
%
% SETTINGSDLG('title', 'window_title') uses 'window_title' as the dialog's
% title. The default is 'Adjust settings'.
%
% SETTINGSDLG('description', 'brief_description',...) starts the dialog box
% with 'brief_description', followed by the input fields.
%
% SETTINGSDLG('windowposition', P, ...) positions the dialog box according to
% the string or vector [P]; see movegui() for valid values.
%
% SETTINGSDLG( {'display_string', 'fieldname'}, default_value,...) uses the
% 'display_string' in the dialog box, while assigning the corresponding
% user-input to fieldname 'fieldname'.
%
% SETTINGSDLG(..., 'checkbox_string', true, ...) displays a checkbox in
% stead of the default edit box, and SETTINGSDLG('fieldname', {'string1',
% 'string2'},... ) displays a popup box with the strings given in
% the second cell-array.
%
% Additionally, you can put [..., 'separator', 'seperator_string',...]
% anywhere in the argument list, which will divide all the arguments into
% sections, with section headings 'seperator_string'.
%
% You can also modify the display behavior in the case of checkboxes. When
% defining checkboxes with a 2-element logical array, the second boolean
% determines whether all fields below that checkbox are initially disabled
% (true) or not (false).
%
% Example:
%
% [settings, button] = settingsdlg(...
%     'Description', 'This dialog will set the parameters used by FMINCON()',...
%     'title'      , 'FMINCON() options',...
%     'separator'  , 'Unconstrained/General',...
%     {'This is a checkbox'; 'Check'}, [true true],...
%     {'Tolerance X';'TolX'}, 1e-6,...
%     {'Tolerance on Function';'TolFun'}, 1e-6,...
%     'Algorithm'  , {'active-set','interior-point'},...
%     'separator'  , 'Constrained',...
%     {'Tolerance on Constraints';'TolCon'}, 1e-6)
%
% See also inputdlg, dialog, errordlg, helpdlg, listdlg, msgbox, questdlg, textwrap,
% uiwait, warndlg.


% Please report bugs and inquiries to:
%
% Name   : Rody P.S. Oldenhuis
% E-mail : oldenhuis@gmail.com
% Licence: 2-clause BSD (See Licence.txt)


% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5

    %% Initialize

    % errortraps
    narg = nargin;
    if verLessThan('MATLAB', '8.6')
        error(nargchk(1, inf, narg, 'struct')); %#ok<NCHKN>
    else
        narginchk(1, inf);
    end

    % parse input (+errortrap)
    have_settings = 0;
    if isstruct(varargin{1})
        settings = varargin{1}; have_settings = 1; end
    if (narg == 1)
        if isstruct(varargin{1})
            parameters = fieldnames(settings);
            values = cellfun(@(x)settings.(x), parameters, 'UniformOutput', false);
        else
            error('settingsdlg:incorrect_input',...
                'When passing a single argument, that argument must be a structure.')
        end
    else
        parameters = varargin(1+have_settings : 2 : end);
        values     = varargin(2+have_settings : 2 : end);
    end

    % Initialize data
    button = [];
    fields = cell(numel(parameters),1);
    tags   = fields;

    % Fill [settings] with default values & collect data
    for ii = 1:numel(parameters)

        % Extract fields & tags
        if iscell(parameters{ii})
            tags{ii}   = parameters{ii}{1};
            fields{ii} = parameters{ii}{2};
        else
            % More errortraps
            if ~ischar(parameters{ii})
                error('settingsdlg:nonstring_parameter',...
                'Arguments should be given as [''parameter'', value,...] pairs.')
            end
            tags{ii}   = parameters{ii};
            fields{ii} = parameters{ii};
        end

        % More errortraps
        if ~ischar(fields{ii})
            error('settingsdlg:fieldname_not_char',...
                'Fieldname should be a string.')
        end
        if ~ischar(tags{ii})
            error('settingsdlg:tag_not_char',...
                'Display name should be a string.')
        end

        % NOTE: 'Separator' is now in 'fields' even though
        % it will not be used as a fieldname

        % Make sure all fieldnames are properly formatted
        % (alternating capitals, no whitespace)
        if ~strcmpi(fields{ii}, {'Separator';'Title';'Description'})
            whitespace = isspace(fields{ii});
            capitalize = circshift(whitespace,[0,1]);
            fields{ii}(capitalize) = upper(fields{ii}(capitalize));
            fields{ii} = fields{ii}(~whitespace);
            % insert associated value in output
            if iscell(values{ii})
                settings.(fields{ii}) = values{ii}{1};
            elseif (length(values{ii}) > 1)
                settings.(fields{ii}) = values{ii}(1);
            else
                settings.(fields{ii}) = values{ii};
            end
        end
    end

    % Avoid (some) confusion
    clear parameters

    % Use default colorscheme from the OS
    bgcolor = get(0, 'defaultUicontrolBackgroundColor');
    % Default fontsize
    fontsize = get(0, 'defaultuicontrolfontsize');
    % Edit-bgcolor is platform-dependent.
    % MS/Windows: white.
    % UNIX: same as figure bgcolor
%     if ispc, edit_bgcolor = 'White';
%     else     edit_bgcolor = bgcolor;
%     end

% TODO: not really applicable since defaultUicontrolBackgroundColor
% doesn't really seem to work on Unix...
edit_bgcolor = 'White';

    % Get basic window properties
    title         = getValue('Adjust settings', 'Title');
    description   = getValue( [], 'Description');
    total_width   = getValue(325, 'WindowWidth');
    control_width = getValue(100, 'ControlWidth');

    % Window positioning:
    % Put the window in the center of the screen by default.
    % This will usually work fine, except on some  multi-monitor setups.
    scz  = get(0, 'ScreenSize');
    scxy = round(scz(3:4)/2-control_width/2);
    scx  = min(scz(3),max(1,scxy(1)));
    scy  = min(scz(4),max(1,scxy(2)));

    % String to pass on to movegui
    window_position = getValue('center', 'WindowPosition');


    % Calculate best height for all uicontrol()
    control_height = max(18, (fontsize+6));

    % Calculate figure height (will be adjusted later according to description)
    total_height = numel(fields)*1.25*control_height + ... % to fit all controls
                     1.5*control_height + 20; % to fit "OK" and "Cancel" buttons

    % Total number of separators
    num_separators = nnz(strcmpi(fields,'Separator'));

    % Draw figure in background
    fighandle = figure(...
         'integerhandle'   , 'off',...         % use non-integers for the handle (prevents accidental plots from going to the dialog)
         'Handlevisibility', 'off',...         % only visible from within this function
         'position'        , [scx, scy, total_width, total_height],...% figure position
         'visible'         , 'off',...         % hide the dialog while it is being constructed
         'backingstore'    , 'off',...         % DON'T save a copy in the background
         'resize'          , 'off', ...        % but just keep it resizable
         'renderer'        , 'zbuffer', ...    % best choice for speed vs. compatibility
         'WindowStyle'     ,'modal',...        % window is modal
         'units'           , 'pixels',...      % better for drawing
         'DockControls'    , 'off',...         % force it to be non-dockable
         'name'            , title,...         % dialog title
         'menubar'         ,'none', ...        % no menubar of course
         'toolbar'         ,'none', ...        % no toolbar
         'NumberTitle'     , 'off',...         % "Figure 1.4728...:" just looks corny
         'color'           , bgcolor);         % use default colorscheme

    %% Draw all required uicontrols(), and unhide window

    % Define X-offsets (different when separators are used)
    separator_offset_X = 2;
    if num_separators > 0
        text_offset_X = 20;
        text_width = (total_width-control_width-text_offset_X);
    else
        text_offset_X = separator_offset_X;
        text_width = (total_width-control_width);
    end

    % Handle description
    description_offset = 0;
    if ~isempty(description)

        % create textfield (negligible height initially)
        description_panel = uicontrol(...
            'parent'  , fighandle,...
            'style'   , 'text',...
            'Horizontalalignment', 'left',...
            'position', [separator_offset_X,...
                         total_height,total_width,1]);

        % wrap the description
        description = textwrap(description_panel, {description});

        % adjust the height of the figure
        textheight = size(description,1)*(fontsize+6);
        description_offset = textheight + 20;
        total_height = total_height + description_offset;
        set(fighandle,...
            'position', [scx, scy, total_width, total_height])

        % adjust the position of the textfield and insert the description
        set(description_panel, ...
            'string'  , description,...
            'position', [separator_offset_X, total_height-textheight, ...
                         total_width, textheight]);
    end

    % Define Y-offsets (different when descriptions are used)
    control_offset_Y = total_height-control_height-description_offset;

    % initialize loop
    controls = zeros(numel(tags)-num_separators,1);
    ii = 1;             sep_ind = 1;
    enable = 'on';      separators = zeros(num_separators,1);

    % loop through the controls
    if numel(tags) > 0
        while true

            % Should we draw a separator?
            if strcmpi(tags{ii}, 'Separator')

                % Print separator
                uicontrol(...
                    'style'   , 'text',...
                    'parent'  , fighandle,...
                    'string'  , values{ii},...
                    'horizontalalignment', 'left',...
                    'fontweight', 'bold',...
                    'position', [separator_offset_X,control_offset_Y-4, ...
                    total_width, control_height]);

                % remove separator, but save its position
                fields(ii) = [];
                tags(ii)   = [];  separators(sep_ind) = ii;
                values(ii) = [];  sep_ind = sep_ind + 1;

                % reset enable (when neccessary)
                if strcmpi(enable, 'off')
                    enable = 'on'; end

                % NOTE: DON'T increase loop index

            % ... or a setting?
            else

                % logicals: use checkbox
                if islogical(values{ii})

                    % First draw control
                    controls(ii) = uicontrol(...
                        'style'   , 'checkbox',...
                        'parent'  , fighandle,...
                        'enable'  , enable,...
                        'string'  , tags{ii},...
                        'value'   , values{ii}(1),...
                        'position', [text_offset_X,control_offset_Y-4, ...
                        total_width, control_height]);

                    % Should everything below here be OFF?
                    if (length(values{ii})>1)
                        % turn next controls off when asked for
                        if values{ii}(2)
                            enable = 'off'; end
                        % Turn on callback function
                        set(controls(ii),...
                            'Callback', @(varargin) EnableDisable(ii,varargin{:}));
                    end

                % doubles      : use edit box
                % cells        : use popup
                % cell-of-cells: use table
                else
                    % First print parameter
                    uicontrol(...
                        'style'   , 'text',...
                        'parent'  , fighandle,...
                        'string'  , [tags{ii}, ':'],...
                        'horizontalalignment', 'left',...
                        'position', [text_offset_X,control_offset_Y-4, ...
                        text_width, control_height]);

                    % Popup, edit box or table?
                    style = 'edit';
                    draw_table = false;
                    if iscell(values{ii})
                        style = 'popup';
                        if all(cellfun('isclass', values{ii}, 'cell'))
                            draw_table = true; end
                    end

                    % Draw appropriate control
                    if ~draw_table
                        controls(ii) = uicontrol(...
                            'enable'  , enable,...
                            'style'   , style,...
                            'Background', edit_bgcolor,...
                            'parent'  , fighandle,...
                            'string'  , values{ii},...
                            'position', [text_width,control_offset_Y,...
                            control_width, control_height]);
                    else
                        % TODO
                        % ...table? ...radio buttons? How to do this?
                        warning(...
                            'settingsdlg:not_yet_implemented',...
                            'Treatment of cells is not yet implemented.');

                    end
                end

                % increase loop index
                ii = ii + 1;
            end

            % end loop?
            if ii > numel(tags)
                break, end

            % Decrease offset
            control_offset_Y = control_offset_Y - 1.25*control_height;
        end
    end

    % Draw cancel button
    uicontrol(...
        'style'   , 'pushbutton',...
        'parent'  , fighandle,...
        'string'  , 'Cancel',...
        'position', [separator_offset_X,2, total_width/2.5,control_height*1.5],...
        'Callback', @Cancel)

    % Draw OK button
    uicontrol(...
        'style'   , 'pushbutton',...
        'parent'  , fighandle,...
        'string'  , 'OK',...
        'position', [total_width*(1-1/2.5)-separator_offset_X,2, ...
                     total_width/2.5,control_height*1.5],...
        'Callback', @OK)

    % move to center of screen and make visible
    movegui(fighandle, window_position);
    set(fighandle, 'Visible', 'on');

    % WAIT until OK/Cancel is pressed
    uiwait(fighandle);



    %% Helper funcitons

    % Get a value from the values array:
    % - if it does not exist, return the default value
    % - if it exists, assign it and delete the appropriate entries from the
    %   data arrays
    function val = getValue(default, tag)
        index = strcmpi(fields, tag);
        if any(index)
            val = values{index};
            values(index) = [];
            fields(index) = [];
            tags(index)   = [];
        else
            val = default;
        end
    end

    %% callback functions

    % Enable/disable controls associated with (some) checkboxes
    function EnableDisable(which, varargin) %#ok<VANUS>

        % find proper range of controls to switch
        if (num_separators > 1)
             last_control = separators(find(separators > which,1)) - 1;
             if isempty(last_control); last_control = numel(controls); end
             
             range = (which+1):(last_control);
        else
            range = (which+1):numel(controls);
        end

        % enable/disable these controls
        if strcmpi(get(controls(range(1)), 'enable'), 'off')
            set(controls(range), 'enable', 'on')
        else
            set(controls(range), 'enable', 'off')
        end
    end

    % OK button:
    % - update fields in [settings]
    % - assign [button] output argument ('ok')
    % - kill window
    function OK(varargin) %#ok<VANUS>

        % button pressed
        button = 'OK';

        % fill settings
        for i = 1:numel(controls)

            % extract current control's string, value & type
            str   = get(controls(i), 'string');
            val   = get(controls(i), 'value');
            style = get(controls(i), 'style');

            % popups/edits
            if ~strcmpi(style, 'checkbox')
                % extract correct string (popups only)
                if strcmpi(style, 'popupmenu'), str = str{val}; end
                % try to convert string to double
                val = str2double(str);
                % insert this double in [settings]. If it was not a
                % double, insert string instead
                if ~isnan(val), settings.(fields{i}) = val;
                else            settings.(fields{i}) = str;
                end

            % checkboxes
            else
                % we can insert value immediately
                settings.(fields{i}) = val;
            end
        end

        %  kill window
        delete(fighandle);
    end

    % Cancel button:
    % - assign [button] output argument ('cancel')
    % - delete figure (so: return default settings)
    function Cancel(varargin) %#ok<VANUS>
        button = 'cancel';
        delete(fighandle);
    end

end
