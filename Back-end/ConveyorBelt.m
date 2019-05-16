classdef ConveyorBelt < StateObject
    % Verwendete Module und Subklassen
    properties
        cANbus;
        status;
%         listenerStart
%         listenerStop
    end
    
    % Definierte Konstanten
    properties(Constant)
        BELT_LENGTH = 175; %in cm
        TABLE_LENGTH = 35; %in cm
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        is_active;
        light_barrier_active;
    end
    
    methods
        % Erstellt das Objekt
        function this = ConveyorBelt(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
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
        
        % Förderband starten
        function start(this)
            if ~this.isReady; return; end
            this.setStateActive('Gestartet');
            this.is_active = 1;
            %CAN-Nachricht wird als letztes gesendet um genaueres ansteuern
            %möglich zu machen
            this.cANbus.sendMsg(512, 1);
        end
        
        % Förderband stoppen
        function stop(this)
            this.cANbus.sendMsg(512, 0);
            %CAN-Nachricht wird als erstes gesendet um genaueres ansteuern
            %möglich zu machen
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        % Förderband um eine Distanz verfahren
        function move(this, distance)
            if distance < 15
                time_gap = -0.002551*distance^2 + (0.07277)*distance +  0.08391;
            else
                time_gap = 0.01623*distance + 0.3929;
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
        
        % Förderband um definierte Distanz verfahren, damit eine Probe auf
        % den Vereinzelungstische gefördert wird
        function moveObjectOntoTable(this)
            this.move(this.TABLE_LENGTH/2);
        end
        
        % Sämtliche Objekte vom Förderband entfernen
        function clearBelt(this)
            this.move(this.BELT_LENGTH*1);
        end
        
        % Förderband aktivieren bis Lichtschranke am Ende ausgelöst wird
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
        
        % Zustand der Lichtschranke zurückgeben
        function status = lightBarrierActivated(this)
           status = this.cANbus.statusLightBarrier1();
           this.light_barrier_active = status;
        end
        
        % Methode zur Zustandsbestimmung
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
        
        % Reaktion des Objektes auf Zustandsänderung
        function onStateChange(this)
            if ~this.isReady()
                this.stop();
            end
        end
        
    end
    
    events
    end
end
