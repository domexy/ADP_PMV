classdef ConveyorBelt < StateObject
    properties
        cANbus;
%         listenerStart;
%         listenerStop;
        status;
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
            this.setStateOnline('Initialisiert');
        end
        % Destruktor
        function delete(this)
            this.stop();
        end
        % F�rderband starten
        function start(this)
            this.cANbus.sendMsg(512, 1);
            this.status = 1;
            this.setStateActive('F�rderband gestartet');
        end
        % F�rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(512, 0);
            this.status = 0;
            this.setStateOnline('F�rderband angehalten');
        end
        
        function success = isolate(this)
            success = 1;
            this.start();
            tic
            while (this.cANbus.statusLightBarrier1() == 0)
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
%         % F�rderband starten nach Unterbrechung der Lichtschranke
%         function startInterruption(obj, eventObj, event)
%             obj.start();
%         end
%         % F�rderband stoppen durch Unterbrechung der Lichtschranke
%         function stopInterruption(obj, eventObj, event)
%             obj.stop();
%         end
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
    end
    
    events
    end
end
