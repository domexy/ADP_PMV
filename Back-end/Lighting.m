classdef Lighting < StateObject
    properties
        lpt
    end
    
    methods
        % Konstruktor
        function this = Lighting(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,lpt)
            this.lpt = lpt;
            
            this.setStateOnline('Initialisiert');
        end
        % Beleuchtung einstellen
        function changeLighting(this, byte)
            if byte == 0
                this.setStateOnline('Licht Aus');
            else
                this.setStateActive(['Licht-Bytecode = ' num2str(byte)]);
            end
            % using java.io.FileOutputStream and java.io.PrintStream
            os = java.io.FileOutputStream(this.lpt); % open stream to LPT1 
            ps = java.io.PrintStream(os); % define PrintStream
            ps.write(byte); % write into buffer 
            ps.close % flush buffer and close stream
        end
        
        function updateState(this)
           if this.getState ~= this.OFFLINE
                
            end 
        end
    end
    
    events
    end
end