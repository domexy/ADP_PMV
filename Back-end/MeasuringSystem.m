classdef MeasuringSystem < StateObject
    properties
        logger;
        
        cANbus;
        status;
        cam;
        scale;
        paperObject;
        weighingBelt;
        listenerStart;
        light;
        
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
        end
        
        function init(this,cANbus)
            this.cANbus = cANbus;
            this.scale = Scale(this.logger);
            this.weighingBelt = WeighingBelt(this.logger);
            this.light = Lighting(this.logger);
            this.cam = Camera(this.logger);
            
            this.scale.init('COM1', cANbus);
            this.weighingBelt.init(cANbus);
            this.light.init('LPT1');
            this.cam.init();
            
            this.listenerStart = addlistener(this.cANbus,'StartMeasurement',@this.startConvBelt);
            
            this.setStateOnline('Initialisiert');
        end
        
        function [success, error] = measure(this)
            success = 1;
            error = 0;
            disp('MeasuringSystem.m --> Messung gestartet');
            this.cam.takePhotos();
%             this.simulateCamera();

            this.scale.awaitMass();
%             this.scale.zero();
            disp('MeasuringSystem.m --> Messung beendet');
        end
        
        function startConvBelt(this,~,~)
            this.weighingBelt.start();
        end
        
        function stopConvBelt(this,~,~)
            this.weighingBelt.stop();
        end
        
        function simulateCamera(this)
            this.light.changeLighting(16);
            % Kurze Pause zum Einstellen
            pause(2);
            this.light.changeLighting(1);
            pause(2);
            this.light.changeLighting(0);
            
        end
     end
end
    