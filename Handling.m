classdef Handling < handle
    
    properties
        cANbus;
        cam;
        paperObject;
        scale;
        
        % Speichert die erfassten Sensordaten des Roboters
        % 1 = Förderband Request des Roboters
        % 2 = Objekt erkannt
        % 3 = Position erreicht
        % 4 = Drucksensor
        % 5 = Lichtschranke 1
        status_robot = de2bi(0,5);
        
        % Übersetzt die einzelnen Bits der Robototersensordaten in 
        % einzelne Variablen
        convRequested = 0;
        objDetected = 0;
        posReached = 0;
        vacSensorOn = 0;
        ls1Blocked = 0;
        
        % Speichert die erfassten Sensordaten des Messsystems
        % 5 = Lichtschranke 2
        status_meas = de2bi(0,8);
        
        % Übersetzt die Messsystemsensordaten in 
        % einzelne Variablen
        ls2Blocked = 0;
        
        status = 20;             % Gibt den Prozessschritt an, der aktuell bearbeitet wird
        last_status = 1;        % Speichert den letzten Prozessschritt
        
        status_conv = 0;        % Gibt den Status des Förderbands an
        
        listenerStatRobot;      % Listenerevent für Statusänderungen des Roboters
        listenerStatMeasure;    % Listenerevent für Statusänderungen des Messsystems 
        
        try_nr_detect = 0;      % Versuchszähler, der in Prozessschritt 4 verwendet wird
        try_nr_detect_limit = 20;   % Anzahl an Versuchen, die maximal in Prozessschritt 4 durchgeführt werden
        try_nr_pressure = 0;    % Versuchszähler, der in Prozessschritt 5 verwendet wird
        try_nr_pressure_limit = 3;  % Anzahl an Versuchen, die maximal in Prozessschritt 4 durchgeführt werden
        
        counter_status1 = 0;        % Zeitzähler, der in Prozessschritt 1 verwendet wird
        counter_status2 = 0;        % Zeitzähler, der in Prozessschritt 2 verwendet wird
        counter_status2_limit = 20;
        counter_status3 = 0;        % Zeitzähler, der in Prozessschritt 3 verwendet wird
        counter_status6 = 0;        % Zeitzähler, der in Prozessschritt 6 verwendet wird
        counter_status8 = 0;        % Zeitzähler, der in Prozessschritt 8 verwendet wird
        counter_status9 = 0;        % Zeitzähler, der in Prozessschritt 9 verwendet wird
        counter_status10 = 0;       % Zeitzähler, der in Prozessschritt 10 verwendet wird
        
        errorcode = 0;          % Speichert den Fehlercode zur Behandlung in Prozessschritt 66
        errorhandling = 0;      % Wird aktiviert, wenn Errorhandlig in Prozessschritt 66 aktiv ist
    end
    
    methods
        % Konstruktor
        function this = Handling()
            this.cANbus = CANbus();
            this.paperObject = PaperObject(this);
            this.scale = Scale('COM7', this.paperObject);
            this.listenerStatRobot = addlistener(this.cANbus,'Status_Robot_Changed',@this.analyseStatus1);
            this.listenerStatMeasure = addlistener(this.cANbus,'Status_Measure_Changed',@this.analyseStatus2);
            disp('Handling.m --> Vor dem Starten bitte die Ablaufsteuerung des Roboters aktivieren');
        end
        
        % Destruktor
        function delete(this)
            delete(this.cANbus);
        end
        
        % Startet das Förderband
        function startConv(this)
            this.cANbus.sendMsg(000,1);
            this.status_conv = 1;
            
        end
        
        % Stoppt das Förderband
        function stopConv(this)
            this.cANbus.sendMsg(000,0);
            this.status_conv = 0;
        end
        
        % Startet die Sendung eines allgemeinen OK Signals
        function sendOKSignal(this)
            this.cANbus.sendMsg(000,2);
%             disp('Handling.m --> OK-Signal gesendet');
        end
        
        % Startet die Sendung eines Reset Signals
        function sendResetSignal(this)
            this.cANbus.sendMsg(000,4);
            disp('Handling.m --> Reset-Signal gesendet');
        end
        
        % Stoppt alle Signalsendungen
        function stopSignal(this)
            this.cANbus.sendMsg(000,0);
