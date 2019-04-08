classdef Gripper < StateObject
    properties
        mega;   % Arduino Mega 2560
        servo1;
        servo2;
        offset
    end
    
    methods
        function this = Gripper(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this)            
            this.servo1 = servo(this.mega, 'D11');
            this.servo2 = servo(this.mega, 'D12');
            this.offset = 0.065;
            
            this.setStateOnline('Initialisiert');
        end
        
        function open(this)
            angle = 0;
        	writePosition(this.servo1, angle+this.offset);
            writePosition(this.servo2, angle);
            this.setStateOnline('Offen');
        end
        
        function close(this)
            angle = 0.60;
            writePosition(this.servo1, angle + this.offset);
            writePosition(this.servo2, angle);
            this.setStateActive('Geschlossen');
        end
        
        function setAngles(this, angle1, angle2)
            writePosition(this.servo1, angle1);
            writePosition(this.servo2, 1-angle2);
            this.setStateUnknown(['Winkel = [',num2str(angle1),',',num2str(angle2),']'])
        end
        
        function [pos1, pos2] = readAngles(this)
            pos1 = readPosition(this.servo1);
            pos1 = pos1*180;
%             fprintf('Current motor position1 is %d degrees\n', pos1);
            pos2 = readPosition(this.servo2);
            pos2 = pos2*180;
%             fprintf('Current motor position2 is %d degrees\n', pos2);
        end
        
        % return 1: Greiferarme haben Kontakt, 
        % return 0: Greiferarme haben keinen Kontakt
        function status = checkContact(this)
            this.close();
            this.mega.configurePin('D9','pullup');
            status = ~this.mega.readDigitalPin('D9');
            if status
                this.logger.warning('Greifer hat kein Objekt');
            end
            % disp(status);
        end
        
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
    end
    
end