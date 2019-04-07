classdef Camera < StateObject
    properties
        logger;
        
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
        end
        
        function init(this)
             % Matlab R2014b starten und einen Instant der
            % Kamera-Server-Klasse in der Variablen s speichern
            !"C:\Program Files\MATLAB\R2014b\bin\matlab.exe" -r "s = CameraServer()"

            % TCPIP-Verbindung konfigurieren
            this.tcpip = tcpip('127.0.0.1', 55000, 'NetworkRole', 'client');
            
            % Input-Buffer-Size auf 1 setzen --> es wird nur ein Zeichen
            % �bertragen
            set(this.tcpip, 'InputBufferSize', 1);
            
            % Versuche 20x die Verbindung zu Matlab R2014b aufzubauen
            for i = 1:20
                try
                    pause(1)                % kurze Pause
                    this.openClient();      % Verbindung aufbauen
                    disp('Camera.m --> Verbindung zur Kamera hergestellt');
                    break;
                catch
                    if (mod(i,5) == 1)      % R�ckmeldung, dass weiter versucht wird, Verbindung aufzubauen
                        disp('Camera.m --> Verbindung zur Kamera wird aufgebaut ...');
                    end
                    
                    if i == 20              % R�ckmeldung, dass Verbindung fehlgeschlagen ist.
                        disp('Camera.m --> Verbindung zur Kamera fehlgeschlagen!');
                    end
                end
            end
            
            % Verbindung zur Beleuchtung herstellen
            this.light = Lighting(this.logger);
            this.light.init('LPT1');
            this.light.changeLighting(0);
            
            this.setStateOnline('Initialisiert');
        end
        
        % Verbindung �ber TCPIP aufbauen
        function openClient(this)
            fopen(this.tcpip);
        end
        
        % Verbindung �ber TCPIP schlie�en
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
                    if this.debug disp('Camera.m --> Foto geladen ...'); end
                    break;
                catch
                    if this.debug disp('Camera.m --> Foto laden ...'); end
                    
                    if i == 5
                        if this.debug disp('Camera.m --> Foto laden fehlgeschlagen!'); end
                    end
                end
            end
            
%             imshow(image);          % Foto anzeigen
            delete('image.mat')     % Foto l�schen
        end
        
        % Ein wei�es und ein UV-Foto aufnehmen
        function takePhotos(this)
            this.light.changeLighting(0);
            this.light.changeLighting(16);
            pause(1)
            this.imgRGB = this.requestFoto();
            this.light.changeLighting(1);
            pause(1)
            this.imgUV = this.requestFoto();
            this.light.changeLighting(0);
            pause(1)
            
            figure(1)
            imshow(this.imgRGB);
            figure(2)
            imshow(this.imgUV);
        end           
        
    end
end


