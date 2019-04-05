classdef ConveyorBelt < handle
    properties
        cANbus;
%         listenerStart;
%         listenerStop;
        status;
    end
    
    methods
        % Konstruktor
        function this = ConveyorBelt(cANbus)
            this.cANbus = cANbus;
%             this.listenerStart = addlistener(this.cANbus,'StartConveyorBelt',@this.startInterruption);
%             this.listenerStop = addlistener(this.cANbus,'LightBarrierInterruption',@this.stopInterruption);
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
