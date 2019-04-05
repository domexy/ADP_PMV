classdef Scale < handle
    properties
        serialPort;
        portID = '';    % z.B. COM7
        mass;
        paperObject;
        cANbus;
    end
    
    methods
        % Konstruktor
        function this = Scale(portID, cANbus)
            this.portID = portID;
            this.cANbus = cANbus;
            this.connect();
        end
        % Verbindung zur Waage herstellen
        function connect(this)
            % alle bestehenden Verbindungen zu COM-Ports schließen
            delete(instrfindall)

            % Verbindung zu COM-Port aufbauen
            this.serialPort = serial(this.portID,'BaudRate',9600,'DataBits',8,'StopBits',1,'Parity','none', 'Terminator', 'ETX');

            % Callback definieren: Wenn 15 byte an der Schnittstelle angekommen
            % sind, wird readMass() aufgerufen
%             this.serialPort.BytesAvailableFcnMode = 'byte';
%             this.serialPort.BytesAvailableFcnCount = 15;
%             this.serialPort.BytesAvailableFcn = {@this.getMass};

            % Verbindung zum COM-Port öffnen
            fopen(this.serialPort);
        end
        % Verbindung zur Waage trennen
        function disconnect(this)
            % Verbindung schließen 
            fclose(this.serialPort);

            % Verbindung trennen und Speicher wieder freigeben
            delete(this.serialPort);
            clear this.serialPort;
        end
        
        % Tara-Funktion der Waage
        function zero(this)
            this.cANbus.sendMsg(516,1);
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
            
       
        end
        
        function mass = awaitMass(this)
            timer = tic;
            
            while(true)
                pause(0.1);
                if (this.serialPort.BytesAvailable >= 15)
                    [mass,count,msg] = fscanf(this.serialPort,'\002%f g  \003');
                    mass
                    break;
                elseif (toc(timer) > 10)
                    disp('Scale.m --> Mass nach 10 Sec. noch nicht da');
                    break;
                end
                
            end
        end
        
        
    end
    
    events
    end
end



% EventData: https://stackoverflow.com/questions/23230723/how-to-send-data-through-matlab-events-and-listeners