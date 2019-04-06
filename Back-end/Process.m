classdef Process < StateObject
    % Process wird als Überklasse für den gesamten Prozess in der Messanlage verwendet 
    
    
    properties
        logger;
        
        isoDevice;      % Vereinzelungsanlage inkl. Förderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. Röderband, Waage und Kamera
        cANbus;
    end
    
    methods
        function this = Process(varargin)   
            % Erzeugt eine Instanz der Klasse Process
            this = this@StateObject();
            
            if nargin < 1
                try
                    this.logger = Logger.Logger();
                catch % Falls Logger nicht vorhanden ist, wird jeder Aufruf zu disp() umgelenkt
                    this.logger.debug = @disp;
                    this.logger.info = @disp;
                    this.logger.warning = @disp;
                    this.logger.error = @disp;
                end
            else
                this.logger = logger;
            end
        end
        
        function init(this)
            % Baut Verbindung zum Prozess selbst auf
            this.cANbus = CANbus();
            this.measSystem = MeasuringSystem(this.cANbus);
            this.isoDevice = IsolationDevice(this.cANbus);
            this.cANbus.init()
            this.measSystem.init()
            this.isoDevice.init()
            
            this.setStateOnline('Initialisiert');
        end
        
        function run(this, num_iterations)
            this.logger.info(['Prozess gestartet für ', num2str(num_iterations) ,' Iterationen']);
            for i=1:num_iterations
                this.setStateActive('Objekt Isolieren');
                [success, error] = this.isoDevice.isolateObject();      % Versuche ein Objekt dem Messsystem zuzuführen
                if (success)                                            % Falls das geklappt hat   
                    this.setStateActive('Objekt Messen');
                    [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuführen    
                    if (~success)                                       % Falls das nicht geklappt hat
                        this.logger.warning('Fehler bei der Messung');   % gibt eine Fehlermeldung aus
                    end
                else                                                    % Falls die Zuführung nicht geklappt hat
                    this.logger.warning('Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
                end
            end
            this.logger.info(['Iteration ', num2str(i) ,' abgeschlossen']);
            this.setStateOnline('Objekt Isolieren');
        end
    end
    
    events
    end
end