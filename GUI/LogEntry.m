classdef LogEntry
    %LOGENTRY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time
        level
        source
        message
    end
    
    methods
        function obj = LogEntry(level, source, message)
            %LOGENTRY Construct an instance of this class
            %   Detailed explanation goes here
            obj.time = now();
            obj.level = level;
            obj.source = source;
            obj.message = message;
        end
        
        function outputStr = format(obj,formatStr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputStr = sprintf(formatStr, 2);
        end
    end
end

