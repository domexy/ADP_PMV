classdef WeighingBelt < handle
    properties
        cANbus;
        status;
    end
    
    methods
        % Konstruktor
        function this = WeighingBelt(cANbus)
            this.cANbus = cANbus;
        end
        % Destruktor
        function delete(this)
            this.stop();
        end
        % F�rderband starten
        function start(this)
            this.cANbus.sendMsg(517, 1);
            this.status = 1;
        end
        % F�rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            this.status = 0;
        end
        
    end
    
    events
    end
end
