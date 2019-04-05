classdef IsolationDevice < handle
    properties
        robot;
        convBelt;
        cANbus;
        mega;
        drumFeeder;
        listenerLightBarrierInterruption;
    end
    
    methods
        function this = IsolationDevice(cANbus)
            this.cANbus = cANbus;
            this.mega = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');
            this.convBelt = ConveyorBelt(cANbus);
            this.robot = Robot(cANbus, this.mega);
            this.drumFeeder = DrumFeeder(cANbus, this.mega);
            
        end
        
        
        % Kompletter Isolationsvorgang für ein Objekt
        function [success, error] = isolateObject(this)
            success = 1;
            error = 0;
            
            if(~this.robot.objDetection.objectOnTable())    % Falls kein Objekt auf dem Objekttisch liegt
                this.convBelt.start();                      % Förderband einschalten
                if(~this.drumFeeder.isolate())              % Falls der Nachschub über das Förderband nicht klappt
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