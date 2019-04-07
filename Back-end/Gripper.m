classdef Gripper < StateObject
    properties
        logger;
        
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
        
        function init(this, mega)
            this.mega = mega;
            this.servo1 = servo(this.mega, 'D11');
            this.servo2 = servo(this.mega, 'D12');
            this.offset = 0.065;
            
            this.setStateOnline('Initialisiert');
        end
        
        function open(this)
            angle = 0;
        	writePosition(this.servo1, angle+this.offset);
            writePosition(this.servo2, angle);
        end
        
        function close(this)
            angle = 0.60;
            writePosition(this.servo1, angle + this.offset);
            writePosition(this.servo2, angle);
%             pause(0.5)
%             writePosition(this.servo1, angle + this.offset + 0.02);
%             writePosition(this.servo2, angle +0.02);
        end
        
        function setAngles(this, angle1, angle2)
            writePosition(this.servo1, angle1);
            writePosition(this.servo2, 1-angle2);
        end
        
        function readAngles(this)
            pos1 = readPosition(this.servo1);
            pos1 = pos1*180;
            fprintf('Current motor position1 is %d degrees\n', pos1);
            pos2 = readPosition(this.servo2);
            pos2 = pos2*180;
            fprintf('Current motor position2 is %d degrees\n', pos2);
        end
        
        % return 1: Greiferarme haben Kontakt, 
        % return 0: Greiferarme haben keinen Kontakt
        function status = checkContact(this)
            this.close();
            this.mega.configurePin('D9','pullup');
            status = ~this.mega.readDigitalPin('D9');
            disp(status);
        end
    end
    
end