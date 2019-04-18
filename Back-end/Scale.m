classdef Scale < StateObject
    properties
        serialPort;
        portID = '';    % z.B. COM7
        mass;
        paperObject;
        cANbus;
    end
    
    methods
        % Konstruktor
        function this = Scale(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,portID, cANbus)
            this.portID = portID;
            this.cANbus = cANbus;
            this.connect();
            
            this.setStateInactive('Initialisiert');
        end
        % Verbindung zur Waage herstellen
        function connect(this)
            % alle bestehenden Verbindungen zu COM-Ports schlie�en
            delete(instrfindall)

            % Verbindung zu COM-Port aufbauen
            this.serialPort = serial(this.portID,'BaudRate',9600,'DataBits',8,'StopBits',1,'Parity','none', 'Terminator', 'ETX');

            % Callback definieren: Wenn 15 byte an der Schnittstelle angekommen
            % sind, wird readMass() aufgerufen
%             this.serialPort.BytesAvailableFcnMode = 'byte';
%             this.serialPort.BytesAvailableFcnCount = 15;
%             this.serialPort.BytesAvailableFcn = {@this.getMass};

            % Verbindung zum COM-Port �ffnen
            fopen(this.serialPort);
            this.logger.info('Verbindung zur Waage hergestellt');
        end
        % Verbindung zur Waage trennen
        function disconnect(this)
            % Verbindung schlie�en 
            fclose(this.serialPort);

            % Verbindung trennen und Speicher wieder freigeben
            delete(this.serialPort);
            clear this.serialPort;
            this.logger.info('Verbindung zur Waage beendet');
        end
        
        % Tara-Funktion der Waage
        function zero(this)
            this.cANbus.sendMsg(516,1);
            this.logger.info('Waage genullt');
        end

        % Masse von COM-Port auslesen
        function getMass(this, eventObj, event)
            % Bestimmen, wie viele Bytes an der seriellen Schnittstelle gesammelt
            % wurden. Erwartet werden 15 bytes. Sind es mehr als 15 bytes, sollen
            % trotzdem alle bytes abgerufen werden

%             [mass,count,msg] = fscanf(this.serialPort,'\002%f g  \003')
%                 
%             
%             this.mass = mass;
            this.logger.info('Waage misst: TODO [g]');
       
        end
        
        function mass = awaitMass(this)
            this.setStateActive('Masse bestimmen');
            timer = tic;
            
            while(true)
                pause(0.1);
                if (this.serialPort.BytesAvailable >= 15)
                    [mass,count,msg] = fscanf(this.serialPort,'\002%f g  \003');
                    this.logger.info('Waage misst: TODO [g]');
                    break;
                elseif (toc(timer) > 10)
                    this.logger.warning('Mass nach 10 Sec. noch nicht da');
                    break;
                end
                
            end
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
    
    events
    end
end



% EventData: https://stackoverflow.com/questions/23230723/how-to-send-data-through-matlab-events-and-listeners