function triggerArrayGUI(obj, GUIParent)
%createTriggeringArray opens a GUI that can create a triggering array.
% This method will open a GUI which allows the user to define a
% 'TriggeringArray', i.e., an array defining a simple DAC/TTL program based
% on a trigger signal.
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

% Generate some panels to help organize the GUI.
TriggerPanel = uipanel(GUIParent, 'Title', 'Trigger', ...
    'Units', 'normalized', 'Position', [0, 0.67, 0.2, 0.33]);
TTLPanel = uipanel(GUIParent, 'Title', 'TTL', ...
    'Units', 'normalized', 'Position', [0, 0.33, 0.2, 0.33]);
DACPanel = uipanel(GUIParent, 'Title', 'DAC', ...
    'Units', 'normalized', 'Position', [0, 0, 0.2, 0.33]);
PlotPanel = uipanel(GUIParent, ...
    'Units', 'normalized', 'Position', [0.2, 0, 0.8, 1]);

% Add some controls to the TriggerPanel.
TextSize = [0, 0, 0.7, 0.1];
EditSize = [0, 0, 0.3, 0.1];
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
    'String', 'Trigger', ...
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
    'String', '2', ...
    'Tooltip', NCyclesTooltip, ...
    'Units', 'normalized', ...
    'Position', EditSize + [TextSize(3), 1-2*TextSize(4), 0, 0], ...
    'HorizontalAlignment', 'center', ...
    'Callback', @plotTriggerSignal);

% Add some controls to the TTLPanel.
TextSize = [0, 0, 0.5, 0.1];
EditSize = [0, 0, 0.5, 0.1];
PopupSize = [0, 0, 0.5, 0.1];
ButtonSize = [0, 0, 1, 0.2];
CheckSize = [0, 0, 0.25, 0.11];
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
    'Position', PopupSize + [TextSize(3), 1-TextSize(4), 0, 0]);
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
    'with every trigger event, while a period of 4 means that the TTL\n', ...
    'changes state with every other trigger event']);
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
    ['The TTL phase specifies whether the signal is in phase with\n', ...
    'the trigger (trigger goes HIGH -> TTL goes HIGH), or out of\n', ...
    'phase (trigger goes HIGH -> TTL goes LOW).']);
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
    'String', 'Add TTL', ...
    'Tooltip', 'Add a new TTL signal on the specified port', ...
    'Units', 'normalized', 'Position', ButtonSize, ...
    'Callback', @plotTTLSignal);

% Add some controls to the DACPanel.
TextSize = [0, 0, 0.5, 0.1];
EditSize = [0, 0, 0.5, 0.1];
PopupSize = [0, 0, 0.5, 0.1];
ButtonSize = [0, 0, 1, 0.2];
CheckSize = [0, 0, 0.2, 0.11];
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
    'Position', PopupSize + [TextSize(3), 1-TextSize(4), 0, 0]);
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
    'with every trigger event, while a period of 4 means that the DAC\n', ...
    'changes state with every other trigger event']);
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
    ['The DAC phase specifies whether the signal is in phase with\n', ...
    'the trigger (trigger goes HIGH -> DAC goes HIGH), or out of\n', ...
    'phase (trigger goes HIGH -> DAC goes LOW).']);
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
ControlHandles.AddDACButton = uicontrol(DACPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Add DAC', ...
    'Tooltip', 'Add a new DAC signal on the specified port', ...
    'Units', 'normalized', 'Position', ButtonSize);
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

% Add axes to the PlotPanel.
PlotAxes = axes(PlotPanel);
hold(PlotAxes, 'on');

% Define a few variables that will be shared with sub-functions.
% NOTE: I'm placing the alias for the trigger here immediately.  The rest
%       of the aliases will be added each time a new signal is added.
LineHandles = gobjects(2*obj.IOChannels + 1, 1);
SignalAliases = {ControlHandles.TriggerAliasEdit.String};

% Plot the default trigger signal.
plotTriggerSignal()

    function plotTriggerSignal(~, ~)
        % This function plots the trigger signal as defined in the trigger
        % signal panel. A handle to this trigger line is always kept in
        % LineHandles(1).
        % NOTE: This will plot the trigger as a square with height 1. The
        %       alignment of several plot features will depend on this.
        
        % Remove any previous trigger.
        if isvalid(LineHandles(1))
            delete(LineHandles(1))
        end
        
        % Plot the trigger.
        NCycles = str2double(ControlHandles.NCyclesEdit.String);
        NPoints = 2*NCycles + 1;
        XArray = transpose(1:NPoints);
        OffBool = ~mod(XArray, 2);
        TriggerArray = ones(NPoints, 1);
        TriggerArray(OffBool) = 0;
        LineHandles(1) = stairs(PlotAxes, XArray, TriggerArray-1, ...
            'Color', [0, 0, 0], 'LineWidth', 2);
        
        % Modify some properties of the axis to improve appearance.
        NSignalsVisible = sum(cell2mat({LineHandles.isvalid}));
        PlotAxes.XTick = XArray(~OffBool);
        PlotAxes.XTickLabels = num2str(transpose(1:numel(PlotAxes.XTick)));
        PlotAxes.YLim = [-(NSignalsVisible+0.5), 0.5];
        PlotAxes.YTick = (0:NSignalsVisible-1) - 0.5;
        PlotAxes.YTickLabels = SignalAliases;
    end

    function plotTTLSignal(~, ~)
        % This function plots a TTL signal defined by the user in the TTL
        % panel. The line handle will be saved in the LineHandles array,
        % with the index being 1 + port number.
        % NOTE: This will plot the signal with the y values normalized to
        %       [0, 1]. The alignment of several plots will rely on this
        %       being true.
        
        % Generate the TTL signal using an toggle latch (this is a nice way
        % to do this since each trigger event can cause a state change,
        % which is exactly what a toggle latchh does).
        NCycles = str2double(ControlHandles.NCyclesEdit.String);
        SignalPeriod = str2double(ControlHandles.TTLPeriodEdit.String);
        NPoints = 2*NCycles + 1;
        TTLSignal = zeros(NPoints, 1);
        TTLSignal(1) = ControlHandles.TTLPhaseCheckbox.Value;
        for ii = 2:NPoints
            % Toggle the signal when appropriate.
            EventNumber = floor(ii / 2);
            IsEvent = mod(ii, 2);
            ToggleSignal = (IsEvent && ~mod(EventNumber, SignalPeriod));
            TTLSignal(ii) = ToggleSignal*~TTLSignal(ii-1) ...
                + ~ToggleSignal*TTLSignal(ii-1);
        end
        
        % Plot the TTL signal over the same x range as the trigger.
        NSignalsVisible = sum(cell2mat({LineHandles.isvalid}));
        TTLSignal = TTLSignal - NSignalsVisible - 1.5;
        LineHandles = [LineHandles; ...
            stairs(PlotAxes, transpose(1:NPoints), TTLSignal, ...
            'LineWidth', 2)];
        NSignalsVisible = NSignalsVisible + 1;
        
        % Modify some properties of the axis to improve appearance.
        PlotAxes.YLim = [-(NSignalsVisible+0.5), 0.5];
        PlotAxes.YTick = (0:NSignalsVisible-1) - 0.5;
        PlotAxes.YTickLabels = SignalAliases;
    end



end