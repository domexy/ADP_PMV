classdef LogEntry
    %LOGENTRY Klasse für einzelne Systemnachrichten
    % Werden durch Logger erstellt
    
    properties
        time
        level
        stack
        message
    end
    
    methods
        function obj = LogEntry(level, stack, message)
            %LOGENTRY Construct an instance of this class
            %   Detailed explanation goes here
            obj.time = now();
            obj.level = level;
            obj.stack = stack;
            obj.message = message;
        end
    end
end

