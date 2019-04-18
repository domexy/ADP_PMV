classdef WeighingBelt < StateObject
    properties
        cANbus;
        status;
    end
    
    methods
        % Konstruktor
        function this = WeighingBelt(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,cANbus)
            this.cANbus = cANbus;
            
            this.setStateInactive('Initialisiert');
        end
        % Destruktor
        function delete(this)
            try
                this.stop();
            end
        end
        % F�rderband starten
        function start(this)
            this.cANbus.sendMsg(517, 1);
            this.status = 1;
            this.setStateActive('Gestartet...');
        end
        % F�rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            this.status = 0;
            this.setStateActive('Gestoppt');
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
