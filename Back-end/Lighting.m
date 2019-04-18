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
            
            this.setStateInactive('Initialisiert');
        end
        % Beleuchtung einstellen
        function changeLighting(this, byte)
            if byte == 0
                this.setStateInactive('Licht Aus');
            else
                this.setStateActive(['Licht-Bytecode = ' num2str(byte)]);
            end
            % using java.io.FileOutputStream and java.io.PrintStream
            disp(1)
            os = java.io.FileOutputStream(this.lpt); % open stream to LPT1 
            disp(2)
            ps = java.io.PrintStream(os); % define PrintStream
            disp(3)
            ps.write(byte); % write into buffer 
            disp(4)
            ps.close % flush buffer and close stream
            disp(5)
        end
        
        function updateState(this)
           if this.getState ~= this.OFFLINE
                
            end 
        end
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
    
    events
    end
end