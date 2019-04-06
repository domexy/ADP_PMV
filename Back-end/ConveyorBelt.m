classdef ConveyorBelt < StateObject
    properties
        logger;
        
        cANbus;
%         listenerStart;
%         listenerStop;
        status;
    end
    
    methods
        % Konstruktor
        function this = ConveyorBelt(logger)
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
        % Förderband starten
        function start(this)
            this.cANbus.sendMsg(512, 1);
            this.status = 1;
            disp('ConveyorBelt.m --> Förderband gestartet');
        end
        % Förderband stoppen
        function stop(this)
            this.cANbus.sendMsg(512, 0);
            this.status = 0;
            disp('ConveyorBelt.m --> Förderband angehalten');
        end
        
        function success = isolate(this)
            success = 1;
            this.start();
            tic
            while (this.cANbus.statusLightBarrier1() == 0)
                pause(0.1)
                if (toc > 30)
                    disp('ConveyorBelt.m --> Timeout: Lichtschranke1');
                    success = 0;
                    break;
                end
            end
            pause(0.4);
            this.stop();
        end
%         % Förderband starten nach Unterbrechung der Lichtschranke
%         function startInterruption(obj, eventObj, event)
%             obj.start();
%         end
%         % Förderband stoppen durch Unterbrechung der Lichtschranke
%         function stopInterruption(obj, eventObj, event)
%             obj.stop();
%         end
    end
    
    events
    end
end
