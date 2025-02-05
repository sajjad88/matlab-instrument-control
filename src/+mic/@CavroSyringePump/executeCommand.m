function executeCommand(obj, Command)
%Sends a command given by Command to the Cavro syringe pump.
% INPUTS: 
%   obj: An instance of the mic.CavroSyringePump class.
%   Command: A string of command(s) as summarized in the Cavro
%            XP 3000 syringe pump manual page G-1 or described 
%            in detail starting on page 3-21, e.g. 
%            Command = '/1A3000R' or Command = 'A3000'
%
% NOTE: This method should NOT be used for report/control commands: those 
% commands have their own methods. 
%
% CITATION: David Schodt, Lidke Lab, 2018


% Add start/end characters if needed. 
if strcmp(Command(1), '/') ...
        && strcmp(Command(2), num2str(obj.DeviceAddress)) ...
        && strcmp(Command(end), 'R')
    % Command is formatted correctly, do nothing. 
else
    % Add the start character, device number, and execute
    % character. 
    Command = sprintf('/%i%sR', obj.DeviceAddress, Command);
end

% Send the command to the syringe pump. 
if ~isempty(obj.SyringePump)
    % A syringe pump serial object exists, send the command.
    fprintf(obj.SyringePump, Command);
    
    % Update the ReadableAction property to show that a command is being
    % executed. 
    obj.ReadableAction = sprintf('Executing control command %s', Command); 
else
    % No syringe pump serial object exists, tell the user they need to
    % establish a connection.
    error('Syringe pump not connected.')
end
    
    
end
