function guiFig = gui(obj)
%Graphical user interface for MIC_CavroSyringePump.

%{
Specify general GUI behaviors. 
%}

% Prevent opening more than one figure for same instrument.
if ishandle(obj.GuiFigure)
    guiFig = obj.GuiFigure;
    figure(obj.GuiFigure);
    return
end

% Create a figure for the GUI.
ScreenSize = get(groot, 'ScreenSize'); % screen size
FigWidth = 600; 
FigHeight = 400; 
BottomLeftX = floor(ScreenSize(3)/2 - FigWidth/2); % ~centers the figure
BottomLeftY = floor(ScreenSize(4)/2 - FigHeight/2); % ~centers the figure
guiFig = figure('Position', ...
    [BottomLeftX, BottomLeftY, FigWidth, FigHeight], ...
    'MenuBar', 'none', 'ToolBar', 'none'); % figure handle
obj.GuiFigure = guiFig;
obj.GuiFigure.Name = obj.InstrumentName;

% Prevent closing after a 'close' or 'close all' command.
obj.GuiFigure.HandleVisibility = 'off';

% Pass control to closeFigure callback when closing the figure.
obj.GuiFigure.CloseRequestFcn = @closeFigure;

%{ 
Create the GUI controls.
%}

% Create a textbox (as well as a refresh button) to display the status of 
% the syringe pump.
StatusText = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [0, 0, FigWidth-50, 25], 'Tag', 'StatusText', ...
    'Enable', 'off');
RefreshStatus = uicontrol('Parent', guiFig, 'Style', 'pushbutton', ...
    'Position', [FigWidth-50, 0, 50, 25], 'String', 'Refresh', ...
    'Callback', @refreshStatus);

% Create syringe pump connection controls/options.
PortList = uicontrol('Parent', guiFig, 'Style', 'popupmenu', ...
    'Position', [0, 325, 150, 50], 'Callback', @portListCallback);
ConnectButton = uicontrol('Parent', guiFig, 'Style', 'pushbutton', ...
    'Position', [0, 300, 150, 50], 'String', 'Connect Syringe Pump', ...
    'Tag', 'ConnectButton', 'Callback', @connectSyringePump);
InitializeButton = uicontrol('Parent', guiFig, 'Style', 'pushbutton', ...
    'Position', [0, 275, 150, 25], ...
    'String', 'Re-initialize Syringe Pump', ...
    'Tag', 'InitializePump', ...
    'Callback', @initializeSyringePump);

% Create plunger velocity controls.
PlungerParamsTitle = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-160, 375, 150, 25], ...
    'String', 'Plunger Velocity Parameters');
VelocitySlope = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [FigWidth-50, 350, 50, 25], ...
    'TooltipString', 'Select integer in the range [1, 20]', ...
    'Callback', @setVelocitySlope);
VSLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-160, 350, 110, 20], ...
    'String', 'Velocity Slope (Hz/s)', ...
    'TooltipString', 'Select integer in the range [1, 20]', ...
    'HorizontalAlignment', 'left'); 
StartVelocity = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [FigWidth-50, 325, 50, 25], ...
    'TooltipString', 'Select integer in the range [50, 1000]', ...
    'Callback', @setStartVelocity); 
SVLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-160, 325, 100, 20], ...
    'String', 'Start Velocity (Hz)', ...
    'TooltipString', 'Select integer in the range [50, 1000]', ...
    'HorizontalAlignment', 'left'); 
TopVelocity = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [FigWidth-50, 300, 50, 25], ...
    'TooltipString', 'Select integer in the range [5, 5800]', ...
    'Callback', @setTopVelocity); 
TVLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-160, 300, 100, 20], ...
    'String', 'Top Velocity (Hz)', ...
    'TooltipString', 'Select integer in the range [5, 5800]', ...
    'HorizontalAlignment', 'left'); 
CutoffVelocity = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [FigWidth-50, 275, 50, 25], ...
    'TooltipString', 'Select integer in the range [50, 2700]', ...
    'Callback', @setCutoffVelocity); 
CVLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-160, 275, 100, 20], ...
    'TooltipString', 'Select integer in the range [50, 2700]', ...
    'String', 'Cutoff Velocity (Hz)', 'HorizontalAlignment', 'left');

% Create plunger position controls.
PlungerPositionTitle = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-150, 225, 150, 25], ...
    'String', 'Plunger Position Controls'); 
CurrentPositionDisplay = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-50, 200, 50, 25]); 
CurrentPositionLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-175, 200, 125, 25], ...
    'String', 'Current Plunger Position:', 'HorizontalAlignment', 'left');
NewPositionAbsolute = uicontrol('Parent', guiFig, 'Style', 'edit', ...
    'Position', [FigWidth-50, 175, 50, 25], ...
    'TooltipString', 'Select integer in the range [0, 3000]');
