classdef Camera < StateObject
    properties
        tcpip
        debug = 0;
        light;
        
        img
        imgRGB
        imgUV
        
    end
    
    methods
        function this = Camera(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.light = Lighting(this.logger);
        end
        
        function init(this)
            this.setStateError('KAMERA SERVER UNNÖTIG -> KAMERA DIREKT IMPLEMENTIEREN');
            return
            try
                % Matlab R2014b starten und einen Instant der
                % Kamera-Server-Klasse in der Variablen s speichern
                !"C:\Program Files\MATLAB\R2014b\bin\matlab.exe" -r "addpath('Back-end');s = CameraServer([])"
                
                % TCPIP-Verbindung konfigurieren
                this.tcpip = tcpip('127.0.0.1', 55000, 'NetworkRole', 'client');
                
                % Input-Buffer-Size auf 1 setzen --> es wird nur ein Zeichen
                % ï¿½bertragen
                set(this.tcpip, 'InputBufferSize', 1);
                
                % Versuche 20x die Verbindung zu Matlab R2014b aufzubauen
                for i = 1:20
                    this.logger.info('Verbindung zur Kamera wird aufgebaut ...');
                    try
                        pause(1)                % kurze Pause
                        this.openClient();      % Verbindung aufbauen
                        this.logger.info('Verbindung zur Kamera hergestellt');
                        break;
                    catch                        
                        if i == 20              % Rï¿½ckmeldung, dass Verbindung fehlgeschlagen ist.
                            this.setStateError('Verbindung zur Kamera fehlgeschlagen!');
                            return
                        end
                    end
                end
                
                % Verbindung zur Beleuchtung herstellen
                this.light.init('LPT1');
                this.light.changeLighting(0);
                
                this.setStateInactive('Initialisiert');
            catch ME
                this.setStateError('Initialisierung fehlgeschlagen');
                this.logger.error(ME.message);
            end
        end
        
        % Verbindung ï¿½ber TCPIP aufbauen
        function openClient(this)
            fopen(this.tcpip);
        end
        
        % Verbindung ï¿½ber TCPIP schlieï¿½en
        function closeClient(this)
            fclose(this.tcpip);
        end
        
        function debugMode(this, mode)
            this.debug = mode;
        end
        
        % Foto anfordern
        function image = requestFoto(this)
            % Kamera-Server reagiert auf ein beliebiges, gesendetes Byte
            fwrite(this.tcpip,'1');     % Ein Byte senden, z.B. '1'
            
            % Versuche 5x, das gespeicherte Foto zu laden
            for i = 1:5
                try
                    pause(1)                        % kurze Pause
                    load('image.mat', 'image');     % Foto laden
                    this.logger.debug('Foto geladen ...');
                    break;
                catch
                    this.logger.debug('Foto laden ...');
                    if i == 5
                        this.logger.warning('Foto laden fehlgeschlagen!');
                    end
                end
            end
            
            %             imshow(image);          % Foto anzeigen
            delete('image.mat')     % Foto lï¿½schen
        end
        
        % Ein weiï¿½es und ein UV-Foto aufnehmen
        function takePhotos(this)
            this.setStateActive('RGB-Foto aufnehmen');
            this.light.changeLighting(0);
            this.light.changeLighting(16);
            pause(1)
            this.imgRGB = this.requestFoto();
            this.setStateActive('UV-Foto aufnehmen');
            this.light.changeLighting(1);
            pause(1)
            this.imgUV = this.requestFoto();
            this.light.changeLighting(0);
            pause(1)
            
            figure(1)
            imshow(this.imgRGB);
            figure(2)
            imshow(this.imgUV);
            this.setStateInactive('Betriebsbereit');
        end
        
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        function onStateChange(this)
            if ~this.isReady()
                
            end
        end
    end
end


