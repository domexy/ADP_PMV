classdef Process < StateObject
    % Process wird als �berklasse f�r den gesamten Prozess in der Messanlage verwendet 
    
    
    properties        
        isoDevice;      % Vereinzelungsanlage inkl. F�rderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. R�derband, Waage und Kamera
        cANbus;
        mega;
        handoff_request_listener;
        handoff_accept_listener;
    end
    
    properties (SetObservable)
        remaining_iterations = 0;
    end
    
    methods
        function this = Process(logger)   
            % Erzeugt eine Instanz der Klasse Process
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            this.cANbus = CANbus(this.logger);
            this.measSystem = MeasuringSystem(this.logger);
            this.isoDevice = IsolationDevice(this.logger);
        end
        
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
        
        function run(this, num_iterations)
            if nargin < 2
                num_iterations = 1;
            end
            this.remaining_iterations = num_iterations;
            this.logger.info(['Prozess gestartet f�r ', num2str(num_iterations) ,' Iterationen']);
            for i=1:num_iterations
                this.setStateActive('Objekt Isolieren');
                [success, error] = this.isoDevice.isolateObject();      % Versuche ein Objekt dem Messsystem zuzuf�hren
                if (success)                                            % Falls das geklappt hat   
                    this.setStateActive('Objekt Messen');
%                     [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuf�hren    
                    disp('measuring')
                    if (~success)                                       % Falls das nicht geklappt hat
                        this.logger.warning('Fehler bei der Messung');   % gibt eine Fehlermeldung aus
                    end
                else                                                    % Falls die Zuf�hrung nicht geklappt hat
                    this.logger.warning('Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
                end
                this.remaining_iterations = this.remaining_iterations - 1;
                this.logger.info(['Iteration ', num2str(i) ,' abgeschlossen']);
            end
            this.setStateInactive('Betriebsbereit');
            this.logger.info(['Prozess abgeschlossen']);
        end
        
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
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
end