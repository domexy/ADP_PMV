classdef Scale < StateObject
    % Verwendete Module und Subklassen
    properties
        serialPort;
        portID = '';    % z.B. COM7
        cANbus;
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        mass = 0;
    end
    
    methods
        % Erstellt das Objekt
        function this = Scale(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this,portID, cANbus)
            try
                this.portID = portID;
                this.cANbus = cANbus;
                this.connect();
                
                this.setStateInactive('Initialisiert');
            catch ME
                this.setStateError('Initialisierung fehlgeschlagen');
                this.logger.error(ME.message);
            end
        end
        
        % Verbindung zur Waage herstellen
        function connect(this)
            % alle bestehenden Verbindungen zu COM-Ports schlieï¿½en
            delete(instrfindall)
            
            % Verbindung zu COM-Port aufbauen
            this.serialPort = serial(this.portID,'BaudRate',9600,'DataBits',8,'StopBits',1,'Parity','none', 'Terminator', 'ETX');
            
            % Callback definieren: Wenn 15 byte an der Schnittstelle angekommen
            % sind, wird readMass() aufgerufen
            %             this.serialPort.BytesAvailableFcnMode = 'byte';
            %             this.serialPort.BytesAvailableFcnCount = 15;
            %             this.serialPort.BytesAvailableFcn = {@this.getMass};
            
            % Verbindung zum COM-Port ï¿½ffnen
            fopen(this.serialPort);
            this.logger.info('Verbindung zur Waage hergestellt');
        end
        
        % Verbindung zur Waage trennen
        function disconnect(this)
            % Verbindung schlieï¿½en
            fclose(this.serialPort);
            
            % Verbindung trennen und Speicher wieder freigeben
            delete(this.serialPort);
            clear this.serialPort;
            this.logger.info('Verbindung zur Waage beendet');
        end
        
        % Tara-Funktion der Waage
        function zero(this)
            this.cANbus.sendMsg(516,1);
            this.mass = 0;
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
        
        % Auf Masse-Nachricht von der Waage warten
        function status = awaitMass(this)
            this.setStateActive('Masse bestimmen');
            timer = tic;
            
            while(true)
                pause(0.1);
                if (this.serialPort.BytesAvailable >= 15)
%                     line = fgetl(this.serialPort)
%                     disp(line)
                    [mass,count,msg] = fscanf(this.serialPort,'\002%f g  \003');
                    disp([mass,count,msg])
                    this.mass = mass;
                    this.logger.info(['Waage misst: ',num2str(mass),' [g]']);
                    status = 1;
                    break;
                elseif (toc(timer) > 10)
                    this.logger.warning('Mass nach 10 Sec. noch nicht da');
%                     mass = [];
                    status = 0;
                    break;
                end
                
            end
            this.setStateInactive('Betriebsbereit');
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.cANbus.getState()];
                    if any(sub_system_states == this.ERROR)
                        this.changeStateError('Fehler im Subsystem')
                    end                
                end
            catch
                this.changeStateError('Fehler bei der Zustandsaktualisierung')
            end
        end
        
        % Reaktion des Objektes auf Zustandsänderung
        function onStateChange(this)
            if ~this.isReady()
                
            end
        end
    end
end



% EventData: https://stackoverflow.com/questions/23230723/how-to-send-data-through-matlab-events-and-listeners