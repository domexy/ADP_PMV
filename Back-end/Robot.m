classdef Robot < StateObject & MovementController
    % Verwendete Module und Subklassen
    properties
        ur5
        objDetection
        cANbus;
        gripper;
        %         homePose = [26 -290 447 180 0 0];
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        pause_length = 0.125;
        speed = 0.2;
        x = 0;
        y = 0;
        z = 0;
        rx = 0;
        ry = 0;
        rz = 0;
        vacuum_active = false;
    end
    
    methods
        % Erstellt das Objekt
        function this = Robot(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.objDetection = ObjectDetection(this.logger);
            this.gripper = Gripper(this.logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this,cANbus, mega)
            try
                if nargin < 3
                    mega = createMega();
                end
                if nargin == 1
                    cANbus = CANbus();
                    cANbus.init();
                end
                Robot_IP = '192.168.42.5';
                this.ur5 = tcpip(Robot_IP,30000,'NetworkRole','server');
                fclose(this.ur5);
                this.logger.info('"Play" auf Roboter-Display drÃ¼cken...')
                fopen(this.ur5);
                this.logger.info('Roboter Verbunden!');
                
                this.cANbus = cANbus;
                
                this.objDetection.init();
                this.gripper.init(mega);
                
                this.moveToHomePosition();
                this.deactivateVacuum();
                this.gripper.open();
                
                this.setStateInactive('Initialisiert');
            catch ME
                this.setStateError('Initialisierung fehlgeschlagen');
                this.logger.error(ME.message);
            end
        end
                
        % Objekt aufnehmen und in Anlage ablegen
        function success = feedObject(this)
            this.setStateActive('Objektzuführung ...');
            success = 1;
            % Stelle sicher, das Roboter in Home-Position ist
            this.moveToHomePosition();
            this.gripper.open()
            % Lokalisiere Objekte auf Objekttisch und finde Koordinaten vom
            % grï¿½ï¿½ten Objekt
            [xObj, yObj, locSuccess] = this.objDetection.locateObject();
            
            if (locSuccess)                             % Falls ein Objekt lokalisiert wurde
                % Objekt mit Vakuumgreifer anheben
                if (~this.liftObject(xObj, yObj))       % Falls Objekt mit Vakuum nicht angehoben werden kann
                    this.logger.warning('Anheben war nicht erfolgreich');
                    this.sweep();               % kehre Objekttisch ab
                    success = 0;
                else
                    % Objekt mit Vakuum transportieren
                    if (~this.placeObjectInRamp())         % Falls Objekt nicht transportiert werden konnte
                        this.sweep();               % kehre Objekttisch ab
                        success = 0;
                    else
                        this.moveToHomePosition();          % Fahre Roboter zurï¿½ck in die Home-Position
                    end
                end
            else
                this.sweep();
                this.logger.warning('kein Objekt lokalisiert!');
                success = 0;
            end
        end
        
        % Versuche Objekt zu heben
        % Parameter:    x, y des Objekts in Roboter-Koordinaten
        % Rückgabe:     status = 1, wenn Objekt gehoben werden konnte,
        %               status = 0, wenn Objekt nicht gehoben werden konnte
        function status = liftObject(this, xObj, yObj)
            this.setStateActive('Hebe Objekt...');
            
            this.moveTo(xObj, yObj);         % Fahre Sauger auf Objekt
            if ~this.pickUpVacuum()
                if ~this.pickUpGripper()
                    this.setStateInactive('Objekt nicht angehoben');
                    status = 0;
                    return;
                end
            end
            status = 1;
            this.setStateInactive('Objekt angehoben');
        end
        
        % Versuch Objekt mit Unterdruck aufzunehmen
        function status = pickUpVacuum(this)
            this.heaveToVacuumHeight();
            this.activateVacuum();           % Schalte Vakuum ein
            this.heaveToMovementHeight();        % Hebe Objekt hoch
            if this.checkPressureSensor()   % Falls Objekt noch am Sauger hï¿½ngt
                status = 1;                 % Anheben hat funktioniert
                this.logger.info('Unterdruck-Anheben erfolgreich');
                return;                      % Schleife abbrechen
            else                            % falls Objekt nicht am Sauger hï¿½ngt
                this.deactivateVacuum();       % Vakuum ausschalten
                status = 0;                 % Anheben hat nicht funkioniert
                this.logger.warning('Unterdruck-Anheben fehlgeschlagen');
            end
        end
        
        % Versuch Objekt mit Greifer aufzunehmen
        function status = pickUpGripper(this)
            this.gripper.open();
            this.heaveToGrippingHeight();
            this.gripper.close();           % Schließe Greifer
            this.heaveToMovementHeight;        % Hebe Objekt hoch
            if this.gripper.checkObject()   % Falls Objekt noch am Greifer hängt
                status = 1;                 % Anheben hat funktioniert
                this.logger.info('Greifer-Anheben erfolgreich');
                return;                      % Schleife abbrechen
            else                            % falls Objekt nicht am Greifer hängt
                this.gripper.open();       % Öffne Greifer
                status = 0;                 % Anheben hat nicht funkioniert
                this.logger.warning('Greifer-Anheben fehlgeschlagen');
            end
        end
        
        % Fahre Objekt in Anlage
        function success = placeObjectInRamp(this)
            this.setStateActive('Bewege Objekt...')
            success = 1;
            this.moveToDroppingPosition();
            if ~this.hasObject()
                success = 0; % Hat Objekt verloren
                this.setStateInactive('Objekt verloren');
                return;
            end
            
            this.heaveToDroppingHeight();
            notify(this,'Handoff_Request');
            this.releaseObject([],[],[],[]);
            
            this.setStateInactive('Objekt abgelegt');
        end
        
        % Objekt freigeben, durch EventListener ausgelöst
        % MeasuringSystem -> "Handoff_Accept" -> Process -> releaseObject
        function releaseObject(this,~,~,~,~)
            this.gripper.open();
            this.deactivateVacuum();
        end
        
        % Überprüft ob der Roboter ein Papierobjekt hat
        function status = hasObject(this)
            if this.checkPressureSensor()
               status = 1;
            elseif this.gripper.checkObject()
                status = 1;
            else
                status = 0;
            end
        end
        
        % Unterdrucksensor überprüfen, ob Objekt an Sauger hängt
        function status = checkPressureSensor(this)
            % Hier sollte der Drucksensor ausgelesen werden
            % 1: Objekt hängt am Sauger    0: Objekt hängt nicht am Sauger
            status = bitget(this.cANbus.msg_robot,4);
            
            if ~status
                this.logger.warning('Kein Objekt am Sauger');
            end
        end
        
        % Lichtschranke am Förderband
        function status = checkLightBarrier1(this)
            status = bitget(this.cANbus.msg_robot,5);
        end
        
        % Aktiviert Unterdruck
        function activateVacuum(this)
            if ~this.isReady; return; end
            this.cANbus.sendMsg(515,1);
            this.logger.info('Unterdruck aktiviert');
            this.vacuum_active = 1;
        end
        
        % Deaktiviert Unterdruck
        function deactivateVacuum(this)
            this.cANbus.sendMsg(515,0);
            this.logger.info('Unterdruck deaktiviert');
            this.vacuum_active = 0;
        end
        
        % Geschwindigkeit des Roboters einstellen
        function setSpeed(this, speed)
            this.speed = speed;
        end
        
        % Nachricht senden, dass Messsystem mit dem Messprozess beginnen
        % kann
        % VERALTET
        function startMeasurement(this)
            
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.cANbus.getState(),...
                        this.objDetection.getState(),...
                        this.gripper.getState()];
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
    
    % LOWLEVEL, sollte nicht für den Benutzer Verfügbar sein
    methods(Hidden)
        % Funktion zum Auslesen der aktuellen Roboter-Pose
        function P = readPose(this)
            if this.ur5.BytesAvailable>0
                fscanf(this.ur5,'%c',this.ur5.BytesAvailable);
            end
            fprintf(this.ur5,'(2)'); % task = 2 : reading task
            while this.ur5.BytesAvailable==0
            end
            rec = fscanf(this.ur5,'%c',this.ur5.BytesAvailable);
            if ~strcmp(rec(1),'p') || ~strcmp(rec(end),']')
                this.setStateError('Pose kann nicht gelesen werden');
                error('robotpose read error')
            end
            rec(end) = ',';
            Curr_c = 2;
            for i = 1 : 6
                C = [];
                Done = 0;
                while(Done == 0)
                    Curr_c = Curr_c + 1;
                    if strcmp(rec(Curr_c) , ',')
                        Done = 1;
                    else
                        C = [C,rec(Curr_c)];
                    end
                end
                P(i) = str2double(C);
            end
            for i = 1 : length(P)
                if isnan(P(i))
                    this.setStateError('Pose kann nicht gelesen werden (NaN)');
                    error('robotpose read error (Nan)')
                end
            end
            P(1:3) = P(1:3)*1000;           % converting to mm
            P(4:6) = P(4:6)*360/2/3.1415;   % converting to ï¿½
            
            this.x = P(1);
            this.y = P(2);
            this.z = P(3);
            this.rx = P(4);
            this.ry = P(5);
            this.rz = P(6);
        end
        
        % Roboter-Nachricht lesen
        function Msg = readMsg(this)
            Msg = fscanf(this.ur5,'%c',this.ur5.BytesAvailable);
        end
        
        % Funktion zum Bewegen des Roboters
        function move(this,pose,orientation)
            if ~this.isReady; return; end
            
            if nargin == 1
                this.logger.warning('Zu wenige Eingabeparameter');
                error('error; not enough input arguments')
            elseif nargin == 2
                P = pose;
            elseif nargin == 3
                P = [pose,orientation];
            end
            
            if (P(2) < -722)
                this.logger.warning('UngÃ¼ltige Y-Position');
                error('error; invalid Y-Position')
            end
            
            % Informationen zur Roboter-Pose ins richtige Format bringen
            P(1:3) = P(1:3) * 0.001;            % von mm zu m
            P(4:6) = P(4:6) * 2*3.1415/360;     % von ï¿½ zu rad
            P_char = ['(',num2str(P(1)),',',...
                num2str(P(2)),',',...
                num2str(P(3)),',',...
                num2str(P(4)),',',...
                num2str(P(5)),',',...
                num2str(P(6)),','...
                num2str(this.speed),...
                ')'];
            success = '0';
            
            % Informationen an Roboter senden
            while strcmp(success,'0')
                fprintf(this.ur5,'(1)');    % task = 1 : moving task
                pause(0.01);                % Tune this to meet your system
                fprintf(this.ur5,P_char);
                while this.ur5.BytesAvailable==0
                    %         disp([this.ur5.BytesAvailable i]);
                end
                success  = this.readMsg();
            end
            if ~strcmp(success,'1')
                this.setStateError('Pose kann nicht gesendet werden');
                error('error sending robot pose')
            end
            
            % Matlab dazu zwingen zu warten, bis Roboter in Endpose
            % angekommen ist. Ansonsten werden evtl. Wegpunkte ï¿½bersprungen
            while(true)
                pose1 = this.readPose();    % Aktuelle Position auslesen
                pause(0.02);                 % Kurz warten
                pose2 = this.readPose();    % Nochmal Position auslesen
                this.changeStateActive('Verfahre...');
                if(isequal(pose1,pose2))    % Falls die beiden Positionen gleich sind...
                    this.setStateInactive('Pose erreicht');
                    break;                  % ...abbrechen, weil Endposition erreicht wurde
                end
            end
        end
    end
    
    % Ereignisse, die durch das Objekt ausgelöst werden
    events
        Handoff_Request
    end
end