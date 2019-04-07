classdef Robot < StateObject
    properties
        logger;
        
        ur5
        objDetection
        homePose = [26 -290 447 180 0 0];
        speed = 0.2;
        cANbus;
        gripper;
        
    end
    
    methods
        % Konstruktor f�r UR5-Roboter
        function this = Robot(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,cANbus, mega)
            Robot_IP = '192.168.42.5';
            this.ur5 = tcpip(Robot_IP,30000,'NetworkRole','server');
            fclose(this.ur5);
            disp('Robot.m --> Press Play on Robot...')
            fopen(this.ur5);
            disp('Robot.m --> Connected!');
            
            this.objDetection = ObjectDetection(this.logger);
            this.cANbus = cANbus;
            
            this.gripper = Gripper(this.logger);
            
            this.gripper.init(mega);
            this.objDetection.init();
            
            this.home();
            
            this.setStateOnline('Initialisiert');
        end
        
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
                    error('robotpose read error (Nan)')
                end
            end
            P(1:3) = P(1:3)*1000;           % converting to mm
            P(4:6) = P(4:6)*360/2/3.1415;   % converting to �
        end
        
        % Roboter-Nachricht lesen
        function Msg = readMsg(this)
            Msg = fscanf(this.ur5,'%c',this.ur5.BytesAvailable);
        end
        
        % Funktion zum Bewegen des Roboters
        function move(this,pose,orientation)
            if nargin == 1
                error('error; not enough input arguments')
            elseif nargin == 2
                P = pose;
            elseif nargin == 3
                P = [pose,orientation];
            end
            
            if (P(2) < -722) || (P(2) > -290)
                error('error; invalid Y-Position')
            end
            
            % Informationen zur Roboter-Pose ins richtige Format bringen
            P(1:3) = P(1:3) * 0.001;            % von mm zu m
            P(4:6) = P(4:6) * 2*3.1415/360;     % von � zu rad
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
                error('error sending robot pose')
            end
            
            % Matlab dazu zwingen zu warten, bis Roboter in Endpose
            % angekommen ist. Ansonsten werden evtl. Wegpunkte �bersprungen
            while(true)
                pose1 = this.readPose();    % Aktuelle Position auslesen
                pause(0.1);                 % Kurz warten
                pose2 = this.readPose();    % Nochmal Position auslesen
%                 disp('fahre');
                if(isequal(pose1,pose2))    % Falls die beiden Positionen gleich sind...
%                     disp('--> angekommen');
                    break;                  % ...abbrechen, weil Endposition erreicht wurde
                end
            end
        end
        
        % Fahre Roboter in die Home-Position
        function home(this)
            this.move(this.homePose);
            this.gripper.open();
        end
        
        % Objekttische abkehren und damit von Objekten befreien
        function sweep(this)
            wp{1} = [0 -400 130 180 0 0];
            wp{2} = [-173.99 -409.07 76.74 -144.38 -1.78 -107.33];
            wp{3} = [-161.49 -409.07 66.74 -144.38 -0.78 -105.33];
            wp{4} = [176.13 -409.07 64.24 143.58 0.78 107.73];
            wp{5} = [0 -400 130 180 0 0];
            wp{6} = [-173.99 -679.71 76.74 -144.38 -1.78 -107.33];
            wp{7} = [-161.49 -679.71 66.74 -144.38 -0.78 -105.33];
            wp{8} = [176.13 -679.71 64.24 143.58 0.78 107.73];
            wp{9} = [0 -400 130 180 0 0];
            
            for k=1:length(wp)
                curWP = wp{k};
                this.move(curWP);
            end
            
            % Fahre Roboter zur�ck in die Home-Position
            this.home();
        end
        
        % Objekt in Anlage ablegen
        function success = feedObject(this)
            success = 1;
            % Stelle sicher, das Roboter in Home-Position ist
            this.home();
            % Lokalisiere Objekte auf Objekttisch und finde Koordinaten vom
            % gr��ten Objekt
            [xObj, yObj, locSuccess] = this.objDetection.locateObject();
            
            if (locSuccess)                             % Falls ein Objekt lokalisiert wurde
                % Objekt mit Vakuumgreifer anheben
                if (~this.liftObject(xObj, yObj))       % Falls Objekt mit Vakuum nicht angehoben werden kann
                    disp('Robot.m --> Vakuum-Greifer war nicht erfolgreich');
                    % Objekt mit mech. Greifer anheben
                    if(~this.liftObjectGripper(xObj, yObj)) % Falls Objekt mit mech. Greifer nicht angehoben werden kann
                        this.sweep();                     % kehre Objekttisch ab
                        success = 0;
                    else
                        disp('Robot.m --> Objekt mit Greifer gegriffen');
                        % Objekt mit Greifer transportieren
                        if (~this.moveObjectGripper())  % Falls Objekt nicht transportiert werden konnte
                            this.sweep();               % kehre Objekttisch ab
                            success = 0;
                        else
                            this.returnHome();          % Fahre Roboter zur�ck in die Home-Position
                        end                        
                    end
                    
                else
                    % Objekt mit Vakuum transportieren
                    if (~this.moveObject())         % Falls Objekt nicht transportiert werden konnte
                        this.sweep();               % kehre Objekttisch ab
                        success = 0;
                    else
                        this.returnHome();          % Fahre Roboter zur�ck in die Home-Position
                    end
                end
                
                
            else
                disp('Robot.m --> kein Objekt lokalisiert!');
                success = 0;
            end
            
            
        end
      
        % Unterdrucksensor �berpr�fen, ob Objekt an Sauger h�ngt
        function status = checkPressureSensor(this)
            % Hier sollte der Drucksensor ausgelesen werden
            % 1: Objekt h�ngt am Sauger    0: Objekt h�ngt nicht am Sauger
            status = bitget(this.cANbus.msg_robot,4);
            
