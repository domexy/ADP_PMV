classdef ConveyorBelt < StateObject
    properties
        cANbus;
%         listenerStart;
%         listenerStop;
        status;
    end
    
    properties(SetAccess = private, SetObservable)
        is_active;
        light_barrier_active;
    end
    
    methods
        % Konstruktor
        function this = ConveyorBelt(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this, cANbus)
            this.cANbus = cANbus;
%             this.listenerStart = addlistener(this.cANbus,'StartConveyorBelt',@this.startInterruption);
%             this.listenerStop = addlistener(this.cANbus,'LightBarrierInterruption',@this.stopInterruption);
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
            this.cANbus.sendMsg(512, 1);
            this.is_active = 1;
            this.setStateActive('Gestartet');
        end
        % F�rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(512, 0);
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        function success = isolate(this)
            success = 1;
            this.start();
            tic
            while ~this.lightBarrierActivated()
                pause(0.1)
                if (toc > 30)
                    this.logger.warning('Timeout: Lichtschranke1');
                    success = 0;
                    break;
                end
            end
            pause(0.4);
            this.stop();
        end
        
        function status = lightBarrierActivated(this)
           status = this.cANbus.statusLightBarrier1();
           this.light_barrier_active = status;
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
                this.stop();
            end
        end
        
    end
    
    events
    end
end
