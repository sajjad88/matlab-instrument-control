classdef abstract < mic.abstract
    % mic.linearstage.abstract: Matlab Instrument Control abstract class for linear stages.
    %
    % ## Description
    % This class defines a set of Abstract Properties and methods that must
    % implemented in inheritting classes. This class also provides a simple 
    % and intuitive GUI.   
    %
    % ## Constructor
    % The constructor in each subclass must begin with the following line 
    % inorder to enable the auto-naming functionality: 
    % obj=obj@mic.linearstage.abstract(~nargout);
    %
    % ## REQUIRES:
    %   mic.abstract.m
    %   MATLAB 2014b or higher
    %
%     ## Abstract Properties
% - **PositionUnit:** Units of the position parameter (e.g., um, mm), specific to the stage's measurement.
% - **CurrentPosition:** Current position of the stage.
% - **MinPosition:** Minimum limit of the stage's range.
% - **MaxPosition:** Maximum limit of the stage's range.
% - **Axis:** Indicates the stage axis (X, Y, or Z) that the class controls.
% 
% ## Methods
% - **Constructor (`mic.linearstage.abstract(AutoName)`):** Initializes a new instance of a subclass, incorporating auto-naming functionality inherited from `mic.abstract`.
% - **`center()`:** Moves the stage to its center position, calculated as the midpoint between `MinPosition` and `MaxPosition`.
% - **`updateGui()`:** Refreshes the GUI elements to reflect current Properties like position, ensuring the display is up-to-date with the stage's status.
%
% ### Citation: Marjolein Meddens, Lidke Lab, 2017.
    
    properties (Abstract,SetAccess=protected)
        PositionUnit;          % Units of position parameter (eg. um/mm)
        CurrentPosition;       % Current position of device
        MinPosition;           % Lower limit position 
        MaxPosition;           % Upper limit position
        Axis;                  % Stage axis (X, Y or Z)
    end
    
   methods
        function obj=abstract(AutoName)
            obj=obj@mic.abstract(AutoName);
        end
        
        function center(obj) 
            % obj.center Moves stage to center position
            % Center is calculated as (MaxPosition-MinPosition)/2
            centerPos = (obj.MaxPosition-obj.MinPosition)/2;
            obj.setPosition(centerPos);
        end
        
         function updateGui(obj)
            % update gui with current parameters
            % check whether gui is open
            if isempty(obj.GuiFigure) || ~isvalid(obj.GuiFigure)
                return
            end
            % find edit box and slider and update
            for ii = 1 : numel(obj.GuiFigure.Children)
                if strcmp(obj.GuiFigure.Children(ii).Tag,'positionEdit')
                    obj.GuiFigure.Children(ii).String = num2str(obj.CurrentPosition);
                elseif strcmp(obj.GuiFigure.Children(ii).Tag,'positionSlider')
                    obj.GuiFigure.Children(ii).Value = obj.CurrentPosition;
                end
            end
         end
    
   end
    
   
        
    methods (Abstract)
        setPosition(obj,position);  % Move stage to position
        pos = getPosition(obj); % Get current position by querying the stage
    end
    
end




