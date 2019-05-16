classdef Lighting < StateObject
    % Verwendete Module und Subklassen
    properties
        lpt = 'LPT1';
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        white = false;
        blue = false;
        green = false;
        red = false;
        uv = false;
    end
    
    methods
        % Erstellt das Objekt
        function this = Lighting(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this,lpt)
            if nargin > 1
                this.lpt = lpt;
            end
            
            this.setStateInactive('Initialisiert');
        end
        
        % Destruktor
        function delete(this)
            try
                this.setLightOff();
            catch
                disp('failed to turn of light')
            end
        end
        
        % Aktiviert/Deaktiviert die einzelnen LEDs
        function setLight(this,w,b,g,r,uv)
%             disp([w,b,g,r,uv])
            this.white = w;
            this.blue = b;
            this.green = g;
            this.red = r;
            this.uv = uv;
            byte = int32(double(w)*16 + double(b)*8 + double(g)*4 + double(r)*2 + double(uv));
            
            os = java.io.FileOutputStream(this.lpt); % open stream to LPT1 
            ps = java.io.PrintStream(os); % define PrintStream
            ps.write(byte); % write into buffer 
            disp(byte)
            ps.close
            if byte == 0
                this.setStateInactive(['Aus']);
            else
                this.setStateActive(['LichtCode: ', dec2bin(byte,5)]);
            end
        end
        
        % Aktiviert weißes Licht
        function setLightWhite(this)
            this.setLight(1,0,0,0,0);
            this.logger.info('Weiß-Licht');
        end
        
        % Aktiviert blaues Licht
        function setLightBlue(this)
            this.setLight(0,1,0,0,0);
            this.logger.info('Blau-Licht');
        end
        
        % Aktiviert grünes Licht
        function setLightGreen(this)
            this.setLight(0,0,1,0,0);
            this.logger.info('Grün-Licht');
        end
        
        % Aktiviert rotes Licht
        function setLightRed(this)
            this.setLight(0,0,0,1,0);
            this.logger.info('Rot-Licht');
        end
        
        % Aktiviert UV Licht
        function setLightUV(this)
            this.setLight(0,0,0,0,1);
            this.logger.info('UV-Licht');
        end
        
        % Deaktiviert Licht
        function setLightOff(this)
            this.setLight(0,0,0,0,0);
            this.logger.info('Licht Aus');
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
    
    events
    end
end