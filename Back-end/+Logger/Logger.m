classdef Logger < handle
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        log_format = '%time - %level - %source : %message';
        time_format = 'yyyy-mm-ddTHH:MM:SS,FFF'; % Datum- und Zeitangabe nach ISO 8601
        log_store = [];
        level_names = {'Debug', 'Info', 'Warning', 'Fehler'}; % Nur für Schreibvorgänge
        % Log -> Matlabkonsole
        log_print_active = true;
        log_print_level = 4; % Nur Fehler in Matlabkonsole
        % Log -> Logdatei
        log_file_active = false;
        log_file_path = 'log.txt';
        log_file_level = 1; % Alles in Logdatei
        % Log -> GUI
        log_remote_fcn_active = false;
        log_remote_fcn_handle = [];
        log_remote_fcn_level = 1; % Alles in GUI-Log-Tabelle
    end
    
    properties (Access = private)
        
    end
    
    methods 
        function this = Logger()
        end
        
        function debug(this,message)
            this.log(message, 1);
        end
        
        function info(this,message)
            this.log(message, 2);
        end
        
        function warning(this,message)
            this.log(message, 3);
        end
        
        function error(this,message)
            this.log(message, 4);
        end
%     end
%     
%     methods (Access = protected)
        function log(this, message, level)
            stack = dbstack;
            log_entry = Logger.LogEntry(level, stack, message);
            this.addToStore(log_entry);
            this.emitLog(log_entry)
        end
        
        function addToStore(this, log_entry)
            this.log_store = [this.log_store, log_entry];
        end
        
        function emitLog(this, log_entry)
            if this.log_print_active
                this.logToPrint(log_entry);
            end
            if this.log_file_active
                this.logToFile(log_entry);
            end
            if this.log_remote_fcn_active
                this.log_remote_fcn_handle(log_entry);                
            end
        end
        
        function logToPrint(this, log_entry)
            disp(this.formatLog(log_entry));
        end
        
        function logToFile(this, log_entry)
            file_id = fopen(this.log_file_path,'a'); %option 'a' um Text an bestehende Datei anzuhängen
            fprintf(file_id, [this.formatLog(log_entry), '\n']);
            fclose(file_id);
        end
        
        function log_str = formatLog(this, log_entry)
            log_str = this.log_format;
            log_str = replace(log_str, '%time', this.formatTime(log_entry));
            log_str = replace(log_str, '%level', this.formatLevel(log_entry));
            log_str = replace(log_str, '%source', this.formatSource(log_entry));
            log_str = replace(log_str, '%message', this.formatMessage(log_entry));
        end
        
        function time_str = formatTime(this, log_entry)
            time_str = datestr(log_entry.time, this.time_format);
        end
        
        function level_str = formatLevel(this, log_entry)
            level_str = this.level_names{log_entry.level};
        end
        
        function source_str = formatSource(this, log_entry)
            try
                source_str = log_entry.stack(3).name;
            catch
                source_str = 'User';
            end
        end
        
        function message_str = formatMessage(this, log_entry)
            message_str = log_entry.message;
           % Aus Vollständigkeit hier, vielleicht will man ja mal alles kleingeschrieben ausgeben 
        end
        
    end
end

