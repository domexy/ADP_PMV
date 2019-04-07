classdef IsolationDevice < StateObject
    properties
        logger;
        
        robot;
        convBelt;
        cANbus;
        mega;
        drumFeeder;
        listenerLightBarrierInterruption;
    end
    
    methods
        function this = IsolationDevice(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this,cANbus)
            this.cANbus = cANbus;
            this.convBelt = ConveyorBelt(this.logger);
            this.robot = Robot(this.logger);
            this.drumFeeder = DrumFeeder(this.logger);
            this.mega = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');
            
            this.convBelt.init(cANbus);
            this.robot.init(cANbus, this.mega);
            this.drumFeeder.init(cANbus, this.mega);
            
            this.setStateOnline('Initialisiert');
        end
        
        
        % Kompletter Isolationsvorgang f�r ein Objekt
        function [success, error] = isolateObject(this)
            success = 1;
            error = 0;
            
            if(~this.robot.objDetection.objectOnTable())    % Falls kein Objekt auf dem Objekttisch liegt
                this.convBelt.start();                      % F�rderband einschalten
                if(~this.drumFeeder.isolate())              % Falls der Nachschub �ber das F�rderband nicht klappt
                    success = 0;                            
                    error = 'Timeout: Lichtschranke1';
                end
                this.convBelt.stop();
            end
            pause(2)
            frame = this.robot.objDetection.cam.snapshot();
            imwrite(frame, [datestr(now, 'HH-MM-SS'),'.jpg'])
%             if (~this.robot.objDetection.objectOnTable())
%                this.robot.sweep()
%                success = 0;
%             end
            if (success)                                    % Falls Vorvereinzelung geklappt hat
                if (~this.robot.feedObject())               % Falls der Transport des Objekts ins Messsystem nicht klappt
                    success = 0;
                    error = 'Transport';
                else
%                     this.simulateCamera();
                end
            
            end
            
        end
        
        % Dauerschleife
        function run(this)
            timer = tic;
            while (toc(timer) < 180)
                this.isolateObject()
            end
        end

    end
    
    events
    end
end