%             status = input('Robot.m --> checkPressureSensor(): ');
        end
 
         % Unterdrucksensor �berpr�fen, ob Objekt an Sauger h�ngt
        function status = checkLightBarrier1(this)
            % Hier sollte der Drucksensor ausgelesen werden
            % 1: Objekt h�ngt am Sauger    0: Objekt h�ngt nicht am Sauger
            status = bitget(this.cANbus.msg_robot,5);
            
%             status = input('Robot.m --> checkPressureSensor(): ');
        end       
        
        % Vakuumsauger ein- bzw. ausschalten
        function switchVacuum(this, status)
            % status = 1: Vakuum anschalten
            % status = 0: Vakuum ausschalten
            switch status
                case 1
                    % Vakuumpumpe einschalten
                    this.cANbus.sendMsg(515,1);
                case 0
                    % Vakuumpumpe ausschalten
                    this.cANbus.sendMsg(515,0);
                otherwise
                    % Fehlerbehandlung
                    error('Roboter.m --> Fehler beim Schalten des Vakuums');
            end
        end
        
        % Versuche Objekt zu heben
        % Parameter:    x, y des Objekts in Roboter-Koordinaten
        % R�ckgabe:     status = 1, wenn Objekt gehoben werden konnte, 
        %               status = 0, wenn Objekt nicht gehoben werden konnte
        function status = liftObject(this, xObj, yObj)
            objPosition = [yObj xObj 57 180 0 0]; 
            liftPosition = [yObj xObj 107 180 0 0]; 
            
            this.move(liftPosition);            % 5 cm �ber das Objekt fahren
            
            % Versuche 3x das Objekt zu heben
            for i = 1:3      
                this.move(objPosition);         % Fahre Sauger auf Objekt
                this.switchVacuum(1);           % Schalte Vakuum ein
                this.move(liftPosition);        % Hebe Objekt hoch
                if this.checkPressureSensor()   % Falls Objekt noch am Sauger h�ngt
                    status = 1;                 % Anheben hat funktioniert
                    disp('Robot.m --> Anheben hat funktioniert');
                    break;                      % Schleife abbrechen
                else                            % falls Objekt nicht am Sauger h�ngt
                    this.switchVacuum(0);       % Vakuum ausschalten
                    status = 0;                 % Anheben hat nicht funkioniert
                end
            end
            
        end
        
        % Fahre Objekt in Anlage
        function success = moveObject(this)
            % Wegpunkte f�r Verfahrweg definieren
%             wp{1} = [91 -332 500 180 0 0];          % Pose: Hochfahren
%             wp{2} = [175 -425 500 -135 -120 0];     % Pose: Drehen zu Rampe 1
%             wp{3} = [550 60 500 0 -180 0];          % Pose: Drehen zu Rampe 2
            wp{1} = [90 -332 644 -177 -29 0];        % Pose: Hochfahren
            wp{2} = [400 94 760 -17 177 0];          % Pose: Drehen zu Rampe
            wp{3} = [528 41 385 -15  167 0];         % Pose: Einfahren in Rampe
                    
            % Webpunkte der Reihe nach abfahren
            for k = 1:length(wp)
                curWP = wp{k};          % aktueller Wegpunkt
                this.move(curWP);       % zu aktuellem Wegpunkt fahren
                
                if this.checkPressureSensor()   % Falls Objekt noch am Sauger h�ngt
                    success = 1;                 % Objekt h�ngt noch am Sauger   
                else                            % falls Objekt nicht am Sauger h�ngt
                    this.switchVacuum(0);       % Vakuum ausschalten
                    success = 0;                 % R�ckmeldung, dass Objekt verloren wurde
                    this.returnHome();          % Fahre zur�ck in die Home-Position
                    break;                      % Schleife abbrechen
                end
            end
            
            % Messsystem informieren, dass gleich ein Objekt kommt und der
            % Messprozess gestartet werden kann
            this.startMeasurement();
