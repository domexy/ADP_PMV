classdef Process < handle
    % Process wird als �berklasse f�r den gesamten Prozess in der Messanlage verwendet 
    
    
    properties
        isoDevice;      % Vereinzelungsanlage inkl. F�rderband, Objekterkennung und Roboter
        measSystem;     % Messystem inkl. R�derband, Waage und Kamera
        cANbus;
    end
    
    methods
        function this = Process()
            % Erzeugt eine Instanz der Klasse Process
            this.cANbus = CANbus();
            this.measSystem = MeasuringSystem(this.cANbus);
            this.isoDevice = IsolationDevice(this.cANbus);
        end
        
        function run(this)
            for i=1:1
                [success, error] = this.isoDevice.isolateObject();      % Versuche ein Objekt dem Messsystem zuzuf�hren
                if (success)                                            % Falls das geklappt hat   
                    [success, error] = this.measSystem.measure();       % Versuche die Messung durchzuf�hren    
                    if (~success)                                       % Falls das nicht geklappt hat
                        disp('Process.m --> Fehler bei der Messung');   % gibt eine Fehlermeldung aus
                    end
                else                                                    % Falls die Zuf�hrung nicht geklappt hat
                    disp('Process.m --> Fehler bei der Vereinzelung');  % gibt eine Fehlermeldung aus    
                end
            end
        end
    end
    
    events
    end
end