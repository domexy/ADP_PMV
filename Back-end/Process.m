classdef Process < StateObject
    % Process wird als �berklasse f�r den gesamten Prozess in der Messanlage verwendet 
    
    
    properties
        logger;
        
        isoDevice;      % Vereinzelungsanlage inkl. F�rderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. R�derband, Waage und Kamera
        cANbus;
    end
    
    methods
        function this = Process(logger)   
            % Erzeugt eine Instanz der Klasse Process
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this)
            % Baut Verbindung zum Prozess selbst auf
            this.cANbus = CANbus(this.logger);
            this.measSystem = MeasuringSystem(this.logger);
            this.isoDevice = IsolationDevice(this.logger);
            this.cANbus.init()
            this.measSystem.init(this.cANbus)
            this.isoDevice.init(this.cANbus)
            
            this.setStateOnline('Initialisiert');
        end
        
        function run(this, num_iterations)
            this.logger.info(['Prozess gestartet f�r ', num2str(num_iterations) ,' Iterationen']);
            for i=1:num_iterations
                this.setStateActive('Objekt Isolieren');
                [success, error] = this.isoDevice.isolateObject();      % Versuche ein Objekt dem Messsystem zuzuf�hren
                if (success)                                            % Falls das geklappt hat   
                    this.setStateActive('Objekt Messen');
                    [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuf�hren    
                    if (~success)                                       % Falls das nicht geklappt hat
                        this.logger.warning('Fehler bei der Messung');   % gibt eine Fehlermeldung aus
                    end
                else                                                    % Falls die Zuf�hrung nicht geklappt hat
                    this.logger.warning('Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
                end
            end
            this.logger.info(['Iteration ', num2str(i) ,' abgeschlossen']);
            this.setStateOnline('Betriebsbereit');
        end
    end
end