classdef abstract < mic.abstract
%  mic.powermeter.abstract
% 
% ## Description
% `mic.powermeter.abstract` is a MATLAB class derived from `mic.abstract` to interface with the power meter (specifically the PM100D model). It enables the measurement of optical power and temperature, and displays this data in real-time through a graphical user interface (GUI).
% 
% ## Features
% - **Real-Time Data Acquisition**: Measures and plots power or temperature data in real time.
% - **Flexible Measurement Options**: Users can query the instrument for either 'power' or 'temperature'.
% - **Adjustable Display Parameters**: Users can set the period of time displayed on the plot and adjust measurement wavelength.
% 
% ## Prerequisites
% - MATLAB 2014 or higher.
% - National Instruments NI-DAQ drivers installed.
% - VISA (Virtual Instrument Software Architecture) software installed.
% 
% ## Installation
% 1. Ensure that MATLAB and the required toolboxes are installed on your system.
% 2. Install the National Instruments NI-DAQ driver compatible with your device.
% 3. Ensure that VISA software is installed for proper communication with the device.
% 4. Clone this repository or download the `mic.powermeter.abstract.m` file into your MATLAB working directory.
% 
% ## Properties
% 
% ### `VisaObj`  
% Visa Object (Virtual Instrument Standard Architecture = VISA).
% 
% ### `Power`  
% Current power.
% 
% ### `Ask`  
% The query sent to the instrument. Possible values are `'power'` or `'temp'`.
% 
% ### `Limits`  
% Minimum and maximum values of wavelength.
% 
% ### `Lambda`  
% Wavelength.
% 
% ### `T`  
% Period of time shown on the figure in the GUI.
% 
% ### `Stop`  
% Controls plotting behavior. Value `0` stops the plot, while `1` starts the plot (default: `0`).
% 
% ## Abstract Properties
% 
% ### `StartGUI`  
% Represents a property for starting the GUI.

% ## Usage Example
% ```matlab
% pm = mic.powermeter.abstract('AutoNameHere');
% % Start the GUI plot. `edit1` and `edit2` are handles to GUI components where the results are displayed.
% pm.guiPlot(edit1, edit2);
% 
% % To export the current state of the power meter:
% state = pm.exportState();
% 
% % Properly shutting down the device:
% pm.Shutdown();
% ```
% ### Citation: Sajjad Khan, Lidkelab, 2024.
    properties
        
        VisaObj             %Visa Object (Virtual Instrument Standard Architecture=VISA)
        Power;              %Currect power
        Ask;                %The question that you ask from the instrument. It could be either 'power' or 'temp'.
        Limits              %Min and max of wavelength.
        Lambda              %Wavelength
        T                   %period of time shown on the figure in the gui.
        Stop=0;             %Stop the plot for 0 and start the plot for 1.
        
    end
    properties %(Abstract)
        StartGUI;
    end
    
    methods %(Abstract)                
        State=exportState(obj);     %Export All Non-Transient Properties in a Structure
        Shutdown(obj);
    end 
    
    methods
        
        function obj=abstract(AutoName)
            obj=obj@mic.abstract(AutoName);
        end
        
        function guiPlot(obj,edit1,edit2)
           %Ploting the measured results in the gui for temperature or
           %power. The two last inputs are the object of the prompts above
           %of the figure in the gui.
           clear power temp t;
           ii=1;
           ss = 0;
           switch obj.Ask
              case 'power' %plotimg power  
                  tic
                  while obj.Stop ==0
                      out=obj.measure();
                      set(edit1,'String',out);
                      power(ii)=out; %The measurment is in Watt and then times 1000 it is in mW.
                      set(edit2,'String',max(power(:)));
                      ss = toc;
                      t(ii) = ss;
                      Start=max(length(power)-round(obj.T)*5,1);
                      semilogy(t(Start:end),power(Start:end),'linewidth',2)
                      xlabel('Time (S)')
                      ylabel('Power (log(mW))')
                      xlim([t(Start),t(Start)+obj.T]);
                      ylim([0.001 1000]);
                      pause(.17171)
                      ii=ii+1;
                  end
            
                case 'temp' %ploting temperature
            
                tic;
                while obj.Stop == 0

                    out=obj.measure();
                    temp(ii)=out;
                    set(edit1,'String',out);
                    set(edit2,'String',max(temp(:)));
                    ss = toc;
                    t(ii) = ss;
                    Start=max(length(temp)-round(obj.T)*5,1);
                    plot(t(Start:end),temp(Start:end),'linewidth',2);
                    xlim([t(Start) t(Start)+obj.T]);
                    ylim([-20 60]);
                    xlabel('Time (s)');
                    ylabel('Temperature (C)');
                    pause(.168);
                    ii=ii+1;
                end
           end
        end
    end
    
end
