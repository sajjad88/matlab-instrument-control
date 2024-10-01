function triggerArrayGUI(obj, GUIParent)
%createTriggeringArray opens a GUI that can create a triggering array.
% This method will open a GUI which allows the user to define a
% 'TriggeringArray', i.e., an array defining a simple DAC/TTL program based
% on a trigger signal. 
%
% NOTE: The primary intention of this method is to generate the class 
%       SignalStruct (which also defines the dependent property 
%       SignalArray), which is a structure with the following fields (to 
%       define this manually outside of this GUI, you only need to set
%       'Identifier' and 'Signal'):
%       NPoints: Number of points in the signal.
%       InPhase: 1 if the signal starts HIGH, 0 otherwise.
%       Period: Period of the signal with respect to the trigger, e.g., a
%               period of 4 means that the signal toggles every other 
%               trigger event.
%       Range: Range of voltages present in the signal [min., max.].
%       IsLogical: 1 if the signal is logical (e.g., TTL or trigger)
%                  0 if the signal is analog (e.g., DAC)
%   	Handle: Line handle for the signal in this GUI.
%       Identifier: char array defining which signal this is (the trigger
%                   is 'trigger', TTL's will be 'TTL' suffixed with port 
%                   number of field width 2, e.g., 'TTL07', DAC's will be 
%                   'DAC' suffixed with port number of field width 2, e.g., 
%                   'DAC03').
%       Alias: Recognizable char array defining what this signal is meant
%              to control, e.g., 'laser 405', 'attenuator', ...
%       Signal: Numeric array containing the signal, e.g., a DAC signal
%               might be something like [0, 5, 0, 2.5, 0, 5]
%
%
% INPUTS:
%   GUIParent: The 'Parent' of this GUI, e.g., a figure handle.
%              (Default = figure(...))

% Created by:
%   David J. Schodt (Lidke Lab, 2020)


% Create a figure handle for the GUI if needed.
if ~(exist('GUIParent', 'var') && ~isempty(GUIParent) ...
        && isgraphics(GUIParent))
    DefaultFigurePosition = get(0, 'defaultFigurePosition');
    GUIParent = figure('MenuBar', 'none', ...
        'Name', 'Trigger Array GUI', 'NumberTitle', 'off', ...
        'Units', 'pixels', ...
        'Position', DefaultFigurePosition .* [0.5, 1, 1.5, 1]);
end
GUIParent.CloseRequestFcn = @figureClosing;

% Generate some panels to help organize the GUI.
TriggerPanel = uipanel(GUIParent, 'Title', 'Trigger', ...
    'Units', 'normalized', 'Position', [0, 0.8, 0.2, 0.2]);
TTLPanel = uipanel(GUIParent, 'Title', 'TTL', ...
    'Units', 'normalized', 'Position', [0, 0.4, 0.2, 0.4]);
DACPanel = uipanel(GUIParent, 'Title', 'DAC', ...
    'Units', 'normalized', 'Position', [0, 0, 0.2, 0.4]);
PlotPanel = uipanel(GUIParent, ...
    'Units', 'normalized', 'Position', [0.2, 0.1, 0.8, 0.9]);
ControlPanel = uipanel(GUIParent, ...
    'Units', 'normalized', 'Position', [0.2, 0, 0.8, 0.1]);

