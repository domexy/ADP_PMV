classdef Logger < handle
    %LOGGER Framework zr kontrollierten Ausgabe von Systemnachrichten
    % Erstellbar durch Logger.Logger()
    
    properties
        log_format = '%time - %level - %source : %message';
        time_format = 'yyyy-mm-ddTHH:MM:SS,FFF'; % Datum- und Zeitangabe nach ISO 8601
        log_store = [];
        level_names = {'Debug', 'Info', 'Warning', 'Fehler'}; % Nur f�r Schreibvorg�nge
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
        % Dateien die beim Durchsuchen des Stacks ignoriert werden;
        forbidden_files = {'Logger.m'}
    end
    
    methods 
        function this = Logger()
        end
        
        % Nachricht mit Level Debug
        function debug(this,message)
            this.log(message, 1);
        end
        
        % Nachricht mit Level Info
        function info(this,message)
            this.log(message, 2);
        end
        
        % Nachricht mit Level Warning
        function warning(this,message)
            this.log(message, 3);
        end
        
        % Nachricht mit Level Error
        function error(this,message)
            this.log(message, 4);
        end
        
        function addToForbiddenFiles(this,filename)
            if nargin < 2
               stack = dbstack;
               filename = stack(2).file;
            end
            this.forbidden_files = unique([this.forbidden_files, filename]);
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
            file_id = fopen(this.log_file_path,'a'); %option 'a' um Text an bestehende Datei anzuh�ngen
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
                source_level = 1;
                allowed_class_not_found = true;
                while allowed_class_not_found
                    source_file = log_entry.stack(source_level).file();
                    if this.isForbidden(source_file)
                        source_level = source_level + 1;
                    else
                        allowed_class_not_found = false;
                    end
                end
                source_str = log_entry.stack(source_level).name;
            catch
                source_str = 'User';
            end
        end
        
        function message_str = formatMessage(this, log_entry)
            message_str = log_entry.message;
           % Aus Vollst�ndigkeit hier, vielleicht will man ja mal alles kleingeschrieben ausgeben 
        end
        
        function forbidden = isForbidden(this, filename)
            forbidden = false;
            for i = 1:length(this.forbidden_files)
                if strcmp(filename,this.forbidden_files{i})
                    forbidden = true;
                    break 
                end
            end
        end
        
    end
end

