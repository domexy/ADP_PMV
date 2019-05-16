classdef MeasuringSystem < StateObject
    % Verwendete Module und Subklassen
    properties
        cANbus;
        mega;
        cam;
        scale;
        paperObject;
        weighingBelt;
        servoVorhangFront;
        servoVorhangRear;
    end
    
    % Für den Nutzer nicht sichtbare EventListener
    properties(Hidden)
        listenerStart;
        listenerLightBarrierOn;
        listenerLightBarrierOff;
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        gate_position = 0;
        light_barrier_blocked = 0;
        ready_for_handoff = 0;
    end
    
     methods
        % Erstellt das Objekt
        function this = MeasuringSystem(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.scale = Scale(this.logger);
            this.weighingBelt = WeighingBelt(this.logger);
            this.cam = Camera(this.logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this,cANbus,mega)
            this.cANbus = cANbus;
            this.mega = mega;
            this.servoVorhangRear = servo(mega,'D7','MinPulseDuration',5.3e-4 , 'MaxPulseDuration',2.6e-3);
            this.servoVorhangFront = servo(mega,'D6','MinPulseDuration',5.3e-4 , 'MaxPulseDuration',2.6e-3);
            this.scale.init('COM1', cANbus);
            this.weighingBelt.init(cANbus);
            this.cam.init();
            
%             this.listenerStart = addlistener(this.cANbus,'StartMeasurement',@this.startConvBelt);
            this.listenerLightBarrierOn = addlistener(this.cANbus,'LightBarrierMeasOn',@this.setLightBarrierOn);
            this.listenerLightBarrierOff = addlistener(this.cANbus,'LightBarrierMeasOff',@this.setLightBarrierOff);
            this.openGate();
            this.weighingBelt.clearBelt();
            this.setStateInactive('Initialisiert');
        end
        
        % Destruktor
        function delete(this)
            delete(this.listenerStart);
            delete(this.listenerLightBarrierOn);
            delete(this.listenerLightBarrierOff);
        end
        
        % Bereitet das System auf ein Papierobjekt vor (Methode wird durch
        % EventListener ausgelöst
        % Robot -> "Handoff_Request" -> Process -> prepareMeasurement
        function prepareMeasurement(this,~,~,~,~)
            this.setStateActive('Messung vorbereiten...');
            this.openGate();
            this.scale.zero();
            this.weighingBelt.start();
%             waitfor(this,'light_barrier_blocked',0)
            this.setStateActive('Akzeptiere Probe...');
            notify(this,'Handoff_Accept'); % Informiert Listener, dass das System aufnahmebereit ist
            % Hier muss das Timing eingestellt werden, damit die Waage zum
            % richtigen Zeitpunkt gestoppt wird
%             pause(6)
%             waitfor(this,'light_barrier_blocked',1)
%             waitfor(this,'light_barrier_blocked',0)
            pause(2)
            this.weighingBelt.stop();
%             this.scale.awaitMass(); 
            
            this.setStateInactive('Probe erhalten...');
        end
        
        % Vermisst das Papierobjekt
        function [success, error] = measure(this)
            success = 1;
            error = 0;
            this.ready_for_handoff = 0; % Messzelle verweigert sich neuen Proben neue Probe
            this.setStateActive('Messung gestartet...');
            this.closeGate();
%             this.cam.takePhotos();
            pause(2)
            this.setStateInactive('Messung beendet');
            this.setStateActive('Probe auswerfen...');
            this.openGate();
            this.weighingBelt.clearBelt();
            this.setStateInactive('Betriebsbereit');
        end
        
        % Startet das Förderband
        function startConvBelt(this,~,~)
            this.weighingBelt.start();
        end
        
        % Stoppt das Förderband
        function stopConvBelt(this,~,~)
            this.weighingBelt.stop();
        end
        
        % Verfährt das Tor/Vorhang
        function moveGate(this, position)
            writePosition(this.servoVorhangRear,1-position)
            writePosition(this.servoVorhangFront,position*0.995) % Keine Ahnung, warum nur dieser Servo keine 1 als Wert akzeptiert... ist aber so
            this.gate_position = position;
            this.logger.debug(['Messzellentore Position: ', num2str(position)])
        end
        
        % Öffnet das Tor/Vorhang
        function openGate(this)
            this.moveGate(0)
            this.logger.info('Messzellentore geöffnet')
        end
        
        % Schließt das Tor/Vorhang
        function closeGate(this)
            this.moveGate(1)
            this.logger.info('Messzellentore geschlossen')
        end
        
        % Setter für light_barrier_blocked, für EventListener
        function setLightBarrierOn(this,~,~)
            this.light_barrier_blocked = 1;
        end
        
        % Setter für light_barrier_blocked, für EventListener
        function setLightBarrierOff(this,~,~)
            this.light_barrier_blocked = 0;
        end
           
        % Methode zur Zustandsbestimmung
        function updateState(this)
            try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.cANbus.getState(),...
                        this.cam.getState(),...
                        this.scale.getState(),...
                        this.weighingBelt.getState()];
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
     
     % Durch das Objekt ausgelöste Ereignisse
     events
         Handoff_Accept
     end
end
    