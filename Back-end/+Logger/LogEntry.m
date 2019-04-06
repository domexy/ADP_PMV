classdef LogEntry
    %LOGENTRY Summary of this class goes here
    %   Detailed explanation goes here
    
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

