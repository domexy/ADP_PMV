classdef WeighingBelt < StateObject
    properties
        logger;
        
        cANbus;
        status;
    end
    
    methods
        % Konstruktor
        function this = WeighingBelt(logger)
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
        
        function init(this,cANbus)
            this.cANbus = cANbus;
            
            this.setStateOnline('Initialisiert');
        end
        % Destruktor
        function delete(this)
            this.stop();
        end
        % Förderband starten
        function start(this)
            this.cANbus.sendMsg(517, 1);
            this.status = 1;
        end
        % Förderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            this.status = 0;
        end
        
    end
    
    events
    end
end
