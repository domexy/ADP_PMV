classdef DrumFeeder < StateObject
    properties
        logger;
        
        mega;   % Arduino Mega 2560
        cANbus;
    end
    
    methods
        function this = DrumFeeder(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,cANbus,mega)
            this.mega = mega;
            this.cANbus = cANbus;
            
            this.setStateOnline('Initialisiert');
        end
        
        function start(this)
            this.mega.writePWMVoltage('D8',4.65); % max = 5 Volt
        end
        
        function stop(this)
            this.mega.writePWMVoltage('D8',0);
        end
        
        function success = isolate(this)
            success = 1;
            this.start();
            tic
            while (this.cANbus.statusLightBarrier1() == 0)
                pause(0.1)
                if (toc > 180)
                    disp('DrumFeeder.m --> Timeout: Lichtschranke1');
                    success = 0;
                    break;
                end
            end
            pause(0.2);
            this.stop();
        end
    end
end