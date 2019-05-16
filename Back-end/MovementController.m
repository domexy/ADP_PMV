classdef MovementController < handle
    %MOVEMENTCONTROLLER Ebenen-Bewegungsmodell für den Roboterarm
    
    % Abhängige Zustände, werden erst beim Abrufen berechnet
    % Projeziert die aktuelle Position auf die jeweilige Ebene
    properties(SetAccess = private, Dependent)
        current_position;
        moving_position;
        vacuum_position;
        gripping_position;
        lifting_position;
        dropping_position;
    end
    
    % Definierte Konstanten
    properties(Access = private, Constant)
        % Bewegungsebenen
%         LOW_MOVING_PLANE = [447 180 0 0]; % z,rx,ry,rz
        LOW_MOVING_PLANE = [447 180 0 0]; % z,rx,ry,rz
        HIGH_MOVING_PLANE = [650 135 120 0]; % z,rx,ry,rz
        VACUUM_PLANE = [57 180 0 0]; % z,rx,ry,rz
        GRIPPING_PLANE = [105 180 0 0]; % z,rx,ry,rz
        LIFTING_PLANE = [250 180 0 0]; % z,rx,ry,rz
        DROPPING_PLANE = [385 -15 167 0]; % z,rx,ry,rz
        SWEEPING_PLANE = [66.74 -144.38 -0.78 -105.33]; % z,rx,ry,rz
        
        % Bewegungsgrenzen für Bewegungen auf den einzelnen Ebenen
        MOVING_HIGH_X_LIMITS = [-inf,600]; % min x limit durch MOVING_HIGH_X_LIMITS,max
        MOVING_HIGH_Y_LIMITS = [-720,100]; % min,max
        MOVING_LOW_X_LIMITS = [-160,inf]; % min,max x limit durch MOVING_HIGH_X_LIMITS
        MOVING_LOW_Y_LIMITS = [-720,-290]; % min,max
        LIFTING_X_LIMITS = [-160,120]; % min,max
        LIFTING_Y_LIMITS = [-720,-290]; % min,max
        DROPPING_X_LIMITS = [470,600]; % min,max
        DROPPING_Y_LIMITS = [-150,100]; % min,max
        SWEEPING_X_LIMITS = [-174,600]; % min,max
        SWEEPING_Y_LIMITS = [-720,-290]; % min,max
        
        % Koordinaten
        LOW_HIGH_Y_TRANSITION_COORD = -550; % y-koordinate für den sicheren übergang LOW<->HIGH
        LOW_HIGH_X_THRESHOLD = 137; % x-koordinate über der die High-Positin
        %statt der LOW-Position verwendet wird um Kollisionen mit der Rampe zu vermeiden
        DROPPING_XY_COORDS = [528, 41];
        HOME_XY_COORDS = [26, -290]
    end
    
    methods
        % Erstellt das Objekt
        function this = MovementController()
            
        end
        % Initialisierung muss durch untergeordnete Klasse (Robot)
        % vorgenommen werden
        
        % Bewegt Roboter zur Ablageposition
        function moveToDroppingPosition(this)
            this.logger.info('Verfahre zur Ablageposition...');
            this.moveTo(this.DROPPING_XY_COORDS(1),this.DROPPING_XY_COORDS(2))
            this.setStateInactive('Ablageposition erreicht');
        end
        
        % Bewegt Roboter zur Homeposition
        function moveToHomePosition(this)
            this.logger.info('Verfahre zur Homeposition...');
            this.moveTo(this.HOME_XY_COORDS(1),this.HOME_XY_COORDS(2))
            this.setStateInactive('Homeposition erreicht');
        end
        
        % Verfährt den Roboter im Ebenenmodel
        function moveTo(this,x,y)
            if nargin < 2
                y = x(2);
                x = x(1);
            end
            
            target_position_is_high = (x > this.LOW_HIGH_X_THRESHOLD);%Robot bei HIGH_PLANE
            current_position_is_high = (this.current_position(1) > this.LOW_HIGH_X_THRESHOLD);%Robot bei HIGH_PLANE;
            
            if target_position_is_high
                if ((x < this.MOVING_HIGH_X_LIMITS(1)) || (this.MOVING_HIGH_X_LIMITS(2) < x))
                    this.logger.warning(['X-Position ',num2str(x),' außerhalb der Limits: ', this.MOVING_HIGH_X_LIMITS])
                    return
                end
                if ((y < this.MOVING_HIGH_Y_LIMITS(1)) || (this.MOVING_HIGH_Y_LIMITS(2) < y))
                    this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.MOVING_HIGH_Y_LIMITS)])
                    return
                end
            else
                if ((x < this.MOVING_LOW_X_LIMITS(1)) || (this.MOVING_LOW_X_LIMITS(2) < x))
                    this.logger.warning(['X-Position ',num2str(x),' außerhalbhsd der Limits: ', num2str(this.MOVING_LOW_X_LIMITS)])
                    return
                end
                if ((y < this.MOVING_LOW_Y_LIMITS(1)) || (this.MOVING_LOW_Y_LIMITS(2) < y))
                    this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.MOVING_LOW_Y_LIMITS)])
                    return
                end
            end
            
            if any(this.current_position ~= this.moving_position)
                this.move(this.moving_position) % Bewege Roboter vertikal auf Bewegungsebene (HIGH oder LOW)
            end
            
            
            if target_position_is_high == current_position_is_high %Kein Übergang von HIGH nach LOW, oder umgekehrt
                this.move([x,y,this.moving_position(3:end)]); % Bewege Roboter auf Zielposition
            else %Übergang von HIGH nach LOW, oder umgekehrt
                transition_direction = -(this.LOW_HIGH_X_THRESHOLD-x)/abs(this.LOW_HIGH_X_THRESHOLD-x);
                % Bewege Roboter 1mm über HIGH_LOW Grenze
                this.move([this.LOW_HIGH_X_THRESHOLD+transition_direction,this.LOW_HIGH_Y_TRANSITION_COORD,this.moving_position(3:end)]);
                this.move(this.moving_position) % Bewege Roboter vertikal auf auf neue Bewegungsebene (HIGH oder LOW)
                this.move([x,y,this.moving_position(3:end)]); % Bewege Roboter auf Zielposition
            end
        end
        
        % Hebt den Roboter auf Bewegungsebene
        function heaveToMovementHeight(this)
            this.move(this.moving_position)
        end
        
        % Hebt den Roboter auf Hebeebene
        function heaveToLiftingHeight(this)
            lifting_position = this.lifting_position;
            x = lifting_position(1);
            y = lifting_position(2);
            if ((x < this.LIFTING_X_LIMITS(1)) || (this.LIFTING_X_LIMITS(2) < x))
                this.logger.warning(['X-Position ',num2str(x),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            if ((y < this.LIFTING_Y_LIMITS(1)) || (this.LIFTING_Y_LIMITS(2) < y))
                this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            this.move(lifting_position)
        end
        
        % Hebt den Roboter auf Greifebene
        function heaveToGrippingHeight(this)
            gripping_position = this.gripping_position;
            x = gripping_position(1);
            y = gripping_position(2);
            if ((x < this.LIFTING_X_LIMITS(1)) || (this.LIFTING_X_LIMITS(2) < x))
                this.logger.warning(['X-Position ',num2str(x),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            if ((y < this.LIFTING_Y_LIMITS(1)) || (this.LIFTING_Y_LIMITS(2) < y))
                this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            this.move(gripping_position)
        end
        
        % Hebt den Roboter auf Unterdruckebene
        function heaveToVacuumHeight(this)
            vacuum_position = this.vacuum_position;
            x = vacuum_position(1);
            y = vacuum_position(2);
            if ((x < this.LIFTING_X_LIMITS(1)) || (this.LIFTING_X_LIMITS(2) < x))
                this.logger.warning(['X-Position ',num2str(x),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            if ((y < this.LIFTING_Y_LIMITS(1)) || (this.LIFTING_Y_LIMITS(2) < y))
                this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.LIFTING_X_LIMITS)]);
                return
            end
            this.move(vacuum_position)
        end
        
        % Hebt den Roboter auf Ablageebene
        function heaveToDroppingHeight(this)
            dropping_position = this.dropping_position;
            x = dropping_position(1);
            y = dropping_position(2);
            if ((x < this.DROPPING_X_LIMITS(1)) || (this.DROPPING_X_LIMITS(2) < x))
                this.logger.warning(['X-Position ',num2str(x),' außerhalb der Limits: ', num2str(this.DROPPING_X_LIMITS)]);
                return
            end
            if ((y < this.DROPPING_Y_LIMITS(1)) || (this.DROPPING_Y_LIMITS(2) < y))
                this.logger.warning(['Y-Position ',num2str(y),' außerhalb der Limits: ', num2str(this.DROPPING_Y_LIMITS)]);
                return
            end
            this.move(dropping_position)
        end
        
        % Objekttische abkehren und damit von Objekten befreien
        % Fest einprogrammiert, da eine flexible Ansteuerung aktuell nicht
        % sinnvoll.
        function sweep(this)
            this.setStateActive('Wische...');
            wp{1} = [0 -400 130 180 0 0];
            wp{2} = [-173.99 -409.07 76.74 -144.38 -1.78 -107.33];
            wp{3} = [-161.49 -409.07 66.74 -144.38 -0.78 -105.33];
            wp{4} = [176.13 -409.07 64.24 143.58 0.78 107.73];
            wp{5} = [0 -400 130 180 0 0];
            wp{6} = [-173.99 -679.71 76.74 -144.38 -1.78 -107.33];
            wp{7} = [-161.49 -679.71 66.74 -144.38 -0.78 -105.33];
            wp{8} = [176.13 -679.71 64.24 143.58 0.78 107.73];
            wp{9} = [0 -400 130 180 0 0];
            
            for k=1:length(wp)
                curWP = wp{k};
                this.move(curWP);
            end
            this.setStateInactive('Wischen abgeschlossen');
            % Fahre Roboter zurück in die Home-Position
            this.moveToHomePosition();
        end
        
        % Getter für current_position
        function current_position = get.current_position(this)
            current_position = this.readPose();
        end
        
        % Getter für moving_position
        function moving_position = get.moving_position(this)
            pose = this.readPose();
            if pose(1) > this.LOW_HIGH_X_THRESHOLD % ROBOTER IST IM RAMPENNÄHE
                moving_position = [pose(1:2), this.HIGH_MOVING_PLANE];
            else
                moving_position = [pose(1:2), this.LOW_MOVING_PLANE];
            end
        end
        
        % Getter für vacuum_position
        function vacuum_position = get.vacuum_position(this)
            pose = this.readPose();
            vacuum_position = [pose(1:2), this.VACUUM_PLANE];
        end
        
        % Getter für gripping_position
        function gripping_position = get.gripping_position(this)
            pose = this.readPose();
            gripping_position = [pose(1:2), this.GRIPPING_PLANE];
        end
        
        % Getter für lifting_position
        function lifting_position = get.lifting_position(this)
            pose = this.readPose();
            lifting_position = [pose(1:2), this.LIFTING_PLANE];
        end
        
        % Getter für dropping_position
        function dropping_position = get.dropping_position(this)
            pose = this.readPose();
            dropping_position = [pose(1:2), this.DROPPING_PLANE];
        end
    end
    
end

