classdef MeasuringSystem < handle
    properties
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
        function this = MeasuringSystem(cANbus)
            this.cANbus = cANbus;
            this.scale = Scale('COM1', cANbus);
            this.weighingBelt = WeighingBelt(cANbus);
            this.light = Lighting('LPT1');
            this.cam = Camera();
            
            this.listenerStart = addlistener(this.cANbus,'StartMeasurement',@this.startConvBelt);
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
    