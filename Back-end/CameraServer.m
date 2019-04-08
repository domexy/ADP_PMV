classdef CameraServer < StateObject
    properties
        tcpip
        cam
        src
    end
    
    methods
        function this = CameraServer(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.init(); % Da es keine Abhängigkeiten zu anderen StateObjects gibt
        end
        
        function init(this)
            % Kamera initalisieren
            imaqreset;
            this.cam = videoinput('gige', 1,'RGB8Packed');
            this.cam.FramesPerTrigger =1;
            this.cam.TriggerRepeat = Inf;
            this.cam.ReturnedColorspace = 'rgb';
            this.cam.ROIPosition = [32 59 2704 2134];   % Historisch aus Ankes Aufbau, wg. Vergleichbarkeit
            this.src = getselectedsource(this.cam);
            this.src.ExposureTimeAbs = 50000; 
            this.src.AllGainAuto = 'Off'; 
            this.src.AllGain = 6; 
            this.logger.debug('Kamera initialisiert');
            
            % TCPIP-Verbinung konfigurieren
            this.tcpip = tcpip('0.0.0.0',55000,'NetworkRole','Server');
            this.tcpip.BytesAvailableFcnMode = 'byte';
            this.tcpip.BytesAvailableFcnCount = 1;
            this.tcpip.BytesAvailableFcn = @(~,~)this.takePicture();
            set(this.tcpip, 'InputBufferSize', 1);
            
            % Verbindung aufbauen
            fopen(this.tcpip);
            this.logger.debug('Verbindung aufgebaut');
            
            this.setStateOnline('Initialisiert');
        end
        
        % Foto aufnehmen und in .mat-Datei speichern
        function takePicture(this)
            dummy = fread(this.tcpip);          % gesendetes Byte auslesen
            image = getsnapshot(this.cam);  % Foto aufnehmen
            save('image.mat','image');       % Foto speichern
            this.logger.debug('Foto aufgenommen');
        end
        
        function image = takePictureRaw(this)
            image = getsnapshot(this.cam);  % Foto aufnehmen
        end
        
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
    end
end






