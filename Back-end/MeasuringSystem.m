classdef MeasuringSystem < StateObject
    properties
        cANbus;
        mega;
        status;
        cam;
        scale;
        paperObject;
        weighingBelt;
        listenerStart;
        light;
        servoVorhang;
        
        imgCol
        imgUV
        data
        mass
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
            this.light = Lighting(this.logger);
            this.cam = Camera(this.logger);
        end
        
        function init(this,cANbus,mega)
            this.cANbus = cANbus;
            this.mega = mega;
            this.servoVorhang = servo(mega,'D7','MinPulseDuration',5.3e-4 , 'MaxPulseDuration',2.6e-3);
            this.scale.init('COM1', cANbus);
            this.weighingBelt.init(cANbus);
            this.light.init('LPT1');
            this.cam.init();
            
            this.listenerStart = addlistener(this.cANbus,'StartMeasurement',@this.startConvBelt);
            this.openCell();
            this.setStateInactive('Initialisiert');
        end
        
        function [success, error] = measure(this)
            success = 1;
            error = 0;
            this.closeCell();
            this.setStateActive('Messung gestartet');
            this.cam.takePhotos();
%             this.simulateCamera();

            this.scale.awaitMass();
%             this.scale.zero();
            this.setStateInactive('Messung beendet');
            this.openCell();
        end
        
        function startConvBelt(this,~,~)
            this.weighingBelt.start();
        end
        
        function stopConvBelt(this,~,~)
            this.weighingBelt.stop();
        end
        
        function openCell(this)
            writePosition(this.servoVorhang,1)
        end
        
        function closeCell(this)
            writePosition(this.servoVorhang,0)
        end
        
        function simulateCamera(this)
%             this.light.changeLighting(16);
            % Kurze Pause zum Einstellen
            pause(2);
%             this.light.changeLighting(1);
            pause(2);
%             this.light.changeLighting(0);
            
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
    