%             disp('Handling.m --> Stop-Signal gesendet');
        end
        
        % Startet die Messaufnahme
        function startScaleConvBelt(this)
            this.cANbus.sendMsg(001,1);

        end
        
        function stopScaleConvBelt(this)
            this.cANbus.sendMsg(001,0);  % Waage Fernstart aus

        end
        
        % Verwirft die folgenden Messwerte
        function dropMeasurement(this)
            
        end
        
        % Stoppt den Ablauf, springt in den Fehlerzustand
        function stop(this)
            this.status = 66;
            this.cANbus.sendMsg(001,0);
            this.errorhandling = 1;
            this.stopConv();
        end
        
        % Startet den Ablauf
        function start(this)
            this.reset;
            this.nextStatus(1);
            
            disp('Handling.m --> Start durchgeführt');
        end
        
        
        % Steuert die Versuchsreihe, um ein Objekt in eine detektierbare
        % Position zu bringen
        function tryDetecting(this)
            switch this.try_nr_detect
                case 1 % Starte Förderband für 1 Schritt (1 Schritt = 500ms)
                    this.startConv();
                case 2 % Stoppe Förderband für 6 Schritte (Versuche Objekterkennung)
                    this.stopConv();
                    this.sendOKSignal(); % Starte Objekterkennung
                case 8 % Starte Förderband für 3 Schritte
                    this.stopSignal();  % Stoppe Objekterkennung
                    this.startConv();
                case 11 % Stoppe Förderband für n (Standard = 9) Schritte (Versuche Objekterkennung)
                    this.stopConv();
                    this.sendOKSignal(); % Starte Objekterkennung
                case this.try_nr_detect_limit % Es konnte kein Objekt identifiziert werden
                    this.stopSignal();  % Stoppe Objekterkennung
                    this.nextStatus(66);
                    this.errorcode = 041;
            end
        end
        
        % Steuert die Versuchsreihe, umd ein Objekt anzuheben
        function tryLifting(this)
            disp('Handling.m --> Versuche, Objekt anzuheben');
            if this.try_nr_pressure < this.try_nr_pressure_limit
                this.nextStatus(3);
            else
                this.nextStatus(66);
                this.errorcode = 051;
            end
        end
        
        % Aktualisiert den Prozessstatus des Ablaufs
        function nextStatus(this, newStatus)
            this.status = newStatus;
        end
        
        % Setzt alle Variablen wieder in den Anfangszustand
        function reset(this)
            disp('Handling.m --> Reset durchgeführt');
            
%             this.status_robot = de2bi(0,5);
%             this.status_meas = de2bi(0,8);
            this.status = 20;
            this.last_status = 1;
            this.try_nr_detect = 0;
            this.try_nr_pressure = 0;
            this.counter_status1 = 0;
            this.counter_status2 = 0;
            this.counter_status3 = 0;
            this.counter_status6 = 0;
            this.counter_status8 = 0;
            this.counter_status9 = 0;
            this.counter_status10 = 0;
            this.errorcode = 0;
            this.errorhandling = 0;
%             this.convRequested = 0;
%             this.objDetected = 0;
%             this.posReached = 0;
%             this.vacSensorOn = 0;
%             this.ls1Blocked = 0;
%             this.ls2Blocked = 0;
            
            this.stopSignal();
            
        end
        
        % Teilt die letzte Statusnachricht von MM0 (Roboter) in einzelne Sensordaten
        % Wird zyklisch (500ms) oder bei Änderung eines Status' ausgeführt
        function analyseStatus1(this, eventObj, event)
            
            this.status_robot = de2bi(this.cANbus.msg_robot,8);

            this.convRequested = bitget(this.cANbus.msg_robot,1);
            this.objDetected = bitget(this.cANbus.msg_robot,2);
            this.posReached = bitget(this.cANbus.msg_robot,3);
            this.vacSensorOn = bitget(this.cANbus.msg_robot,4);
            this.ls1Blocked = bitget(this.cANbus.msg_robot,5);
            
            
            if this.errorhandling == 0
                this.doSomething();
            else
                this.handleProblem();
            end
        end
        
        % Teilt die letzte Statusnachricht von MM1 (Messsystem) in einzelne Sensordaten
        % Wird zyklisch (500ms) ausgeführt
        function analyseStatus2(this, eventObj, event)
            this.status_meas = de2bi(this.cANbus.msg_meas,8);
            if this.cANbus.msg_meas == 16
                this.ls2Blocked = 1;
            else
                this.ls2Blocked = 0;
            end
            
            if this.errorhandling == 0
                this.doSomething();
            else
                this.handleProblem();
            end
        end
        
        % Steuert den Ablauf
        % Wird von analyseStatus1 zyklisch (500ms) aufgerufen
        function doSomething(this)
            
            if (this.last_status ~= this.status)
                disp('Status System');
                disp(this.status);
                this.last_status = this.status;
            end
            
