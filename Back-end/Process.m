classdef Process < StateObject
    % Process wird als �berklasse f�r den gesamten Prozess in der Messanlage verwendet 
    
    % Verwendete Module und Subklassen
    properties        
        isoDevice;      % Vereinzelungsanlage inkl. F�rderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. F�rderband, Waage und Kamera
        cANbus;
        mega;
    end
    
    % F�r den Nutzer nicht sichtbare EventListener
    properties (Hidden)
        handoff_request_listener;
        handoff_accept_listener;
    end
    
    % Beobachtbare Zust�nde
    properties (SetObservable)
        remaining_iterations = 0;
    end
    
    methods
        % Erstellt das Objekt
        function this = Process(logger)   
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            this.cANbus = CANbus(this.logger);
            this.measSystem = MeasuringSystem(this.logger);
            this.isoDevice = IsolationDevice(this.logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this)
            this.logger.info('Prozessinitialisierung gestartet...'); 
            % Baut Verbindung zum Prozess selbst auf
            this.mega = createMega();
            this.cANbus.init()
            this.measSystem.init(this.cANbus,this.mega)
            this.isoDevice.init(this.cANbus,this.mega)
            
            this.handoff_request_listener = addlistener(this.isoDevice.robot,'Handoff_Request',@(~,~)this.measSystem.prepareMeasurement);
            this.handoff_accept_listener = addlistener(this.measSystem,'Handoff_Accept',@(~,~)this.isoDevice.robot.releaseObject);
            
            this.setStateInactive('Initialisiert');
            % Da Process die Top-Level Klasse ist wird hier auch auf dem INFO Level geloggt
            this.logger.info('Prozessinitialisierung abgeschlossen'); 
            try
                loadSettings();
            catch
                this.logger.warning('"Einstellungen laden" fehlgeschlagen, verwende Standarteinstellungen'); 
            end
        end
        
        % F�hrt den Prozess f�r eine Anzahl von Iterationen aus
        function run(this, num_iterations)
            if nargin < 2
                num_iterations = 1;
            end
            this.remaining_iterations = num_iterations;
            this.logger.info(['Prozess gestartet f�r ', num2str(num_iterations) ,' Iterationen']);
            while this.remaining_iterations > 0
                this.setStateActive('Objekt Isolieren');
                [success, error] = this.isoDevice.isolateObject();      % Versuche ein Objekt dem Messsystem zuzuf�hren
                if (success)                                            % Falls das geklappt hat   
                    this.setStateActive('Objekt Messen');
                    [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuf�hren    
                    disp('measuring')
                    if (~success)                                       % Falls das nicht geklappt hat
                        this.logger.warning('Fehler bei der Messung');   % gibt eine Fehlermeldung aus
                    end
                else                                                    % Falls die Zuf�hrung nicht geklappt hat
                    this.logger.warning('Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
                end
                this.logger.info(['Iteration ', num2str(this.remaining_iterations) ,' abgeschlossen']);
                this.remaining_iterations = this.remaining_iterations - 1;
            end
            this.setStateInactive('Betriebsbereit');
            this.logger.info(['Prozess abgeschlossen']);
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.isoDevice.getState(),...
                        this.measSystem.getState(),...
                        this.cANbus.getState()];
                    if any(sub_system_states == this.ERROR)
                        this.changeStateError('Fehler im Subsystem')
                    end                
                end
            catch
                this.changeStateError('Fehler bei der Zustandsaktualisierung')
            end
        end
        
        % Reaktion des Objektes auf Zustands�nderung
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
end