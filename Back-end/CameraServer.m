classdef CameraServer < StateObject
    properties
        logger;
        
        tcpip
        cam
        src
    end
    
    methods
        function this = CameraServer(logger)
            this = this@StateObject();
            
            if nargin < 1
                this.logger.debug = @disp;
                this.logger.info = @disp;
                this.logger.warning = @disp;
                this.logger.error = @disp;
            else
                this.logger = logger;
            end
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
            disp('server.m --> Kamera initialisiert');
            
            % TCPIP-Verbinung konfigurieren
            this.tcpip = tcpip('0.0.0.0',55000,'NetworkRole','Server');
            this.tcpip.BytesAvailableFcnMode = 'byte';
            this.tcpip.BytesAvailableFcnCount = 1;
            this.tcpip.BytesAvailableFcn = @(~,~)this.takePicture();
            set(this.tcpip, 'InputBufferSize', 1);
            
            % Verbindung aufbauen
            fopen(this.tcpip);
            disp('server.m --> Verbindung aufgebaut');
            
            this.setStateOnline('Initialisiert');
        end
        
        % Foto aufnehmen und in .mat-Datei speichern
        function takePicture(this)
            dummy = fread(this.tcpip);          % gesendetes Byte auslesen
            image = getsnapshot(this.cam);  % Foto aufnehmen
            save('image.mat','image');       % Foto speichern
            disp('server.m --> Foto aufgenommen');
        end
        
        function image = takePictureRaw(this)
            image = getsnapshot(this.cam);  % Foto aufnehmen
        end
    end
end






