classdef Process < StateObject
    % Process wird als �berklasse f�r den gesamten Prozess in der Messanlage verwendet 
    
    
    properties        
        isoDevice;      % Vereinzelungsanlage inkl. F�rderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. R�derband, Waage und Kamera
        cANbus;
    end
    
    properties (SetObservable)
        remaining_iterations
    end
    
    methods
        function this = Process(logger)   
            % Erzeugt eine Instanz der Klasse Process
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            this.mega = createMega();
            this.cANbus = CANbus(this.logger);
            this.measSystem = MeasuringSystem(this.logger,mega);
            this.isoDevice = IsolationDevice(this.logger,mega);
        end
        
        function init(this)
            % Baut Verbindung zum Prozess selbst auf
            this.cANbus.init()
            this.measSystem.init(this.cANbus)
            this.isoDevice.init(this.cANbus)
            
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
                    this.measSystem.startConvBelt
                        pause(2)
                    this.measSystem.stopConvBelt
%                     this.setStateActive('Objekt Messen');
%                     [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuf�hren    
%                     if (~success)                                       % Falls das nicht geklappt hat
%                         this.logger.warning('Fehler bei der Messung');   % gibt eine Fehlermeldung aus
%                     end
%                 else                                                    % Falls die Zuf�hrung nicht geklappt hat
%                     this.logger.warning('Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
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