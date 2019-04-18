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
        
        function init(this, mega)   
            this.mega = mega;
            this.servo1 = servo(this.mega, 'D11');
            this.servo2 = servo(this.mega, 'D12');
            this.offset = 0.065;
            
            this.setStateInactive('Initialisiert');
        end
        
        function open(this)
            angle = 0;
        	writePosition(this.servo1, angle+this.offset);
            writePosition(this.servo2, angle);
%             this.setStateInactive('Offen');
        end
        
        function close(this)
            angle = 0.60;
            writePosition(this.servo1, angle + this.offset);
            writePosition(this.servo2, angle);
%             this.setStateActive('Geschlossen');
        end
        
        function setAngles(this, angle1, angle2)
%             if nargin < 3
%                 disp('ding')
%                 angle2 = angle1;
%             else
%                 disp('dong')
%             end
            writePosition(this.servo1, angle1);
            writePosition(this.servo2, 1-angle2);
%             this.setStateUnknown(['Winkel = [',num2str(angle1),',',num2str(angle2),']'])
        end
        
        function pos = readAngle1(this)
            pos = readPosition(this.servo1);
            pos = pos*180;
        end
        
        function pos = readAngle2(this)
            pos = readPosition(this.servo2);
            pos = pos*180;
        end
        
        function [pos1, pos2] = readAngles(this)
            pos1 = readAngle1(this);
            pos2 = readAngle2(this);
        end
        
        % return 1: Greiferarme haben Kontakt, 
        % return 0: Greiferarme haben keinen Kontakt
        function status = checkContact(this)
%             this.close();
            this.mega.configurePin('D9','pullup');
            status = ~this.mega.readDigitalPin('D9');
%             if status
%                 this.logger.warning('Greifer hat kein Objekt');
%             end
            % disp(status);
        end
        
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
    
end