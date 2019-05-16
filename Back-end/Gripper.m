classdef Gripper < StateObject
    % Verwendete Module und Subklassen
    properties
        mega;   % Arduino Mega 2560
        servo1;
        servo2;
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        offset = 0.05;
        angle_1 = 0;
        angle_2 = 0;
        has_contact = 0;
    end
    
    methods
        % Erstellt das Objekt
        function this = Gripper(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
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
                this.setStateInactive('Initialisiert');
            catch ME
                this.setStateError('Initialisierung fehlgeschlagen');
                this.logger.error(ME.message);
            end
        end
        
        % Öffnet den Greifer
        function open(this)
            angle = 0;
            this.setAngles(angle, angle)
            this.setStateInactive('Offen');
        end
        
        % Schließt den Greifer
        function close(this)
            angle = 0.60;
            this.setAngles(angle, angle)
            this.setStateInactive('Geschlossen');
        end
        
        % Verfährt die Servos
        function setAngles(this, angle1, angle2)
            if ~this.isReady; return; end
            diff_angle_1 = abs(this.angle_1 - angle1);
            diff_angle_2 = abs(this.angle_2 - angle2);
            writePosition(this.servo1, angle1 + this.offset);
            writePosition(this.servo2, angle2);
            this.angle_1 = angle1;
            this.angle_2 = angle2;
            pause(max(diff_angle_1,diff_angle_2)+0.05) % ungefähr die Zeit dies es brauch um den Greifer zu verfahren
            this.checkContact();
        end
        
        % Verfährt die Servos zu symmetrischen Werten
        function setAnglesSym(this, angle)
            this.setAngles(angle, angle)
        end
        
        % Gibt den Winkel von Servo 1 zurück
        function pos = readAngle1(this)
            pos = readPosition(this.servo1) - this.offset;
            this.angle_1 = pos;
        end
        
        % Gibt den Winkel von Servo 2 zurück
        function pos = readAngle2(this)
            pos = readPosition(this.servo2);
            this.angle_2 = pos;
        end
        
        % Gibt die Winkel der Servos zurück
        function [pos1, pos2] = readAngles(this)
            pos1 = readAngle1(this);
            pos2 = readAngle2(this);
        end
        
        % Verändert den Offset der Servos
        function changeOffset(this, offset)
            [a1,a2] = this.readAngles();

            this.open()
            this.offset = offset;
            pause(0.3)
            this.setAngles(a1,a2);
        end
        
        % return 1: Greiferarme haben Kontakt,
        % return 0: Greiferarme haben keinen Kontakt
        function status = checkContact(this)
            this.mega.configurePin('D9','pullup');
            status = ~this.mega.readDigitalPin('D9');
            this.has_contact = status;
        end
        
        % Gibt zurück, ob ein Objekt im Greifer detektiert wird
        function status = checkObject(this)
            status = ~checkContact(this);
            if status
                this.logger.warning('Greifer hat kein Objekt');
            end
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        % Reaktion des Objektes auf Zustandsänderung
        function onStateChange(this)
            if ~this.isReady()
                
            end
        end
    end
    
end