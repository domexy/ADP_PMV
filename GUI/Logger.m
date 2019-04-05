classdef Logger < handle
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time_format = 'yyyy-mm-ddTHH:MM:SS,FFF';
        log_store = [];
    end
    
    properties (Access = private)
        
    end
    
    methods 
        function obj = Logger()
        end
        
        function debug(obj,message)
            obj.log(message, 'Debug');
        end
        
        function info(obj,message)
            obj.log(message, 'Info');
        end
        
        function warning(obj,message)
            obj.log(message, 'Warning');
        end
        
        function error(obj,message)
            obj.log(message, 'Error');
        end
    end
    
    methods (Access = protected)
        function log(obj, message, level)
            stack = dbstack;
            source = stack(2).name;
            log_entry = LogEntry(level, source, message);
            obj.addToStore(log_entry);
            %obj.log_store = [obj.log_store, log_entry];
        end
        
        function addToStore(obj, log_entry)
            obj.log_store = [obj.log_store, log_entry];
        end
        
        function log_str = formatLog(obj, log_entry)
            
        end
        
        function time_str = formatTime(obj, log_entry)
            time_str = datestr(log_entry.time, obj.time_format);
        end
        
        function level_str = formatLevel(obj, log_entry)
            level_str = log_entry.level;
        end
        
        function source_str = formatSource(obj, log_entry)
            source_str = log_entry.source;
        end
        
        function 
    end
end

