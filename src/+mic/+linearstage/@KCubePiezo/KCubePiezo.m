classdef KCubePiezo < mic.linearstage.abstract
    % mic.linearstage.KCubePiezo Matlab Instrument Control Class for ThorLabs Cube Piezo
    %
    % ## Description
    %   This class controls a linear piezo stage using the Thorlabs KCube Piezo
    %   controller KPZ101 and TCube strain gauge controller KSG101. It uses the Thorlabs 
    %   Kinesis C-API via pre-complied mex files. 
    %
    % ## Protected Properties
    %
    % ### `PositionUnit`
    % Units of the position parameter.
    % **Default:** `'um'` (e.g., microns/millimeters).
    %
    % ### `CurrentPosition`
    % Current position of the device.
    % **Default:** `0`.
    %
    % ### `MinPosition`
    % Lower limit position.
    % **Default:** `0`.
    %
    % ### `MaxPosition`
    % Upper limit position.
    % **Default:** `20`.
    %
    % ### `Axis`
    % Stage axis (options: `X`, `Y`, or `Z`).
    %
    % ### `SerialNoKPZ001`
    % Serial number of the KCube Piezo Controller.
    %
    % ### `SerialNoKSG001`
    % Serial number of the KCube Strain Gauge Controller.
    %
    % ### `Slope`
    % Strain gauge calibration parameter.
    %
    % ### `Offset`
    % Strain gauge calibration parameter.
    %
    % ### `InstrumentName`
    % Name of the instrument.
    % **Default:** `'KCubePiezo'`.
    %
    % ### `WaitTime`
    % Time to wait before returning after a `setPosition` command (in seconds).
    % **Default:** `0`.
    %
    % ## Hidden Properties
    %
    % ### `StartGUI`
    % Flag to indicate whether the GUI should start when creating an instance of the class.
    %
    % ## Protected Properties
    %
    % ### `PositionUnit`
    % Units of the position parameter (e.g., `um` for microns or `mm` for millimeters).
    % **Default:** `'um'`.
    %
    % ### `CurrentPosition`
    % Current position of the device.
    % **Default:** `0`.
    %
    % ### `MinPosition`
    % Lower limit position.
    % **Default:** `0`.
    %
    % ### `MaxPosition`
    % Upper limit position.
    % **Default:** `20`.
    %
    % ### `Axis`
    % Stage axis (`X`, `Y`, or `Z`).
    %
    % ### `SerialNoKPZ001`
    % Serial number of the KCube Piezo Controller.
    %
    % ### `SerialNoKSG001`
    % Serial number of the KCube Strain Gauge Controller.
    %
    % ### `Slope`
    % Strain gauge calibration parameter.
    %
    % ### `Offset`
    % Strain gauge calibration parameter.
    %
    % ### `InstrumentName`
    % Name of the instrument.
    % **Default:** `'KCubePiezo'`.
    %
    % ### `WaitTime`
    % Time to wait before returning after a `setPosition` command (in seconds).
    % **Default:** `0`.
    %
    % ## Hidden Properties
    %
    % ### `StartGUI`
    % Flag indicating whether the GUI should start when creating an instance of the class.
    %
    %   ## Key Functions
    % - **Constructor (`mic.linearstage.KCubePiezo(SerialNoKPZ001, SerialNoKSG001, AxisLabel)`):** Initializes the device with specific serial numbers and the designated axis. Establishes connections and calibrates the device for use.
    % - **`openDevices()`:** Opens connections to the KCube Piezo and Strain Gauge controllers using Thorlabs Kinesis C-API.
    % - **`closeDevices()`:** Safely closes the connections to the piezo and strain gauge controllers to ensure the system is properly shut down.
    % - **`zeroStrainGauge()`:** Sets the strain gauge to zero to ensure accurate position feedback, essential for precise operations.
    % - **`calibrateStrainGauge()`:** Performs a calibration of the strain gauge by measuring known positions to determine the scale and offset required for accurate positioning.
    % - **`setPosition(Position)`:** Moves the piezo stage to the specified position, with input validated against the stage's configured minimum and maximum range.
    % - **`getPosition()`:** Retrieves the current position of the piezo stage, providing feedback on the stage's location in its operational range.
    % - **`shutdown()`:** Completes the session by turning off the devices and ensuring all settings are reset to prevent damage or misconfiguration for future operations.
    % - **`exportState()`:** Exports the current operational state, including position, calibration data, and system settings, useful for session logging or debugging.
    %
    % ## Usage Example
    %   PX=mic.linearstage.KCubePiezo(SerialNoKPZ001,SerialNoKSG001,AxisLabel)
    %   PX.gui()
    %   PX.setPosition(10);
    %
    % ## Kinesis Setup:
    %   change these settings in Piezo device on Kinesis Software GUI before you create object:
    %   1-set on "External SMA signal" (in Advanced settings: Drive Input Settings)
    %   2-set on "Software+Potentiometer" (in Advanced settings: Input Source)
    %   3-set on "closed loop" (in Control: Feedback Loop Settings>Loop Mode)
    %   4-check box of "Persist Settings to the Device" (in Settings)
    %
    % ## REQUIRES: 
    %   mic.Abstract.m
    %   mic.linearstage,abstract.m
    %   Precompiled set of mex files Kinesis_KCube_PCC_*.mex64 and Kinesis_KCube_SG_*.mex64
    %   The following dll must be in system path or same directory as mex files: 
    %   Thorlabs.MotionControl.KCube.Piezo.dll
    %   Thorlabs.MotionControl.KCube.StrainGauge.dll
    %   Thorlabs.MotionControl.DeviceManager.dll
    %
    % ### Citation: Keith Lidke, LidkeLab, 2018.
    
    properties (SetAccess=protected)
        PositionUnit='um';          % Units of position parameter (eg. um/mm)
        CurrentPosition=0;          % Current position of device
        MinPosition=0;              % Lower limit position 
        MaxPosition=20;             % Upper limit position
        Axis;                       % Stage axis (X, Y or Z)
        SerialNoKPZ001;             % Serial Number of KCube Piezo Controller
        SerialNoKSG001;             % Serial Number of KCube Strain Gauge Controller
        Slope;                      % Strain Gauge Calibration Parameter
        Offset;                     % Strain Gauge Calibration Parameter
        InstrumentName='KCubePiezo' % Instrument name. 
    end
    
    properties (SetAccess=protected)
        WaitTime=0;                 %Time to wait before returning after a setPosition (s)
    end
    
    properties (Hidden)
        StartGUI; % Start gui when creating instance of class
    end
    
    methods
        function obj=KCubePiezo(SerialNoKPZ001,SerialNoKSG001,AxisLabel)
            % Creates a KCubePiezo object and centers the stage.  
            % Example: PX=mic.linearstage.KCubePiezo('81843229','84842506','X')
            obj=obj@mic.linearstage.abstract(~nargout);
           
            if nargin<3
                error('mic.linearstage.KCubePiezo::SerialNoKPZ001,SerialNoKSG001,AxisLabel must be defined')
            end
            
            obj.SerialNoKPZ001=SerialNoKPZ001;
            obj.SerialNoKSG001=SerialNoKSG001;
            obj.Axis=AxisLabel;
            try
            %Open Devices (This may crash)
            obj.openDevices();
            
            %Zero the Strain Gauge
            obj.zeroStrainGauge();
            
            %Calibrate the Strain Gauge
            obj.calibrateStrainGauge();
            
            catch ME
                obj.closeDevices();
                warning('Problem contructing KCube Piezo')
                rethrow(ME)
            end
                
            
            %Center
            obj.center();
            
        end
        function delete(obj)
            % Destructor.  
            obj.shutdown();
        end
        
        function Err=openDevices(obj)
            % Opens communications to PZ and SG with Kinesis C-API via mex
            
            Kinesis_TLI_BuildDeviceList(); 
            pause(1);  %Try to prevent crash
            
            ErrSG=Kinesis_KCube_SG_Open(obj.SerialNoKSG001);
            
            % Determine if there were errors opening the strain gauge and
            % output an appropriate warning.
            if ErrSG ~= 0 % ErrSG == 0 suggests a succesful connection
                ErrorMessage = obj.decodeError(ErrSG); 
                warning(['openDevices::Error opening strain gauge ', ...
                    'controller \nError code %i was returned while ', ...
                    'trying to connect to strain gauge %s: \n', ...
                    ErrorMessage], ErrSG, obj.SerialNoKSG001)
            end
            
            ErrPZ=Kinesis_KCube_PCC_Open(obj.SerialNoKPZ001);
            % Determine if there were errors opening the piezo controller
            % and output an appropriate warning.
            if ErrPZ ~= 0 % ErrPZ == 0 suggests a succesful connection
                ErrorMessage = obj.decodeError(ErrPZ); 
                warning(['openDevices::Error opening piezo ', ...
                    'controller \nError code %i was returned while ', ...
                    'trying to connect to piezo controller %s: \n', ...
                    ErrorMessage], ErrPZ, obj.SerialNoKPZ001)
            end
            
            % Return a general error boolean in case it's needed elsewhere.
            Err=(ErrSG==0)&(ErrPZ==0);
            
        end
        
        function closeDevices(obj)
            % Closes communications to PZ and SG with Kinesis C-API via mex
            % This must be done before using Kinesis or creating new
            % objects. 
            Kinesis_KCube_PCC_Close(obj.SerialNoKPZ001)
            Kinesis_KCube_SG_Close(obj.SerialNoKSG001)
        end
        
        function resetDevices(obj)
            % Close and Reopen Devices.  
           obj.closeDevices();
           obj.openDevices();
        end
        
        function zeroStrainGauge(obj)
            % Intiates automatic Voltage-Position Calibration of the 
            SN=obj.SerialNoKPZ001;
            SNSG=obj.SerialNoKSG001;
            
            %Set to open loop and voltage to zero
            Kinesis_KCube_PCC_SetPositionControlMode(SN,2);
            Kinesis_KCube_PCC_SetPosition(SN,uint32(0));
            beep
            pause(4)
            Kinesis_KCube_PCC_SetPositionControlMode(SN,1);
            Kinesis_KCube_PCC_SetPosition(SN,uint32(0));
            
            %Zero strain gauge
            Kinesis_KCube_SG_SetZero(SNSG); % This needs wait till finished inside mex.
            
            %Set to closed loop and voltage to zero
            Kinesis_KCube_PCC_SetPositionControlMode(SN,2);
        end
        
        function calibrateStrainGauge(obj)
            %Calibrate the Piezo/Strain Gauge.  Required for accurate positions.
            SN=obj.SerialNoKPZ001;
            SNSG=obj.SerialNoKSG001;
            
            %Calibration
            Kinesis_KCube_PCC_SetPosition(SN,uint32(0.2*2^16));
            pause(5)
            PZ20=Kinesis_KCube_SG_GetReading(SNSG)/2^15*20;
            
            Kinesis_KCube_PCC_SetPosition(SN,uint32(0.8*2^16));
            pause(5)
            PZ80=Kinesis_KCube_SG_GetReading(SNSG)/2^15*20;
            
            obj.Slope=0.6*2^16/(PZ80-PZ20);
            obj.Offset=0.2*2^16/obj.Slope-PZ20;  
        end
        
        
        function setPosition(obj,Position)
            % Sets Piezo Stage Position in microns. 
            obj.CurrentPosition=max(obj.MinPosition,Position);
            obj.CurrentPosition=min(obj.MaxPosition,obj.CurrentPosition);
            
            Kinesis_KCube_PCC_SetPosition(obj.SerialNoKPZ001,uint32((obj.CurrentPosition+obj.Offset)*obj.Slope)); 
            pause(obj.WaitTime);
            obj.updateGui();
            
        end
        
        function Position=getPosition(obj)
            %Returns the currently set position
            Position=obj.CurrentPosition;
        end
        
        function [Attributes,Data,Children]=exportState(obj)
            % Export the object current state
            Attributes.PositionUnit=obj.PositionUnit;
            Attributes.CurrentPosition=obj.CurrentPosition;
            Attributes.MinPosition=obj.MinPosition;
            Attributes.MaxPosition=obj.MaxPosition;
            Attributes.Axis=obj.Axis;
            Attributes.SerialNoKPZ001=obj.SerialNoKPZ001;
            Attributes.SerialNoKSG001=obj.SerialNoKSG001;
            Attributes.Offset=obj.Offset;
            Attributes.Slope=obj.Slope;
            Attributes.InstrumentName=obj.InstrumentName;
            Data=[];
            Children=[];
        end
        
        function shutdown(obj)
            % Set power to zero and turn off. 
            obj.closeDevices();
        end
        
    end
        methods (Static=true)
            function Success=funcTest(SNP,SNSG,AxisLabel)
                % Unit test of object functionality
                % Example: mic.linearstage.KCubePiezo.funcTest('81843229','84842506','X')
                
                if nargin<3
                    error('mic.linearstage.KCubePiezo::SerialNoKPZ001,SerialNoKSG001,AxisLabel must be defined')
                end
                
                try
                    %Creating an Object and Testing setPower, on, off
                    fprintf('Creating Object and testing...\n')
                    P=mic.linearstage.KCubePiezo(SNP,SNSG,AxisLabel);
                    P.gui;
                    P.setPosition(P.MaxPosition/8);
                    pause(1);
                    P.center();
                    pause(1);
                    P.setPosition(P.MaxPosition*7/8);
                    pause(1);
                    P.exportState()
                    delete(P);
                    fprintf('Deleteing Object.\n')
                    clear RS;
                    Success=1;
                catch
                    warning('mic.linearstage.KCubePiezo:: Failed Unit Test');
                    clear RS;
                    Success=0;
                end
                
            end
            
            function [ErrorMessage] = decodeError(Error)
                % Used to decode an integer error code returned by a TCube
                % device.
                % Example: [ErrorMessage] = decodeError(0) returns
                % ErrorMessage = 'FT_OK - Success' as given in the
                % Thorlabs.MotionControl.C_API Device and Low Level Error
                % Codes section.
                % NOTE: error codes >= 32 might actually be returned as HEX
                %       values, in which case the code here is not working
                %       correctly for such errors...

                % Switch through the possible error codes.
                switch Error
                    % "FTDI and Communication errors
                    % The following errors are generated from the FTDI 
                    % communications module or supporting code."
                    case 0
                        ErrorMessage = 'FT_OK - Success';
                    case 1
                        ErrorMessage = ['FT_InvalidHandle - The FTDI ', ...
                            'functions have not been initialized.'];
                    case 2
                        ErrorMessage = ['FT_DeviceNotFound - The ', ...
                            'Device could not be found'];
                    case 3
                        ErrorMessage = ['FT_DeviceNotOpened - The ', ...
                            'Device must be opened before it can be ', ...
                            'accessed'];
                    case 4
                        ErrorMessage = ['FT_IOError - An I/O Error ', ...
                            'has occured in the FTDI chip.'];
                    case 5
                        ErrorMessage = ['FT_InsufficientResources - ', ...
                            'There are Insufficient resources to run ', ...
                            'this application.'];
                    case 6
                        ErrorMessage = ['FT_InvalidParameter - An ', ...
                            'invalid parameter has been supplied to ', ...
                            'the device.'];
                    case 7
                        ErrorMessage = ['FT_DeviceNotPresent - The ', ...
                            'Device is no longer present'];
                    case 8
                        ErrorMessage = ['FT_IncorrectDevice - The ', ...
                            'device detected does not match that ', ...
                            'expected.'];
                        
                    % "General DLL control errors
                    % The following errors are general errors generated 
                    % by all DLLs."
                    case {32, 20} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_ALREADY_OPEN - Attempt ', ...
                            'to open a device that was already open.'];
                    case {33, 21} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_NO_RESPONSE - The device ', ...
                            'has stopped responding.'];
                    case {34, 22} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_NOT_IMPLEMENTED - This ', ...
                            'function has not been implemented.'];
                    case {35, 23} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_FAULT_REPORTED - The ', ...
                            'device has reported a fault.'];
                    case {36, 24} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_INVALID_OPERATION - The ', ...
                            'function could not be completed at this ', ...
                            'time.'];
                    case {40, 28} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_DISCONNECTING - The ', ...
                            'function could not be completed because ', ...
                            'the device is disconnected.'];
                    case {41, 29} % check for both hex. and dec. errors 
                        ErrorMessage = ['TL_FIRMWARE_BUG - The ', ...
                            'firmware has thrown an error'];
                    case 42
                        ErrorMessage = ['TL_INITIALIZATION_FAILURE - ', ...
                            'The device has failed to initialize'];
                    case 43
                        ErrorMessage = ['TL_INVALID_CHANNEL - An ', ...
                            'Invalid channel address was supplied'];
                        
                    % "Motor specific errors
                    % The following errors are motor specific errors 
                    % generated by the Motor DLLs."
                    case {37, 25} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_UNHOMED - The device ', ...
                            'cannot perform this function until it ', ...
                            'has been Homed.'];
                    case {38, 26} % check for both hex. and dec. errors
                        ErrorMessage = ['TL_INVALID_POSITION - The ', ...
                            'function cannot be performed as it ', ...
                            'would result in an illegal position.'];
                    case {39, 27} % check for both hex. and dec. errors
                        ErrorMessage = ...
                            ['TL_INVALID_VELOCITY_PARAMETER - An ', ...
                            'invalid velocity parameter was supplied'];
                    case 44
                        ErrorMessage = ['TL_CANNOT_HOME_DEVICE - ', ...
                            'This device does not support Homing'];
                    case 45
                        ErrorMessage = ['TL_JOG_CONTINOUS_MODE - An ', ...
                            'invalid jog mode was supplied for the ', ...
                            'jog function.'];
                    otherwise
                        ErrorMessage = 'Unknown error code';
                end
            end
            
        end
        
    
end
