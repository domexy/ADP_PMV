classdef Camera < StateObject
    % Verwendete Module und Subklassen
    properties
        light  
        cam
        src
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        img = []
        imgRGB = []
        imgUV = []
    end
    
    methods
        % Erstellt das Objekt
        function this = Camera(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.light = Lighting(this.logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this)
            try
                % Kamera initalisieren
                imaqreset;
                this.cam = videoinput('gige', 1,'RGB8Packed');
                this.cam.FramesPerTrigger =1;
                this.cam.TriggerRepeat = Inf;
                this.cam.ReturnedColorspace = 'rgb';
                this.cam.ROIPosition = [32 59 2704 2134];   % Historisch aus Ankes Aufbau, wg. Vergleichbarkeit
                this.src = getselectedsource(this.cam);
                this.src.ExposureTimeAbs = 50000; 
                % Verbindung zur Beleuchtung herstellen
                this.light.init('LPT1');
                
                this.setStateInactive('Initialisiert');
            catch ME
                this.setStateError('Initialisierung fehlgeschlagen');
                this.logger.error(ME.message);
            end
        end
                
        % Foto anfordern
        function image = requestFoto(this)
            image = getsnapshot(this.cam);  % Foto aufnehmen
            this.logger.debug('Foto aufgenommen');
        end
        
        % Ein weißes und ein UV-Foto aufnehmen
        function takePhotos(this)
            this.setStateActive('RGB-Foto aufnehmen');
            this.light.setLightWhite();
            pause(1)
            this.imgRGB = this.requestFoto();
            this.setStateActive('UV-Foto aufnehmen');
            this.light.setLightUV();
            pause(3)
            this.imgUV = this.requestFoto();
            this.light.setLightOff();
            pause(1)
            
            figure(1)
            imshow(this.imgRGB);
            figure(2)
            imshow(this.imgUV);
            this.setStateInactive('Betriebsbereit');
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        % Reaktion des Objektes auf Zustandsänderung
        function onStateChange(this)
            if ~this.isReady()
                
            end
        end
    end
end


