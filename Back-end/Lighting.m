classdef Lighting < StateObject
    properties
        lpt
        current_bitcode = '000000'
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
            if nargin == 1
                lpt = 'LPT1';
            end
            this.lpt = lpt;
            
            this.setStateInactive('Initialisiert');
        end
        % Beleuchtung einstellen
        function changeLighting(this, byte)
            if byte == 0
                this.setStateInactive('Licht Aus');
            else
                this.setStateActive(['Licht-Bitcode = ' dec2bin(byte)]);
            end
            % akuteller Zustand abfragbar machen über current_bitcode
            bitcode = dec2bin(byte,5);
            this.current_bitcode = bitcode(end-4:end);
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
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
    
    events
    end
end