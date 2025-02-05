classdef RebelStarLED < mic.lightsource.abstract
    % mic.lightsource.RebelStarLED: Matlab Instrument Control Class for the Rebel Star LED
    %
    % ## Description
    % This class controls a Luxeon Rebel Star LED via a 700 mA 'BUCKPUCK'
    % model 3023-D-E-700.  The power can be set between 0 and 100% as well as
    % turned off or on.
    % The current from the LED driver is regulated by the analog voltage output
    % of a NI DAQ card. The Constructor requires the Device and Channel details.
    % The output current, and therfore the light output follows the
    % relationship
    %  C_out/C_max = (V_off - V_in)/(V_off - V_100)
    % Where C_out is the output current, V_in is the input voltage,
    % V_off is the voltage where output current drops to zero and V_100 is the
    % Voltage where current begins to drop from 100%. V_off and V_100 must be
    % measured and set in the class.
    %
    % ## Link to Driver:
    % http://www.luxeonstar.com/700ma-external-dimming-buckpuck-dc-driver-leaded
    %
    % ## Protected Properties
    %
    % ### `InstrumentName`
    % Descriptive name of the instrument.
    % **Default:** `'RebelStarLED'`.
    %
    % ### `Power`
    % Currently set output power.
    % **Default:** `0`.
    %
    % ### `PowerUnit`
    % Unit for measuring power.
    % **Default:** `'Percent'`.
    %
    % ### `MinPower`
    % Minimum power setting.
    % **Default:** `0`.
    %
    % ### `MaxPower`
    % Maximum power setting.
    % **Default:** `100`.
    %
    % ### `IsOn`
    % On or off state of the device (`0` for OFF, `1` for ON).
    % **Default:** `0`.
    %
    % ### `V_off`
    % Voltage at which output current drops to zero.
    % **Default:** `4.2`.
    %
    % ### `V_100`
    % Voltage at which current begins to drop from 100%.
    % **Default:** `3.5`.
    %
    % ### `V_0`
    % Voltage setting to completely turn off the device.
    % **Default:** `5`.
    %
    % ### `DAQ`
    % NI DAQ session object.
    % **Default:** `[]`.
    %
    % ## Hidden Properties
    %
    % ### `StartGUI`
    % Indicates whether the GUI should start when creating an instance of the class.
    % **Default:** `false`.
    
    % ## Constructor
    % Example: RS = mic.lightsource.RebelStarLED('Dev1', 'ao1');
    %
    % ## Key Functions: 
    % delete, setPower, on, off, exportState, shutdown
    %
    % ## REQUIREMENTS:
    %   mic.abstract.m
    %   mic.lightsource.abstract.m
    %   Data Acquisition Toolbox
    %   MATLAB NI-DAQmx driver installed via the Support Package Installer
    %
    % ### CITATION: Lidkelab, 2017.
    
    properties (SetAccess=protected)
        InstrumentName='RebelStarLED' % Descriptive Instrument Name
        Power=0;            % Currently Set Output Power
        PowerUnit='Percent' % Power Unit 
        MinPower=0;         % Minimum Power Setting
        MaxPower=100;       % Maximum Power Setting
        IsOn=0;             % On or Off State.  0,1 for off,on
       
    end
    
    properties (SetAccess=protected)
        V_off=4.2;      % Voltage where output current drops to zero         
        V_100=3.5;      % Voltage where current begins to drop from 100%
        V_0=5;          % Voltage to set completetly off
        DAQ=[];         % NI DAQ Session
    end
    
    properties (Hidden)
        StartGUI=false; % Start gui when creating instance of class
    end
    
    methods
        function obj=RebelStarLED(NIDevice,AOChannel)
            % Creates a mic.lightsource.RebelStarLED object and sets output to minimum and turns off LED. 
            % Example: RS=mic.lightsource.RebelStarLED('Dev1','ao1')
            
            obj=obj@mic.lightsource.abstract(~nargout);
            %obj = obj@mic.lightsource.abstract();
            %obj = obj@mic.abstract(~nargout);
           
            if nargin<2
                error('mic.lightsource.RebelStarLED::NIDevice and AOChannel must be defined')
            end
            %Set up the NI Daq Object
           
            obj.DAQ = daq.createSession('ni');
            addAnalogOutputChannel(obj.DAQ,NIDevice,AOChannel, 'Voltage');
          
            %Set to minimum power
            obj.setPower(obj.MinPower);
            obj.off();
        end
        function delete(obj)
            % Destructor
            obj.shutdown();
        end
        function setPower(obj,Power_in)
            % Sets output power in percentage of maximum
            obj.Power=max(obj.MinPower,Power_in);
            obj.Power=min(obj.MaxPower,obj.Power);
            
            %Output voltage
            if obj.IsOn %Only set voltage if we are on
                V_out=obj.V_off-obj.Power/100*(obj.V_off-obj.V_100);
            else
                V_out=obj.V_0;  %turn off - should be redundant. 
            end
            if ~isempty(obj.DAQ) %daq not yet created
                outputSingleScan(obj.DAQ,V_out);
            end
        end
        function on(obj)
            % Turn on LED to currently set power. 
            obj.IsOn=1;
            obj.setPower(obj.Power);
        end
        function off(obj)
            % Turn off LED. 
            V_out=obj.V_0; 
            if ~isempty(obj.DAQ) %daq not yet created
                outputSingleScan(obj.DAQ,V_out);
            end
            obj.IsOn=0;
        end
        function [State,Data,Children]=exportState(obj)
            % Export the object current state
            State.Power=obj.Power;
            State.IsOn=obj.IsOn;
            Data=[];
            Children=[];
        end
        function shutdown(obj)
            % Set power to zero and turn off. 
            obj.setPower(0);
            obj.off();
            delete(obj.DAQ);
        end
        
    end
        methods (Static=true)
            function funcTest(NIDevice,AOChannel)
                % Unit test of object functionality
                
                if nargin<2
                    error('mic.lightsource.RebelStarLED::NIDevice and AOChannel must be defined')
                end
            
                %Creating an Object and Testing setPower, on, off
                fprintf('Creating Object\n')
                RS=mic.lightsource.RebelStarLED(NIDevice,AOChannel);
                fprintf('Setting to Max Output\n')
                RS.setPower(100);
                fprintf('Turn On\n')
                RS.on();pause(.5);
                fprintf('Turn Off\n')
                RS.off();;pause(.5);
                fprintf('Turn On\n')
                RS.on();pause(.5);
                fprintf('Setting to 50 Percent Output\n')
                RS.setPower(50);
                fprintf('Delete Object\n')
                %Test Destructor
                delete(RS);
                clear RS;
                
                %Creating an Object and Repeat Test
                fprintf('Creating Object\n')
                RS=mic.lightsource.RebelStarLED(NIDevice,AOChannel);
                fprintf('Setting to Max Output\n')
                RS.setPower(100);
                fprintf('Turn On\n')
                RS.on();pause(.5);
                fprintf('Turn Off\n')
                RS.off();;pause(.5);
                fprintf('Turn On\n')
                RS.on();pause(.5);
                fprintf('Setting to 50 Percent Output\n')
                RS.setPower(50);
                fprintf('Delete Object\n')
                State=exportState();
                delete(RS);
                clear RS;
                 
            end
            
        end
        
end
