classdef MIC_Triggerscope < MIC_Abstract
    %MIC_Triggerscope contains methods to control a Triggerscope.
    % This class is designed for the control of a Triggerscope (written for
    % Triggerscope 3B and 4). All functionality present in the Triggerscope
    % documentation should be included (see documents in
    % Z:\Manuals\AdvancedResearch).
    %
    % REQUIRES:
    %   Triggerscope 3B, Triggerscope 4 (https://arc.austinblanco.com/)
    %       connected via an accessible serial port
    %   MATLAB 2019b or later (for updated serial communications, e.g.,
    %       serialport())
    %   Windows operating system recommended (Unix based systems might 
    %       require changes to, e.g., usage/definition of obj.SerialPort,
    %       or perhaps more serious changes)
    
    % Created by:
    %   David J. Schodt (Lidke Lab, 2020)
    
    
    properties
        DeviceTimeout = 10; % (seconds) Triggerscope response timeout
        SerialPort = 'COM3'; % COM port of connected Triggerscope
    end
    
    properties (SetObservable)
        ActivityMessage = ''; % message describing current action
    end
    
    properties (SetAccess = protected)
        GUIParent; % graphics object parent of the GUI
        InstrumentName = 'Triggerscope'; % name of the instrument
        Triggerscope; % serial object for the connected Triggerscope
        
        % The following should be specified in the Triggerscope
        % documentation. The Terminator was assumed to be 'LF' but that is
        % unclear. These properties are not expected to change, and if they
        % are changed, we will probably want them to be changed 
        % permanently (i.e., hard coded here).
        BaudRate = 115200; % Baud rate for the Triggerscope
        DataBits = 8; % Number of bits per character
        Terminator = 'LF'; % Command terminator (or End Of Linede, EOL)
        
        % List of commands present in the Triggerscope documentation.
        CommandList = {'*', 'DAC', 'FOCUS', 'TTL', 'RANGE', 'CAM', ...
            'STAT?', 'TEST?', 'CLEARTABLE', 'PROG', 'STEP', 'ARM', ...
            'ARRAY', 'CLEARALL', 'RANGE', ...
            'PROG_FOCUS', 'PROG_TTL', 'PROG_DAC', 'PROG_DEL', ...
            'TIMECYCLES', 'TRIGMODE'};
    end
    
    properties (Hidden)
        StartGUI = false; % specifies whether GUI starts on instantiation
    end
    
    methods
        function obj = MIC_Triggerscope(SerialPort, DeviceTimeout)
            %MIC_Triggerscope is the class constructor.
                       
            % If needed, automatically assign a name to the instance of
            % this class (i.e. if user forgets to do this).
            obj = obj@MIC_Abstract(~nargout);
            
            % Set inputs to class properties if needed.
            if (exist('SerialPort', 'var') && ~isempty(SerialPort))
                obj.SerialPort = SerialPort;
            end
            if (exist('DeviceTimeout', 'var') && ~isempty(DeviceTimeout))
                obj.DeviceTimeout = DeviceTimeout;
            end
        
        end
        
        % Serial communication methods.
        [Response] = executeCommand(obj, Command);
        
        % General instrument methods.
        delete(obj)
        exportState(obj)
        [GUIParent] = gui(obj, GUIParent);
        unitTest(obj)
        
    end
    
    methods (Access = protected)
        % These methods are protected because it is not anticipated that a
        % user would want to access these. Any methods in this section
        % should have public calling methods that make them more 
        % user-friendly while providing the same functionality.
        
        writeCommand(obj, Command);
        [Response] = readResponse(obj);
        
    end
    
    methods (Static)
        
    end
    
    
end