classdef DrumFeeder < StateObject
    properties        
        mega;   % Arduino Mega 2560
        cANbus;
    end
    
    properties(SetAccess = private, SetObservable)
        drum_voltage = 4.65;
        is_active;
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
            
            this.setStateInactive('Initialisiert');
        end
        
        function setVoltage(this, voltage)
            this.drum_voltage = voltage;
        end
        
        function start(this)
            this.mega.writePWMVoltage('D8',this.drum_voltage); % max = 5 Volt
            this.is_active = 1;
            this.setStateActive(['Rotiert @',num2str(this.drum_voltage),'V']);
        end
        
        function stop(this)
            this.mega.writePWMVoltage('D8',0);
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        function success = isolate(this)
            success = 1;
            this.start();
            tic
            while (this.cANbus.statusLightBarrier1() == 0)
                pause(0.1)
                if (toc > 180)
                    this.logger.warning('Timeout: Lichtschranke1');
                    success = 0;
                    break;
                end
            end
            pause(0.2);
            this.stop();
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
end