classdef Lighting < StateObject
    properties
        logger;
        
        lpt
    end
    
    methods
        % Konstruktor
        function this = Lighting(logger)
            this = this@StateObject();
            
            if nargin < 1
                this.logger.debug = @disp;
                this.logger.info = @disp;
                this.logger.warning = @disp;
                this.logger.error = @disp;
            else
                this.logger = logger;
            end
        end
        
        function init(this,lpt)
            this.lpt = lpt;
            
            this.setStateOnline('Initialisiert');
        end
        % Beleuchtung einstellen
        function changeLighting(this, byte)
            % using java.io.FileOutputStream and java.io.PrintStream
            os = java.io.FileOutputStream(this.lpt); % open stream to LPT1 
            ps = java.io.PrintStream(os); % define PrintStream
            ps.write(byte); % write into buffer 
            ps.close % flush buffer and close stream
        end
    end
    
    events
    end
end