NewPositionAbsoluteLabel = uicontrol('Parent', guiFig, 'Style', 'text', ...
    'Position', [FigWidth-175, 175, 125, 20], ...
    'String', 'New Plunger Position:', 'HorizontalAlignment', 'left', ...
    'TooltipString', 'Select integer in the range [0, 3000]');
MovePlungerButton = uicontrol('Parent', guiFig, 'Style', 'pushbutton', ...
    'Position', [FigWidth-175, 150, 175, 25], ...
    'String', 'Move Plunger to New Position', ...
    'Tag', 'MovePlunger', ...
    'Callback', @movePlungerAbsolute);
TerminateMoveButton = uicontrol('Parent', guiFig, 'Style', 'pushbutton', ...
    'Position', [FigWidth-175, 125, 175, 25], ...
    'String', 'Terminate Plunger Move', ...
    'Callback', @terminatePlungerMove); 

%{
Initialize the GUI based on object properties. 
%}
properties2gui();

%{ 
Define the callback functions for the GUI controls.
%}
    function closeFigure(~,~)
        gui2properties(); % update object properties based on GUI
        delete(obj.GuiFigure); % delete the GUI figure
    end

    function gui2properties()
        % Sets the object properties based on the GUI widgets.
        
        % Set the properties related to the plunger velocity.
        obj.VelocitySlope = str2double(VelocitySlope.String); 
        obj.StartVelocity = str2double(StartVelocity.String);
        obj.TopVelocity = str2double(TopVelocity.String); 
        obj.CutoffVelocity = str2double(CutoffVelocity.String); 
        
        % Set the properties related to the plungers position.
        obj.PlungerPosition = str2double(NewPositionAbsolute.String); 
    end

    function properties2gui()
        % Set the GUI widgets based on the object properties.
        
        % Set the message text to the most recently known state of the
        % syringe pump.
        StatusText.String = obj.ReadableStatus;

        % Provide a list of available COM ports if MATLAB version will
        % allow for it.
        if str2double(obj.MatlabRelease(1:4)) >= 2017
            % The version of MATLAB in use has the seriallist function,
            % place each serial port available in the PortList menu,
            % ensuring that obj.SerialPort is the first option shown.
            ListItems = unique([obj.SerialPort, seriallist], 'stable');
            PortList.String = cellstr(ListItems); % convert to cell array
        else
            % The version of MATLAB in use does not have the seriallist
            % function, display the default port just for consistency.
            PortList.String = obj.SerialPort; 
        end
        
        % Display the plunger velocity settings of the syringe pump.
        VelocitySlope.String = obj.VelocitySlope; 
        StartVelocity.String = obj.StartVelocity; 
        TopVelocity.String = obj.TopVelocity; 
        CutoffVelocity.String = obj.CutoffVelocity; 
        
        % Display the most recently known absolute plunger position.
        CurrentPositionDisplay.String = obj.PlungerPosition; 
        NewPositionAbsolute.String = obj.PlungerPosition; 
    end

    function portListCallback(Source, ~)
        % Callback for the Port selection popup (dropdown) menu.
        
        % Set the serial port property based on the selection made in the
        % popup menu.
        ListItems = Source.String; % list of options given in popup menu
        
        % Set obj.SerialPort to the user selection.
        obj.SerialPort = ListItems{Source.Value};
    end

    function refreshStatus(~, ~)
        % Callback for the refresh status (query) button.
        
        % Query the syringe pump and update the GUI based on response.
        obj.querySyringePump(); 
        
        % Update GUI properties to reflect any changes to the syringe pump.
        properties2gui();
    end
    
    function connectSyringePump(~, ~)
        % Callback for the Connect Syringe Pump button.

        % Attempt to make a connection to the syringe pump.
        obj.connectSyringePump();

        % Update GUI properties to reflect any changes to the syringe pump.
        properties2gui();
    end

    function initializeSyringePump(~, ~)
        % Callback for the Re-initialize Syringe Pump button.

        % Attempt to re-initialize the syringe pump directly (without using
        % obj.executeCommand() method).
        fprintf(obj.SyringePump, ['/', num2str(obj.DeviceAddress), 'ZR']);

        % Set default properties based on the (assumed) succesful initialization.
        obj.StartVelocity = 900; 
        obj.TopVelocity = 1400; 
        obj.CutoffVelocity = 900;
        obj.VelocitySlope = 14; 
        obj.PlungerPosition = 0;
        
        % Update GUI properties to reflect any changes to the syringe pump.
        properties2gui();
    end
    
    function setVelocitySlope(Source, ~)
        % Callback used to set the VelocitySlope property of the syringe
        % pump.
        
        % Retrieve the value entered by the user and ensure it is valid.
        ProposedSlope = str2double(Source.String);
        if (ProposedSlope >= 1) && (ProposedSlope <= 20)
            % Set syringe pump to new velocity slope.
            obj.executeCommand(['L', num2str(ProposedSlope)]);
        else
            error('Velocity slope %g Hz out of range (1-20 Hz/sec)', ...
                ProposedSlope); 
        end
        
        % Update class properties to reflect changes (must be done first).
        gui2properties();
        
        % Update GUI properties to refelct changes. 
        properties2gui();
    end

    function setStartVelocity(Source, ~)
        % Callback used to set the start velocity property of the syringe
        % pump.
        
        % Retrieve the value entered by the user and ensure it is valid. 
        ProposedStartVelocity = str2double(Source.String);
        if (ProposedStartVelocity <= 1000) && (ProposedStartVelocity >= 50)
            % User entered start velocity is in the valid range, ensure
            % that it is less than the top velocity.
            if ProposedStartVelocity < obj.TopVelocity
                % Set syringe pump to new start velocity.
                obj.executeCommand(['v', num2str(ProposedStartVelocity)]);
            else
                error('Start velocity must be less than top velocity.')
            end
        else
            error('Start velocity %g Hz out of range (50-1000 Hz)', ...
                ProposedStartVelocity)
        end
        
        % Update class properties to reflect changes (must be done first).
        gui2properties();
        
        % Update GUI properties to refelct changes. 
        properties2gui();
    end

    function setTopVelocity(Source, ~)
        % Callback used to set the top velocity property of the syringe
        % pump.
        
        % Retrieve the value entered by the user. 
        ProposedTopVelocity = str2double(Source.String);
        if (ProposedTopVelocity <= 5800) && (ProposedTopVelocity >= 5)
            % User entered top velocity is in the valid range, ensure it is
            % greater than the start velocity.
            if ProposedTopVelocity > obj.StartVelocity
                % Set syringe pump to new top velocity.
                obj.executeCommand(['V', num2str(ProposedTopVelocity)]);
            else
                error('Top velocity must be greater than start velocity')
            end
        else
            error('Top velocity %g Hz out of range (5-5800 Hz)', ...
                ProposedTopVelocity)
        end 
        
        % Update class properties to reflect changes (must be done first).
        gui2properties();
        
        % Update GUI properties to refelct changes. 
        properties2gui(); 
    end

    function setCutoffVelocity(Source, ~)
        % Callback used to set the cutoff velocity property of the syringe
        % pump.
        
        % Retrieve the value entered by the user. 
        ProposedCutoffVelocity = str2double(Source.String);
        if (ProposedCutoffVelocity <= 2700) ...
                && (ProposedCutoffVelocity >= 50)
            % Set syringe pump to new cutoff velocity.
            obj.executeCommand(['c', num2str(ProposedCutoffVelocity)]);
        else
            error('Cutoff velocity %g Hz out of range (50-2700 Hz)', ...
                ProposedCutoffVelocity)
        end
        
        % Update class properties to reflect changes (must be done first).
        gui2properties();
        
        % Update GUI properties to refelct changes. 
        properties2gui();
    end

    function movePlungerAbsolute(~, ~)
        % Callback for the Move Plunger to New Position pushbutton.
        
        % Ensure that the syringe pump is ready for commands.
        obj.waitForReadyStatus()
        
        % Ensure a valid position was entered, attempt to move the syringe.
        ProposedPosition = str2double(NewPositionAbsolute.String); 
        if (ProposedPosition <= 3000) && (ProposedPosition >= 0)
            % A valid plunger position has been entered. 
            obj.executeCommand(['A', num2str(ProposedPosition)]);
            obj.waitForReadyStatus() 
        else
            error('Plunger position %g out of range (0-3000)', ...
                ProposedPosition)
        end
        
        % Attempt to query the syringe pump to report the plunger position
        % (instead of trusting that it went to the correct place). 
        ReportedPosition = obj.reportCommand('?'); % absolute position char
        obj.PlungerPosition = str2double(ReportedPosition);
        
        % Update GUI to reflect any changes. 
        properties2gui();
    end

    function terminatePlungerMove(~, ~)
        % Callback for the Terminate Plunger Move pushbutton.
        
        % Attempt to terminate the plunger move directly (without using
        % obj.executeCommand() method).
        fprintf(obj.SyringePump, ['/', num2str(obj.DeviceAddress), 'TR']);
        obj.waitForReadyStatus();
        
        % Attempt to query the syringe pump to report the plunger position. 
        ReportedPosition = obj.reportCommand('?'); % absolute position char
        obj.PlungerPosition = str2double(ReportedPosition);
        
        % Update GUI to reflect any changes.
        properties2gui();
    end

    
end