%             disp(this.status_robot);
%             disp(this.status_meas);
%              disp(this.cANbus.msg_meas);
%             disp('Objekt erkannt');
%             disp(this.objDetected);
%             disp('Position erreicht');
%             disp(this.posReached);
            
            switch this.status
                case 1 % Startzustand. Warten auf erstes Objekt
                    if this.ls1Blocked == 1 % Signal der Lichtschranke
                        % Stoppe das Laufband mit leichter Verzögerung, damit das Objekt zu einem größereren Teil im Erkennungsbereich der Kamera liegt
                        pause(0.2);
                        this.stopConv();
                        % Wartezeit, damit das Objekt ruhig liegt.
                        pause(0.2);
                        this.nextStatus(2);
                        this.counter_status1 = 0;
                    elseif (this.counter_status1 < 100 && this.status_conv == 1) % (entspricht 100x500ms = 50s)
                        this.counter_status1 = this.counter_status1 +1;
                    elseif this.status_conv == 1 % Wenn die Lichtschranke für 50s nicht unterbrochen wurde, ist das Laufband leer oder funktionsunfähig
                        this.status = 66; % Fehlerzustand
                        this.errorcode = 011;
                    end
                    
                case 2 % Objekt liegt bereit. Warten auf Objekterkennung.
                    this.sendOKSignal(); % Gibt das Signal, um die Objekterkennung zu starten
                    if this.counter_status2 < this.counter_status2_limit % Standard = 10s
                        this.counter_status2 = this.counter_status2 +1;
                        if this.counter_status2 > 3 && this.counter_status2 < 6 % Das OK-Signal wird erst zeitverzögert gestoppt, um dem Roboter genügend Zeit zur Erkennung des Signals zu geben
                            this.stopSignal();
                        end
                    else
                        this.stopSignal();
                        this.nextStatus(4);
                    end
                    
                    if this.objDetected == 1 % Signal der Robotersteuerung, dass ein Objekt erkannt wurde
                        this.nextStatus(3);
                    end
                    
                case 3 % Objekt wurde erkannt. Warten auf Signal "Roboter in Position"
                    if this.posReached == 1 % Roboter hat Zwischenposition erreicht
                        this.nextStatus(5);
                        this.stopSignal();  % Hält die Objekterkennung an
                    elseif this.counter_status3 < 200 % Entspricht 100s
                        this.counter_status3 = this.counter_status3 + 1;
                    else % Roboter hat Zeitlimit überschritten
                        this.nextStatus(66);
                        this.errorcode = 031;
                    end
                    
                case 4 % Versuchszustand, um Objekt erkennbar zu machen
                    if this.objDetected == 1 % Robotersteuerung hat Ojekt erkannt
                        this.stopConv()
                        this.nextStatus(3);
                    else
                        this.try_nr_detect = this.try_nr_detect +1;
                        this.tryDetecting();
                    end
                    
                case 5 % Versuch, Objekt anzuheben. Warte auf Drucksensor
                    if this.vacSensorOn == 1 % Drucksensor bestätigt, dass ein Objekt am Roboterarm hängt
                        this.sendOKSignal();
                        this.nextStatus(6);
                    else
                        this.try_nr_pressure = this.try_nr_pressure + 1;
                        this.tryLifting();
                    end
                    
                case 6 % Objekt wurde vom Roboter erfolgreich angehoben. Warte auf Bestätigung, dass Roboter über Messsystem angekommen ist
                    this.startScaleConvBelt();
                    if this.counter_status6 > 4  % Das OK-Signal wird erst zeitverzögert gestoppt, um dem Roboter genügend Zeit zur Erkennung des Signals zu geben
                        this.stopSignal();
                    end
                    
                    if ((this.counter_status6 > 6) && (this.posReached == 1)) % Kontrolliert erst nach 6 Zeitschritten (3s) den Status. Ansonsten Überspringen der Phase fälschlicherweise möglich
                        this.nextStatus(7);
                    elseif this.counter_status6 < 100 % Entspricht 50s
                        this.counter_status6 = this.counter_status6 + 1;
                    else
                        this.nextStatus(66);
                        this.errorcode = 061;
                    end
                    
                case 7 % Roboter hält über Messsystem. Kontrolliert Drucksensor und LS2
                    if ((this.vacSensorOn == 1) && this.ls2Blocked == 0) % Objekt hängt noch an Roboter, LS2 ist frei
                        this.nextStatus(8);
                        this.sendOKSignal();
                    elseif this.vacSensorOn == 0 % Kein Signal vom Drucksensor mehr, Objekt wahrscheinlich auf dem Weg verloren.
                        % Trotzdem wird möglicherweise Messung getriggert
                        this.nextStatus(66);
                        this.errorcode = 071;
                    elseif this.ls2Blocked == 1 % Es hängt noch ein anderes Objekt in Lichtschranke 2 fest
                        this.nextStatus(66);
                        this.errorcode = 072;
                    end
                    
                case 8 % Objekt wurde im Messsystem abgelegt
                    if this.cANbus.msg_meas == 16 % Lichtschranke 2 wurde unterbrochen
                        this.nextStatus(9);
                        this.sendOKSignal();
                        
                    elseif this.counter_status8 < 15 % Entsprechen 7s Wartezeit
                        this.counter_status8 = this.counter_status8 + 1;
                        if this.counter_status8 > 2 && this.counter_status8 < 5 %% Sendet nach 2s das Stop-Signal
                            this.stopSignal();
                        end
                    else    % Es wurde kein Objekt von Lichtschranke 2 erkannt. Objekt hängt wahrscheinlich vor LS2 fest
                        this.nextStatus(66);
                        this.errorcode = 081;
                        this.dropMeasurement();
                    end
                    
                case 9  % Kontrolliert, ob LS2 nur kurz oder dauerhaft blockiert wurde
