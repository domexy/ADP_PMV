classdef MeasuringSystem < StateObject
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
    
    properties(Hidden)
        listenerStart;
        listenerLightBarrierOn;
        listenerLightBarrierOff;
    end
    
    properties(SetAccess = private, SetObservable)
        gate_position = 0;
        light_barrier_blocked = 0;
        ready_for_handoff = 0;
    end
    
     methods
        % Konstruktor
        function this = MeasuringSystem(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.scale = Scale(this.logger);
            this.weighingBelt = WeighingBelt(this.logger);
            this.cam = Camera(this.logger);
        end
        
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
        
        function delete(this)
            delete(this.listenerStart);
            delete(this.listenerLightBarrierOn);
            delete(this.listenerLightBarrierOff);
        end
        
        function prepareMeasurement(this,~,~,~,~)
            this.setStateActive('Messung vorbereiten...');
            this.openGate();
%             this.scale.zero();
            this.weighingBelt.start();
%             waitfor(this,'light_barrier_blocked',0)
            this.setStateActive('Akzeptiere Probe...');
            notify(this,'Handoff_Accept');
%             pause(6)
%             waitfor(this,'light_barrier_blocked',1)
%             waitfor(this,'light_barrier_blocked',0)
%             this.weighingBelt.stop();
            this.scale.awaitMass(); 
            
            this.setStateInactive('Probe erhalten...');
        end
        
        function [success, error] = measure(this)
            success = 1;
            error = 0;
            this.ready_for_handoff = 0; % Messzelle verweigert sich neuen Proben neue Probe
            this.setStateActive('Messung gestartet...');
            this.closeGate();
%             this.cam.takePhotos();;
            pause(2)
            this.setStateInactive('Messung beendet');
            this.setStateActive('Probe auswerfen...');
            this.openGate();
            this.weighingBelt.clearBelt();
            this.setStateInactive('Betriebsbereit');
        end
        
        function startConvBelt(this,~,~)
            this.weighingBelt.start();
        end
        
        function stopConvBelt(this,~,~)
            this.weighingBelt.stop();
        end
        
        function moveGate(this, position)
            writePosition(this.servoVorhangRear,1-position)
            writePosition(this.servoVorhangFront,position*0.995) % Keine Ahnung, warum nur dieser Servo keine 1 als Wert akzeptiert... ist aber so
            this.gate_position = position;
            this.logger.debug(['Messzellentore Position: ', num2str(position)])
        end
        
        function openGate(this)
            this.moveGate(0)
            this.logger.info('Messzellentore geöffnet')
        end
        
        function closeGate(this)
            this.moveGate(1)
            this.logger.info('Messzellentore geschlossen')
        end
        
        function setLightBarrierOn(this,~,~)
            this.light_barrier_blocked = 1;
        end
        
        function setLightBarrierOff(this,~,~)
            this.light_barrier_blocked = 0;
        end
                
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
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
     end
     
     events
         Handoff_Accept
     end
end
    