%             pause(0.5);
            
            if (success)
                % Objekt in Anlage ablegen
                this.cANbus.sendMsg(517,1);
                pause(1)
                this.switchVacuum(0);           % Vakuum zum Ablegen ausschalten
                pause(3)
                this.cANbus.sendMsg(517,0);
            end
        end
        
        % Fahre von Ablageposition zur�ck in Home-Position
        function returnHome(this)
                        
            if isequal(round(this.readPose()), [528 41 385 -15  167 0])
                wp = [400 94 760 -17 177 0];         % Pose: Aus Rampe hochfahren
                this.move(wp);                      % Fahre zur Pose
                wp = [90 -332 644 -177 -29 0];
                this.move(wp);
            end
            
            if isequal(round(this.readPose()), [400 94 760 -17 177 0])
                wp = [90 -332 644 -177 -29 0];      
                this.move(wp);                      % Fahre zur Pose
            end
            
            % Greifer schlie�en, dass er nicht im Weg steht
            this.gripper.close();
            
            this.home();                        % Fahre zu Home-Position
            
        end
        
        % Geschwindigkeit des Roboters einstellen
        function setSpeed(this, speed)
            this.speed = speed;
        end
        
        % Nachricht senden, dass Messsystem mit dem Messprozess beginnen
        % kann
        function startMeasurement(this)
            
        end
 
        
        
   
        
        function status = liftObjectGripper(this, xObj, yObj)
            status = 1;
            objPosition = [yObj xObj 105 180 0 0]; 
            liftPosition = [yObj xObj 250 180 0 0]; 
            
            this.gripper.open();
            this.move(objPosition);
            pause(5)% 5 cm �ber das Objekt fahren
            this.gripper.close();
            pause(0.5);
            this.move(liftPosition);

        end
        
        function success = moveObjectGripper(this)
            success = 1;
            % Wegpunkte f�r Verfahrweg definieren
            wp{1} = [90 -332 644 -177 -29 0];        % Pose: Hochfahren
            wp{2} = [400 94 760 -17 177 0];          % Pose: Drehen zu Rampe
            wp{3} = [528 41 385 -15  167 0];         % Pose: Einfahren in Rampe
            
            % Webpunkte der Reihe nach abfahren
            for k = 1:length(wp)
                curWP = wp{k};          % aktueller Wegpunkt
                this.move(curWP);       % zu aktuellem Wegpunkt fahren
                
                if ~this.gripper.checkContact()  % Falls Objekt noch am Greifer h�ngt
                    success = 1;                 % Objekt h�ngt noch am Greifer   
                else                             % falls Objekt nicht am Greifer h�ngt
                    success = 0;                 % R�ckmeldung, dass Objekt verloren wurde
                    this.returnHome();           % Fahre zur�ck in die Home-Position
                    break;                       % Schleife abbrechen
                end
            end
            
            
            if (success)
                % Objekt in Anlage ablegen
                this.gripper.open();
            end
        end
                
        function success = feedObjectGripper(this)
            success = 1;
            % Stelle sicher, das Roboter in Home-Position ist
            this.home();
            % Lokalisiere Objekte auf Objekttisch und finde Koordinaten vom
            % gr��ten Objekt
            [xObj, yObj, locSuccess] = this.objDetection.locateObject();
            
            if (locSuccess)           % Falls ein Objekt lokalisiert wurde
                % Objekt anheben
                if (~this.liftObjectGripper(xObj, yObj))     % Falls Objekt nicht angehoben werden kann
                    this.sweep();                     % kehre Objekttisch ab
                    success = 0;
                else
                    % Objekt transportieren
                    if (~this.moveObjectGripper())         % Falls Objekt nicht transportiert werden konnte
                        this.sweep();               % kehre Objekttisch ab
                        success = 0;
                    else
                        this.returnHome();          % Fahre Roboter zur�ck in die Home-Position
                    end
                end
                
                
            else
                disp('Robot.m --> kein Objekt lokalisiert!');
                success = 0;
            end
            
            
        end
             
    end
    
    events
    end
end