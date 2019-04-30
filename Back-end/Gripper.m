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
            try
                if nargin == 1
                    mega = createMega();
                end
                this.mega = mega;
                for i = 1:5
                    try
                        this.servo1 = servo(this.mega, 'D11');
                        break
                    catch
                        if i == 5
                            this.logger.error('Konnte Servo 1 nicht initialisieren!');
                            return
                        end
                    end
                    pause(0.25)
                end
                for i = 1:5
                    try
                        this.servo2 = servo(this.mega, 'D12');
                        break
                    catch
                        if i == 5
                            this.logger.error('Konnte Servo 2 nicht initialisieren!');
                            return
                        end
                    end
                    pause(0.25)
                end
                this.offset = 0.06;

                this.setStateInactive('Initialisiert');
            catch ME
               this.setStateError('Initialisierung fehlgeschlagen'); 
               this.logger.error(ME.message);
            end
        end
        
        function open(this)
            angle = 0;
        	this.setAngles(angle, angle)
            this.setStateInactive('Offen');
        end
        
        function close(this)
            angle = 0.60;
            this.setAngles(angle, angle)
            this.setStateInactive('Geschlossen');
        end
        
        function setAngles(this, angle1, angle2)
            writePosition(this.servo1, angle1 + this.offset);
            writePosition(this.servo2, angle2);
%             this.setStateUnknown(['Winkel = [',num2str(angle1),',',num2str(angle2),']'])
        end
        
        function setAnglesSym(this, angle)
            this.setAngles(angle, angle)
        end
        
        function pos = readAngle1(this)
            pos = readPosition(this.servo1) - this.offset;
        end
        
        function pos = readAngle2(this)
            pos = readPosition(this.servo2);
        end
        
        function [pos1, pos2] = readAngles(this)
            pos1 = readAngle1(this);
            pos2 = readAngle2(this);
        end
        
        function pos = readAngleDeg1(this)
            pos = this.readAngle1()*180;
        end
        
        function pos = readAngleDeg2(this)
            pos = this.readAngle2()*180;
        end
        
        function [pos1, pos2] = readAnglesDeg(this)
            pos1 = readAngleDeg1(this);
            pos2 = readAngleDeg2(this);
        end
        
        function changeOffset(this, offset)
            [a1,a2] = this.readAngles();
%             disp([a1,a2])
            b1 = a1+(0.5-a1)/2;
            b2 = a2+(0.5-a2)/2;
%             disp([b1,b2])
%             this.setAngles(b1,b2);
            this.open()
            this.offset = offset;
            pause(0.3)
            this.setAngles(a1,a2);
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
        
        function status = checkObject(this)
            this.close();
            status = checkContact(this);
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