%                     this.stopScaleConvBelt();
                    notify(this,'Measure');
                    disp('Handling.m --> Ich bin hier');
                    if this.cANbus.msg_meas == 0 % Objekt hat Lichtschranke 2 passiert
                        this.nextStatus(10);
                    elseif this.counter_status9 < 10 % Entsprechen 5s Wartezeit
                        this.counter_status9 = this.counter_status9 + 1;
                    else
                        this.nextStatus(66);
                        this.errorcode = 091;
                        this.dropMeasurement();
                    end
                    
                case 10 % Wartet auf Bestätigung, dass Roboter wieder in Grundstellung angekommen ist
                    this.stopScaleConvBelt();
                    if this.posReached == 1
                        this.nextStatus(11);
                    elseif this.counter_status10 < 100 % Entsprechen 50s Wartezeit
                        this.counter_status10 = this.counter_status10 + 1;
                    else
                        this.nextStatus(66);
                        this.errorcode = 101;
                    end
                    
                case 11 % Führt Reset der Prozesskette durch
                    this.start;
                    if this.ls1Blocked == 0
                        this.startConv;
                    end
                    disp('Status System');
                    disp(this.status);
                    
                case 20 % Wartezustand
                    
                case 66 % Fehlerzustand. Execute Order 66
                    this.stopConv();
                    this.errorhandling = 1;
                    
                    % Fehlerbenachrichtigung
                    switch this.errorcode
                        case 0 % Unbekannter Fehler
                            disp('error 0 --> Manueller Abbruch / Unbekannter Fehler');
                            this.stop;
                            
                        case 011 % Timeout in Status 1
                            disp('error 011 --> Keine neuen Objekte detektiert. Förderband ist leer');
                            this.stop;
                            
                        case 031 % Timeout in Status 3
                            disp('error 031 --> Zeitlimit bei Objektaufnahme überschritten');
                            this.stop;
                            
                        case 041 % Versuchslimit für Objekterkennung überschritten
                            disp('error 041 --> Kein Objekt identifizierbar');                           
                            disp('Handling.m --> Nicht behandelbare Objekte werden von der Ablage entfernt');
                            this.sendResetSignal;
                            
                        case 051 % Versuchslimit für Objektanhebung überschritten
                            disp('error 051 --> Objekt konnte nicht angehoben werden');
                            disp('Handling.m --> Nicht behandelbare Objekte werden von der Ablage entfernt');
                            this.sendResetSignal();
                            
                        case 061 % Zeitlimit für Objekttransport von Förderband zu Messsystem überschritten
                            disp('error 061 --> Zeitlimit für Objekttransport überschritten');
                            this.stop;
                            
                        case 071 % Drucksensor hat bei Ankunft an Messsystem kein Signal mehr
                            disp('error 071 --> Objekt vor Messsystem verloren');
                            this.sendResetSignal();
                            this.stopScaleConvBelt();
                            
                        case 072 % Lichtschranke 2 wird noch von einem anderen Objekt blockiert
                            disp('error 072 --> Lichtschranke 2 durch anderes Objekt blockiert');
                            this.sendOKSignal();
                            
                        case 081 % Lichtschranke 2 wird nicht ausgelöst, obwohl Objekt vermeintlich im Messsystem abgelegt wurde
                            disp('error 081 --> Objekt hängt vor Lichtschranke 2 fest oder wurde beim Transport verloren');
                            disp('error 081 --> Objekt entfernen');
                            this.stop;
                            
                        case 091 % Lichtschranke 2 dauerhaft blockiert, nachdem Objekt im Messsystem abgelegt wurde
                            disp('error 091 --> Objekt hängt in Lichtschranke 2 fest. Objekt entfernen.');
                            
                        case 101 % Zeitlimit für Rückkehr des Roboters in Grundstellung überschritten
                            disp('error101 --> Zeitlimit für Rückkehr in Grundstellung überschritten');
                            
                    end
            end
        end
        
        % Wird aufgerufen, wenn ein Problem behandelt werden muss
        function handleProblem(this)
            switch this.errorcode
                case 041 % Objekterkennung fehlgeschlagen
                    if this.posReached == 1 % Roboter gibt Signal, dass Reinigungsvorgang beendet ist
                        this.reset;
                        this.start;
                        if this.ls1Blocked == 0 % Wenn kein Objekt LS1 blockiert, starte das Conveyor Belt
                            this.startConv();
                        end
                        disp('Handling.m --> Kehrvorgang wurde abgeschlossen');
                    end
                    
                case 051 % Objektanhebung fehlgeschlagen
                    if this.posReached == 1 % Roboter gibt Signal, dass Reinigungsvorgang beendet ist
                        this.stopSignal;
                        this.reset;
                        this.start;
                        if this.ls1Blocked == 0 % Wenn kein Objekt LS1 blockiert, starte das Conveyor Belt
                            this.startConv();
                        end
                        disp('Handling.m --> Kehrvorgang wurde abgeschlossen');
                    end
                    
                case 071
                    if this.posReached == 1 % Roboter gibt Signal, dass er wieder in Grundstellung angekommen ist
                        this.stop;
                        this.start;
                        if this.ls1Blocked == 0 % Wenn kein Objekt LS1 blockiert, starte das Conveyor Belt
                            this.startConv();
                        end
                        disp('Handling.m --> Grundstellung erreicht. Ablauf wurde gestartet');
                    end
                    
                case 072
                    if this.posReached == 1 % Roboter gibt Signal, dass er wieder in Grundstellung angekommen ist
                        this.stopSignal();
                        this.stop;
                        disp('Handling.m --> Grundstellung erreicht.')
                        disp('Objekte aus Lichtschranke 2 entfernen. Danach Reset der Steuerung durchführen');
                    end
            end
        end
    end
    
    events
        Status_Robot_Changed
        Status_Measure_Changed
        Measure
    end
end

