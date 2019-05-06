classdef MeasuringSystem < StateObject
    properties
        cANbus;
        mega;
        cam;
        scale;
        paperObject;
        weighingBelt;
        servoVorhang;
    end
    
    properties(Hidden)
        listenerStart;
        listenerLightBarrierOn;
        listenerLightBarrierOff;
    end
    
    properties(SetAccess = private, SetObservable)
        gate_position = 0;
        light_barrier_blocked = 0;
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
            this.servoVorhang = servo(mega,'D7','MinPulseDuration',5.3e-4 , 'MaxPulseDuration',2.6e-3);
            this.scale.init('COM1', cANbus);
            this.weighingBelt.init(cANbus);
            this.cam.init();
            
            this.listenerStart = addlistener(this.cANbus,'StartMeasurement',@this.startConvBelt);
            this.listenerLightBarrierOn = addlistener(this.cANbus,'LightBarrierMeasOn',@this.setLightBarrierOn);
            this.listenerLightBarrierOff = addlistener(this.cANbus,'LightBarrierMeasOff',@this.setLightBarrierOff);
            this.openGate();
            this.setStateInactive('Initialisiert');
        end
        
        function [success, error] = measure(this)
            success = 1;
            error = 0;
            this.weighingBelt.moveToCenter();
            this.closeGate();
            this.setStateActive('Messung gestartet');
            this.cam.takePhotos();
%             this.simulateCamera();

            this.scale.awaitMass();
%             this.scale.zero();
            this.setStateInactive('Messung beendet');
            this.openGate();
            this.weighingBelt.clearBelt();
        end
        
        function startConvBelt(this,~,~)
            this.weighingBelt.start();
        end
        
        function stopConvBelt(this,~,~)
            this.weighingBelt.stop();
        end
        
        function moveGate(this, position)
            writePosition(this.servoVorhang,position)
            this.gate_position = position;
            this.logger.debug(['Messzellentor Position: ', num2str(position)])
        end
        
        function openGate(this)
            this.moveGate(1)
            this.logger.info('Messzellentor geöffnet')
        end
        
        function closeGate(this)
            this.moveGate(0)
            this.logger.info('Messzellentor geschlossen')
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
end
    