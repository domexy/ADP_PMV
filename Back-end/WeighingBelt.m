classdef WeighingBelt < StateObject
    properties
        cANbus;
    end
    
    properties(Constant)
        BELT_LENGTH = 88;%in cm
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
        % Fï¿½rderband starten
        function start(this)
            this.setStateActive('Gestartet...');
            this.is_active = 1;
            %CAN-Nachricht wird als letztes gesendet um genaueres ansteuern
            %möglich zu machen
            this.cANbus.sendMsg(517, 1);
        end
        % Fï¿½rderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            %CAN-Nachricht wird als erstes gesendet um genaueres ansteuern
            %möglich zu machen
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        function move(this, distance)
            if distance < 9
                time_gap = -0.003301*distance^2 + (0.06319)*distance + 0.49990+0.01;
            else
                time_gap = 0.015650*distance + 0.6751;
            end
            disp(time_gap)
            this.start();
            tic
            while true
                if toc >= time_gap
                    this.stop();
                    break;
                end
            end
        end
        
        function clearBelt(this)
            this.move(this.BELT_LENGTH*1.2);
        end
        
        function moveToCenter(this)
            this.move(this.BELT_LENGTH/2);
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