% Add some controls to the TriggerPanel.
TextSize = [0, 0, 0.6, 0.2];
EditSize = [0, 0, 0.4, 0.2];
PopupSize = [0, 0, 0.4, 0.2];
DefaultTriggerParams.Alias = 'Trigger';
DefaultTriggerParams.NCycles = 2;
DefaultTriggerParams.TriggerModeIndex = 1;
TriggerAliasTooltip = 'Alias/nickname for this trigger, e.g., ''camera''';
uicontrol(TriggerPanel, 'Style', 'text', ...
    'String', 'Trigger alias: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', TriggerAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TriggerAliasEdit = uicontrol(TriggerPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.7, ...
    'String', DefaultTriggerParams.Alias, ...
    'Tooltip', TriggerAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize ...
    + [TextSize(3), 1-EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
NCyclesTooltip = 'Desired number of trigger pulses/sequences';
uicontrol(TriggerPanel, 'Style', 'text', ...
    'String', 'Number of cycles: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', NCyclesTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-2*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.NCyclesEdit = uicontrol(TriggerPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', num2str(DefaultTriggerParams.NCycles), ...
    'Tooltip', NCyclesTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-2*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'center', ...
    'Callback', @createTriggerSignal);
uicontrol(TriggerPanel, 'Style', 'text', ...
    'String', 'Trigger mode: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', NCyclesTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-3*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TriggerModePopup = uicontrol(TriggerPanel, ...
    'Style', 'popupmenu', ...
    'String', obj.TriggerModeOptions, ...
    'Value', DefaultTriggerParams.TriggerModeIndex, ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Units', 'normalized', ...
    'Position', PopupSize + [TextSize(3), 1-3*TextSize(4), 0, 0], ...
    'Callback', @triggerModeCallback);

% Add some controls to the TTLPanel.
TextSize = [0, 0, 0.5, 0.09];
EditSize = [0, 0, 0.5, 0.09];
PopupSize = [0, 0, 0.5, 0.09];
ButtonSize = [0, 0, 1, 0.18];
CheckSize = [0, 0, 0.25, 0.1];
uicontrol(TTLPanel, 'Style', 'text', ...
    'String', 'TTL port: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TTLPortPopup = uicontrol(TTLPanel, ...
    'Style', 'popupmenu', ...
    'String', num2str(transpose(1:obj.IOChannels)), ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Units', 'normalized', ...
    'Position', PopupSize + [TextSize(3), 1-TextSize(4), 0, 0], ...
    'Callback', @ttlPopupCallback);
TTLAliasTooltip = 'Alias/nickname for your TTL channel, e.g., ''laser''';
uicontrol(TTLPanel, 'Style', 'text', ...
    'String', 'TTL alias: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', TTLAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-3*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TTLAliasEdit = uicontrol(TTLPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', ['TTL ', num2str(ControlHandles.TTLPortPopup.Value)], ...
    'Tooltip', TTLAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-3*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
TTLPeriodTooltip = sprintf(...
    ['Period of this TTL signal with respect to the trigger events.\n', ...
    'For example, a period of 2 means that the TTL changes state\n', ...
    'with every trigger event, while a period of 4 means that the\n', ...
    'TTL changes state with every other trigger event.  Note that \n', ...
    'this value will be divided by 2 and rounded before being used']);
uicontrol(TTLPanel, 'Style', 'text', ...
    'String', 'Period: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', TTLPeriodTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-4*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TTLPeriodEdit = uicontrol(TTLPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', '2', 'Tooltip', TTLPeriodTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-4*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
TTLPhaseTooltip = sprintf(...
    ['The TTL phase specifies whether the signal is "in phase" with\n', ...
    'the trigger (in this context, in phase means it starts HIGH, \n', ...
    'just like the trigger)']);
uicontrol(TTLPanel, 'Style', 'text', ...
    'String', 'Signal in phase: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', TTLPhaseTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-5*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.TTLPhaseCheckbox = uicontrol(TTLPanel, ...
    'Style', 'checkbox', ...
    'Tooltip', TTLPhaseTooltip, ...
    'Value', 1, ...
    'Units', 'normalized', ...
    'Position', CheckSize + [TextSize(3), 1-5.1*TextSize(4), 0, 0]);
ControlHandles.AddTTLButton = uicontrol(TTLPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Add TTL signal', ...
    'Tooltip', 'Add a new TTL signal on the specified port', ...
    'Units', 'normalized', ...
    'Position', ButtonSize + [0, ButtonSize(4), 0, 0], ...
    'Callback', @addTTLCallback);
ControlHandles.DeleteTTLButton = uicontrol(TTLPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Delete TTL signal', ...
    'Tooltip', 'Delete the TTL signal defined for the specified port', ...
    'Units', 'normalized', ...
    'Position', ButtonSize, ...
    'Callback', @deleteTTLCallback);

% Add some controls to the DACPanel.
TextSize = [0, 0, 0.5, 0.09];
EditSize = [0, 0, 0.5, 0.09];
PopupSize = [0, 0, 0.5, 0.09];
ButtonSize = [0, 0, 1, 0.18];
CheckSize = [0, 0, 0.25, 0.1];
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'DAC port: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACPortPopup = uicontrol(DACPanel, ...
    'Style', 'popupmenu', ...
    'String', num2str(transpose(1:obj.IOChannels)), ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Units', 'normalized', ...
    'Position', PopupSize + [TextSize(3), 1-TextSize(4), 0, 0], ...
    'Callback', @dacPopupCallback);
DACAliasTooltip = 'Alias/nickname for your DAC channel, e.g., ''laser''';
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'DAC alias: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', DACAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-3*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACAliasEdit = uicontrol(DACPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', ['DAC ', num2str(ControlHandles.DACPortPopup.Value)], ...
    'Tooltip', DACAliasTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-3*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
DACPeriodTooltip = sprintf(...
    ['Period of this DAC signal with respect to the trigger events.\n', ...
    'For example, a period of 2 means that the DAC changes state\n', ...
    'with every trigger event, while a period of 4 means that the\n', ...
    'DAC changes state with every other trigger event.  Note that \n', ...
    'this value will be divided by 2 and rounded before being used']);
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'Period: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', DACPeriodTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-4*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACPeriodEdit = uicontrol(DACPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', '2', 'Tooltip', DACPeriodTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-4*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
DACPhaseTooltip = sprintf(...
    ['The DAC phase specifies whether the signal is "in phase" with\n', ...
    'the trigger (in this context, in phase means it starts at\n', ...
    'Voltage HIGH, just like the trigger)']);
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'Signal in phase: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', DACPhaseTooltip, ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-5*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACPhaseCheckbox = uicontrol(DACPanel, ...
    'Style', 'checkbox', ...
    'Tooltip', DACPhaseTooltip, ...
    'Value', 1, ...
    'Units', 'normalized', ...
    'Position', CheckSize + [TextSize(3), 1-5.1*TextSize(4), 0, 0]);
VoltageRangeDefault = obj.VoltageRangeOptions(...
    obj.DACStatus(ControlHandles.DACPortPopup.Value).VoltageRangeIndex, :);
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'Voltage LOW: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', 'Voltage output when ''off''', ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-6*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACLowEdit = uicontrol(DACPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', VoltageRangeDefault(1), ...
    'Tooltip', 'Voltage output when ''off''', ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-6*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
uicontrol(DACPanel, 'Style', 'text', ...
    'String', 'Voltage HIGH: ', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'Tooltip', 'Voltage output when ''on''', ...
    'Units', 'normalized', ...
    'Position', TextSize + [0, 1-7*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'right');
ControlHandles.DACHighEdit = uicontrol(DACPanel, ...
    'Style', 'edit', ...
    'FontUnits', 'normalized', 'FontSize', 0.8, ...
    'String', VoltageRangeDefault(2), ...
    'Tooltip', 'Voltage output when ''on''', ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-7*EditSize(4), 0, 0], ...
    'HorizontalAlignment', 'center');
ControlHandles.AddDACButton = uicontrol(DACPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Add DAC signal', ...
    'Tooltip', 'Add a new DAC signal on the specified port', ...
    'Units', 'normalized', ...
    'Position', ButtonSize + [0, ButtonSize(4), 0, 0], ...
    'Callback', @addDACCallback);
ControlHandles.DeleteDACButton = uicontrol(DACPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Delete DAC signal', ...
    'Tooltip', 'Delete the DAC signal defined for the specified port', ...
    'Units', 'normalized', ...
    'Position', ButtonSize, ...
    'Callback', @deleteDACCallback);

% Add some controls to the control panel.
ButtonSize = [0, 0, 0.2, 1];
ControlHandles.SaveSignalsButton = uicontrol(ControlPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Save signals', ...
    'Tooltip', ...
    'Save these signals in the class property ''SignalStruct''', ...
    'Units', 'normalized', 'Position', ButtonSize, ...
    'Callback', @saveSignalCallback);
ControlHandles.ResetGUIButton = uicontrol(ControlPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Reset GUI', ...
    'Tooltip', 'Reset this GUI by deleting all user defined signals', ...
    'Units', 'normalized', ...
    'Position', ButtonSize + [ButtonSize(3), 0, 0, 0], ...
    'Callback', @resetGUICallback);

% Add axes to the PlotPanel.
PlotAxes = axes(PlotPanel);
PlotAxes.Toolbar.Visible = 'on';
hold(PlotAxes, 'on');

% If obj.SignalStruct is already populated, attempt to re-plot those 
% signals.  Otherwise, create and plot the default trigger signal.
% NOTE: SignalStruct(1) will always be the trigger signal.  The rest of the
%       signals are concatenated in the order the user added them.
% NOTE: I don't want to directly use obj.SignalStruct because the user
%       might not want to overwrite that structure yet.
DefaultSignalStruct.NPoints = [];
DefaultSignalStruct.InPhase = [];
DefaultSignalStruct.Period = [];
DefaultSignalStruct.Range = [];
DefaultSignalStruct.IsLogical = [];
DefaultSignalStruct.Handle = [];
DefaultSignalStruct.Identifier = [];
DefaultSignalStruct.Alias = [];
DefaultSignalStruct.Signal = [];
if isempty(obj.SignalStruct)
    SignalStruct = DefaultSignalStruct;
    createTriggerSignal()
else
    try
        SignalStruct = obj.SignalStruct;
        plotSignals()
    catch MException
        warning(['Signals present in obj.SignalStruct were invalid. ', ...
            'Errors reported: %s, %s'], ...
            MException.identifier, MException.message)
        SignalStruct = DefaultSignalStruct;
        createTriggerSignal();
    end        
end


    function createTriggerSignal(~, ~)
        % This function plots the trigger signal as defined in the trigger
        % signal panel. A handle to this trigger line is always kept in
        % LineHandles(1). The trigger itself will always be saved in 
        % NOTE: This will plot the trigger as a square with height 1. The
        %       alignment of several plot features will depend on this.
        % NOTE: The trigger will always start HIGH, and it will be assumed
        %       that this initial state of HIGH is caught as a triggering
        %       event when appropriate (i.e., for Rising edge and Change
        %       trigger modes).
        % NOTE: The trigger will always end LOW.
                
        % Generate the trigger, noting that the trigger will always
        % alternate with each time step (e.g., [1, 0, 1, 0, 1, ...]).
        NCycles = round(str2double(ControlHandles.NCyclesEdit.String));
        ControlHandles.NCyclesEdit.String = num2str(NCycles);
        NPoints = 2 * NCycles;
        XArray = transpose(1:NPoints);
        OnBool = logical(mod(XArray, 2));
        TriggerArray = zeros(1, NPoints);
        TriggerArray(OnBool) = 1;
        SignalStruct(1).NPoints = NPoints;
        SignalStruct(1).InPhase = 1;
        SignalStruct(1).Period = 1;
        SignalStruct(1).Range = [0; 1];
        SignalStruct(1).IsLogical = 1;
        SignalStruct(1).Handle = stairs(PlotAxes, ...
            XArray, TriggerArray-1, ...
            'Color', [0, 0, 0], 'LineWidth', 2);
        SignalStruct(1).Identifier = 'trigger';
        SignalStruct(1).Alias = ControlHandles.TriggerAliasEdit.String;
        SignalStruct(1).Signal = TriggerArray;
        
        % Re-generate the other signals and then plot them.
        regenerateAllSignals()
        plotSignals()
        
    end

    function triggerModeCallback(~, ~)
        % This is a callback for the trigger mode selection popup menu.
                
        % Regenerate and plot all of the signals to reflect the changes to
        % the triggering mode.
        regenerateAllSignals()
        plotSignals()

    end

    function ttlPopupCallback(Source, ~)
        % This is a callback for the TTL port selection popup menu.
        
        % Update the default Alias (the user couldn't have selected this
        % already here, so no harm in overwriting what's there).
        PortNumber = Source.Value;
        ControlHandles.TTLAliasEdit.String = ['TTL ', num2str(PortNumber)];
        
    end

    function dacPopupCallback(Source, ~)
        % This is a callback for the DAC port selection popup menu.
        
        % Update the default Alias (the user couldn't have selected this
        % already here, so no harm in overwriting what's there).
        PortNumber = Source.Value;
        ControlHandles.DACAliasEdit.String = ['DAC ', num2str(PortNumber)];
        
    end

    function addTTLCallback(~, ~)
        % This function plots a TTL signal defined by the user in the TTL
        % panel.
        
        % Make sure the user isn't overwriting a signal!
        CurrentIdentifier = sprintf('TTL%02i', ...
            ControlHandles.TTLPortPopup.Value);
        if any(strcmp({SignalStruct.Identifier}, CurrentIdentifier))
            errordlg(sprintf('A signal was already defined for %s.', ...
                CurrentIdentifier))
            return
        end
        
        % Generate the TTL signal using an toggle latch (this is a nice way
        % to do this since each trigger event can cause a state change,
        % which is exactly what a toggle latch does).
        NPoints = SignalStruct(1).NPoints;
        SignalPeriod = str2double(ControlHandles.TTLPeriodEdit.String);
        InPhase = ControlHandles.TTLPhaseCheckbox.Value;
        TriggerMode = ControlHandles.TriggerModePopup.Value;
        CurrentSignal.NPoints = NPoints;
        CurrentSignal.InPhase = InPhase;
        CurrentSignal.Period = SignalPeriod;
        CurrentSignal.Range = [0; 1];
        CurrentSignal.IsLogical = 1;
        CurrentSignal.Handle = [];
        CurrentSignal.Identifier = CurrentIdentifier;
        CurrentSignal.Alias = ControlHandles.TTLAliasEdit.String;
        ToggleSignal = obj.generateToggleSignal(...
            SignalStruct(1).Signal, SignalPeriod, TriggerMode);
        Signal = obj.toggleLatch(ToggleSignal, InPhase);
        CurrentSignal.Signal = Signal;
        SignalStruct = [SignalStruct; CurrentSignal];
        
        % Re-plot all of the signals.
        plotSignals()
        
    end

    function deleteTTLCallback(~, ~)
        % This function deletes a TTL signal specified by the user in the
        % TTL panel.  The signal is only deleted from 'SignalStruct' within
        % this .m file.  The signal will not be removed from
        % obj.SignalStruct until the user saves the signals with the save
        % signals button.
        
        % Look for the specified signal and delete it if it exists.
        CurrentIdentifier = sprintf('TTL%02i', ...
            ControlHandles.TTLPortPopup.Value);
        DeleteBool = strcmp({SignalStruct.Identifier}, CurrentIdentifier);
        SignalStruct = SignalStruct(~DeleteBool);
        
        % Re-plot all of the signals.
        plotSignals()
        
    end

    function addDACCallback(~, ~)
        % This function plots a DAC signal defined by the user in the DAC
        % panel.
        % NOTE: The signal generated here will be rescaled when plotted so
        %       to improve plot appearance.  The rescaling will not affect
        %       the output signal.
        % NOTE: The signal is always driven to the LOW voltage at the end
        %       of the signal.
        
        % Make sure the user isn't overwriting a signal!
        CurrentIdentifier = sprintf('DAC%02i', ...
            ControlHandles.DACPortPopup.Value);
        if any(strcmp({SignalStruct.Identifier}, CurrentIdentifier))
            errordlg(sprintf('A signal was already defined for %s.', ...
                CurrentIdentifier))
            return
        end
        
        % Generate the DAC signal using an toggle latch (this is a nice way
        % to do this since each trigger event can cause a state change,
        % which is exactly what a toggle latch does).
        NPoints = SignalStruct(1).NPoints;
        SignalPeriod = str2double(ControlHandles.DACPeriodEdit.String);
        InPhase = ControlHandles.DACPhaseCheckbox.Value;
        TriggerMode = ControlHandles.TriggerModePopup.Value;
        LOWVoltage = str2double(ControlHandles.DACLowEdit.String);
        HIGHVoltage = str2double(ControlHandles.DACHighEdit.String);
        CurrentSignal.NPoints = NPoints;
        CurrentSignal.InPhase = InPhase;
        CurrentSignal.Period = SignalPeriod;
        CurrentSignal.Range = [LOWVoltage; HIGHVoltage];
        CurrentSignal.IsLogical = 0;
        CurrentSignal.Handle = [];
        CurrentSignal.Identifier = CurrentIdentifier;
        CurrentSignal.Alias = ControlHandles.DACAliasEdit.String;
        [ToggleSignal] = obj.generateToggleSignal(...
            SignalStruct(1).Signal, SignalPeriod, TriggerMode);
        Signal = obj.toggleLatch(ToggleSignal, InPhase);
        CurrentSignal.Signal = Signal*(HIGHVoltage-LOWVoltage) ...
            + LOWVoltage;
        SignalStruct = [SignalStruct; CurrentSignal];
        
        % Re-plot all of the signals.
        plotSignals()

    end

    function deleteDACCallback(~, ~)
        % This function deletes a DAC signal specified by the user in the
        % DAC panel.  The signal is only deleted from 'SignalStruct' within
        % this .m file.  The signal will not be removed from
        % obj.SignalStruct until the user saves the signals with the save
        % signals button.
        
        % Look for the specified signal and delete it if it exists.
        CurrentIdentifier = sprintf('DAC%02i', ...
            ControlHandles.DACPortPopup.Value);
        DeleteBool = strcmp({SignalStruct.Identifier}, CurrentIdentifier);
        SignalStruct = SignalStruct(~DeleteBool);
        
        % Re-plot all of the signals.
        plotSignals()
        
    end

    function saveSignalCallback(~, ~)
        % This callback updates the class property 'SignalArray' with the
        % signals defined in this GUI.
        
        obj.SignalStruct = SignalStruct;
        obj.TriggerMode = ControlHandles.TriggerModePopup.String{...
            ControlHandles.TriggerModePopup.Value};
        fprintf('Signals saved in obj.SignalStruct\n')
        
    end

    function resetGUICallback(~, ~)
        % This callback will delete all of the user defined signals, thus
        % resetting the GUI to it's default state.
        
        % Make sure the user wants to proceed.
        [UserResponse] = questdlg(...
            ['Resetting the GUI will remove all of your signals. ', ...
            'Would you like to proceed?'], ...
            'Reset request', 'Yes', 'No', 'No');
        if strcmp(UserResponse, 'No')
            return
        end
        
        % Create a new default trigger signal (which internally clears the
        % GUI).
        % NOTE: createTriggerSignal() can only use parameters stored in the
        %       trigger related uicontrols.  This is not a great way to do
        %       this, but for various reasons I'm keeping that behavior
        %       (forcing me to change some uicontrols here).
        SignalStruct = DefaultSignalStruct;
        ControlHandles.TriggerAliasEdit.String = ...
            DefaultTriggerParams.Alias;
        ControlHandles.NCyclesEdit.String = ...
            DefaultTriggerParams.NCycles;
        ControlHandles.TriggerModePopup.Value = ...
            DefaultTriggerParams.TriggerModeIndex;
        createTriggerSignal()
        
    end

    function regenerateAllSignals()
        % This function will re-generate all of the signals defined so far.
        % The intention of this method is that the user may wish to change
        % the number of sequences in the trigger, which will require us to
        % extend the rest of the signals already defined.
        
        % Loop through all of the existing signals and recompute them to
        % match the size of the triggering signal (SignalStruct(1).Signal).
        NSignals = numel(SignalStruct);
        NPointsTrigger = SignalStruct(1).NPoints;
        for ii = 2:NSignals
            SignalStruct(ii).Signal = regenerateSignal(ii);
            SignalStruct(ii).NPoints = NPointsTrigger;
        end

    end

    function [OutputSignal] = regenerateSignal(SignalIndex)
        % This function regenerates the signal SignalStruct(SignalIndex)
        % such that it's length matches the trigger signal.
        % NOTE: This function will always drive the signal LOW for the last
        %       point, i.e., OutputSignal(end) = 0 for all signals.
        
        TriggerMode = ControlHandles.TriggerModePopup.Value;
        ToggleSignal = obj.generateToggleSignal(...
            SignalStruct(1).Signal, ...
            SignalStruct(SignalIndex).Period, ...
            TriggerMode);
        Signal = obj.toggleLatch(ToggleSignal, ...
            SignalStruct(SignalIndex).InPhase);
        Range = SignalStruct(SignalIndex).Range;
        OutputSignal = Signal*diff(Range) + Range(1);
        
    end

    function plotSignals()
        % This function will plot all of the signals in the SignalStruct.
        % NOTE: The digital signals (trigger and TTL) will always be
        %       plotted with the same "height".  The DAC signals will be
        %       rescaled with respect to the DAC signal with the largest
        %       swing.  For example, if we have two DAC signals, 
        %       DAC1 = [0, 5, 0, 5, 0] and DAC2 = [0, 2.5, 0, 2.5, 0], DAC1
        %       would appear the same size as the trigger signal, but DAC2
        %       would appear to half of the swing as either DAC1 or the
        %       trigger.
        
        % Clear the plot axes to make sure we don't keep anything by
        % mistake.
        cla(PlotAxes);
        
        % Plot the trigger signal (this is the only signal that will always
        % be in the same spot with the same color). 
        % NOTE: For the plots, I'm padding the end of the signals with
        %       their last value for the sake of improving the plot 
        %       appearance.
        NPoints = SignalStruct(1).NPoints;
        XArray = 1:(NPoints+1);
        PaddedSignal = [SignalStruct(1).Signal, ...
            SignalStruct(1).Signal(NPoints)];
        ShiftedSignal = PaddedSignal - 0.5;
        SignalStruct(1).Handle = stairs(PlotAxes, ...
            XArray, ShiftedSignal, ...
            'Color', [0, 0, 0], 'LineWidth', 2);
        
        % Plot the rest of the signals, rescaling them to improve the plot 
        % appearance (the rescaled signals won't be saved).
        NSignals = numel(SignalStruct);
        SignalYZero = (0:(NSignals-1)) * 1.5;
        for ii = 2:NSignals
            Signal = SignalStruct(ii).Signal;
            PaddedSignal = [Signal, Signal(NPoints)];
            if SignalStruct(ii).IsLogical
                RescaledSignal = PaddedSignal;
            else
                % Compute some scaling parameters that we'll need.  These
                % are defined to ensure that the appearance of all DAC
                % signals are consistent, e.g., a signal from -5 to 5
                % should look twice as tall as a signal from 0 to 5.
                ConcatenatedSignal = cell2mat({SignalStruct.Signal});
                MinVoltage = min(ConcatenatedSignal);
                MaxVoltage = max(ConcatenatedSignal);
                MaxSignalSwing = max(cellfun(@(X) max(X) - min(X), ...
                    {SignalStruct.Signal}));
                MaxGlobalSwing = MaxVoltage - MinVoltage;
                SignalCenterScaled = abs(min(PaddedSignal)-MinVoltage) ...
                    / MaxGlobalSwing;
                
                % Rescale the signal.
                RescaledSignal = SignalCenterScaled ...
                    + ((PaddedSignal-min(PaddedSignal)) / MaxSignalSwing);
            end
            ShiftedSignal = RescaledSignal + SignalYZero(ii) - 0.5;           
            SignalStruct(ii).Handle = stairs(PlotAxes, ...
                XArray, ShiftedSignal, ...
                'LineWidth', 2);
        end
                        
        % Add some vertical lines to indicate each trigger event.
        EventLocationsX = find(obj.generateToggleSignal(...
            SignalStruct(1).Signal, ...
            1, ControlHandles.TriggerModePopup.Value));
        NEvents = numel(EventLocationsX);
        YExtent = [-1, 1.5*NSignals - 0.5];
        for ii = 1:NEvents
            line(PlotAxes, ...
                ones(2, 1)*EventLocationsX(ii), YExtent, ...
                'Color', [0, 0, 0, 0.2], ...
                'LineStyle', ':')
        end
        
        % Add some horizontal lines at y=-1, 0, 1 for each signal.
        XExtent = [min(XArray), max(XArray)];
        for ii = 1:NSignals
            YZero = SignalYZero(ii);
            line(PlotAxes, XExtent, ones(2, 1)*YZero, ...
                'Color', [0, 0, 0, 0.2], 'LineStyle', '-')
            line(PlotAxes, XExtent, ones(2, 1)*YZero + 0.5, ...
                'Color', [0, 0, 0, 0.2], 'LineStyle', ':')
            line(PlotAxes, XExtent, ones(2, 1)*YZero - 0.5, ...
                'Color', [0, 0, 0, 0.2], 'LineStyle', ':')
        end
        
        % Add a bunch of invisible rectangles which the user can click to
        % edit each point of a signal.
        % NOTE: We don't want the trigger to be edited in this way, thus
        %       the index of the second for loop starts at 2.
        if (NEvents > 1)
            NPointsBetweenEvents = ...
                EventLocationsX(2) - EventLocationsX(1) - 1;
        else
            NPointsBetweenEvents = 1;
        end
        for ii = 1:NEvents
            for jj = 2:NSignals
                rectangle(PlotAxes, ...
                    'Position', ...
                    [EventLocationsX(ii), SignalYZero(jj)-0.5, ...
                    (NPointsBetweenEvents+1), 1], ...
                    'EdgeColor', 'none', ...
                    'PickableParts', 'all', ...
                    'ButtonDownFcn', ...
                    {@clickedRectangle, ...
                    EventLocationsX(ii), jj, NPointsBetweenEvents});
            end
        end
        
        % Modify some properties of the axis to improve appearance.
        axis(PlotAxes, 'tight')
        PlotAxes.XLim = XExtent;
        PlotAxes.XTick = EventLocationsX;
        PlotAxes.XTickLabels = num2str(transpose(1:NEvents));
        PlotAxes.YLim = YExtent;
        PlotAxes.YTick = SignalYZero;
        PlotAxes.YTickLabels = {SignalStruct.Alias};
    end

    function clickedRectangle(Source, ~, ...
            XIndex, YIndex, NPointsBetweenEvents)
        % This is a callback for when the user clicks one of the invisible
        % rectangles on the plot axes (to edit the signal value in that
        % box).
        
        % Change the face color to indicate the rectangle was clicked.
        if strcmp(Source.FaceColor, 'none')
            Source.FaceColor = [0, 0, 0, 0.1];
        else
            Source.FaceColor = 'none';
            return
        end
        
        % If the signal is a TTL signal, toggle the signal in the clickable
        % rectangle region.  For DAC signals, we'll want to get some user
        % input for the new voltage level.
        XIndices = XIndex:(XIndex+NPointsBetweenEvents);
        if SignalStruct(YIndex).IsLogical
            SignalStruct(YIndex).Signal(XIndices) = ...
                ~SignalStruct(YIndex).Signal(XIndices);
        else
            % Request for a user input voltage level with a dialog box.
            UserInputVoltage = inputdlg('Enter the desired voltage:');
            if isempty(UserInputVoltage)
                Source.FaceColor = 'none';
                return
            end
            NewVoltage = str2double(UserInputVoltage{1});
            Range = SignalStruct(YIndex).Range;
            SignalStruct(YIndex).Signal(XIndices) = NewVoltage;
            SignalStruct(YIndex).Range = [min(Range(1), NewVoltage); ...
                max(Range(2), NewVoltage)];
        end
        
        % Re-plot the signals to reflect the updates.
        plotSignals()
        
    end

    function figureClosing(~, ~)
        % This callback is executed with the GUI figure is being closed.
        
        % Check if the user would like to save their changes before
        % closing.
        [UserResponse] = questdlg(...
            'Would you like to save these signals in obj.SignalStruct?',...
            'Close request', 'Yes', 'No', 'Yes');
        if strcmp(UserResponse, 'Yes')
            saveSignalCallback();
        end
        if ~isempty(UserResponse)
            delete(GUIParent)
        end
        
    end


end