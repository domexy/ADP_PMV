classdef WeighingBelt < StateObject
    properties
        cANbus;
    end
    
    properties(SetAccess = private, SetObservable)
        is_active = 0;
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
            this.is_active = 1;
            this.setStateActive('Gestartet...');
        end
        % F�rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        function updateState(this)
           try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.cANbus.getState()];
                    if any(sub_system_states == this.ERROR)
                        this.changeStateError('Fehler im Subsystem')
                    end                
                end
            catch
                this.changeStateError('Fehler bei der Zustandsaktualisierung')
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
