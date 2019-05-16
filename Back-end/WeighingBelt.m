classdef WeighingBelt < StateObject
    % Verwendete Module und Subklassen
    properties
        cANbus;
    end
    
    % Definierte Konstanten
    properties(Constant)
        BELT_LENGTH = 88;%in cm
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        is_active = 0;
    end
    
    methods
        % Erstellt das Objekt
        function this = WeighingBelt(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
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
        
        % Förderband starten
        function start(this)
            if ~this.isReady; return; end
            this.setStateActive('Gestartet...');
            this.is_active = 1;
            %CAN-Nachricht wird als letztes gesendet um genaueres ansteuern
            %möglich zu machen
            this.cANbus.sendMsg(517, 1);
        end
        % Förderband stoppen
        function stop(this)
            this.cANbus.sendMsg(517, 0);
            %CAN-Nachricht wird als erstes gesendet um genaueres ansteuern
            %möglich zu machen
            this.is_active = 0;
            this.setStateInactive('Gestoppt');
        end
        
        % Förderband um eine Distanz verfahren
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
        
        % Objekte von Förderband entfernen
        function clearBelt(this)
            this.move(this.BELT_LENGTH*1.2);
        end
        
        % Objekte in die Mitte des Förderbandes fahren
        function moveToCenter(this)
            this.move(this.BELT_LENGTH/2);
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

            end
        end
    end
    
    events
    end
end
