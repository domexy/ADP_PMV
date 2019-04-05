classdef Lighting < handle
    properties
        lpt
    end
    
    methods
        % Konstruktor
        function obj = Lighting(lpt)
            obj.lpt = lpt;
        end
        % Beleuchtung einstellen
        function changeLighting(obj, byte)
            % using java.io.FileOutputStream and java.io.PrintStream
            os = java.io.FileOutputStream(obj.lpt); % open stream to LPT1 
            ps = java.io.PrintStream(os); % define PrintStream
            ps.write(byte); % write into buffer 
            ps.close % flush buffer and close stream
        end
    end
    
    events
    end
end