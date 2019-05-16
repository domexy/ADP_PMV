classdef IsolationDevice < StateObject
    % Verwendete Module und Subklassen
    properties
        robot;
        convBelt;
        cANbus;
        mega;
        drumFeeder;
    end
    
    % F�r den Nutzer nicht sichtbare EventListener
    properties(Hidden)
        listenerLightBarrierOn;
        listenerLightBarrierOff;
    end
    
    % Beobachtbare Zust�nde
    properties(SetAccess = private, SetObservable)
        light_barrier_blocked = 0;
    end
    
    methods
        % Erstellt das Objekt
        function this = IsolationDevice(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
            
            this.convBelt = ConveyorBelt(this.logger);
            this.robot = Robot(this.logger);
            this.drumFeeder = DrumFeeder(this.logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this,cANbus,mega)
            try
                this.cANbus = cANbus;
                this.mega = mega;

                this.convBelt.init(cANbus);
                this.robot.init(cANbus, this.mega);
                this.drumFeeder.init(cANbus, this.mega);
                
                this.listenerLightBarrierOn = addlistener(this.cANbus,'LightBarrierIsoOn',@this.setLightBarrierOn);
                this.listenerLightBarrierOff = addlistener(this.cANbus,'LightBarrierIsoOff',@this.setLightBarrierOff);

                this.setStateInactive('Initialisiert');
            catch ME
               this.setStateError('Initialisierung fehlgeschlagen'); 
               this.logger.error(ME.message);
            end
        end
        
        
        % Kompletter Isolationsvorgang f�r ein Objekt
        function [success, error] = isolateObject(this)
            success = 1;
            error = 0;
            this.setStateActive('Vorvereinzeln...');
            if(~this.robot.objDetection.objectOnTable())    % Falls kein Objekt auf dem Objekttisch liegt
                this.convBelt.start();                      % F�rderband einschalten
                if(~this.drumFeeder.isolate())              % Falls der Nachschub �ber das F�rderband nicht klappt
                    success = 0;                            
                    error = 'Timeout: Lichtschranke1';
                end
                this.convBelt.stop();
                this.convBelt.moveObjectOntoTable();
            end
            pause(2)
            frame = this.robot.objDetection.cam.snapshot();
            imwrite(frame, [datestr(now, 'HH-MM-SS'),'.jpg'])
%             if (~this.robot.objDetection.objectOnTable())
%                this.robot.sweep()
%                success = 0;
%             end
            if (success)                                    % Falls Vorvereinzelung geklappt hat
                this.setStateActive('Vereinzeln...')
                if (~this.robot.feedObject())               % Falls der Transport des Objekts ins Messsystem nicht klappt
                    success = 0;
                    error = 'Transport';
                else
%                     this.simulateCamera();
                end
            
            end
            this.setStateInactive('Bertriebsbereit')
        end
        
        % Dauerschleife
        function run(this)
            timer = tic;
            while (toc(timer) < 180)
                this.isolateObject()
            end
        end
        
        % Setter f�r light_barrier_blocked, bedingt durch EventListener
        function setLightBarrierOn(this,~,~)
            this.light_barrier_blocked = 1;
        end
        
        % Setter f�r light_barrier_blocked, bedingt durch EventListener
        function setLightBarrierOff(this,~,~)
            this.light_barrier_blocked = 0;
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            try
                if this.getState() ~= this.OFFLINE
                    sub_system_states = [...
                        this.cANbus.getState(),...
                        this.robot.getState(),...
                        this.convBelt.getState(),...
                        this.drumFeeder.getState()];
                    if any(sub_system_states == this.ERROR)
                        this.changeStateError('Fehler im Subsystem')
                    end                
                end
            catch
                this.changeStateError('Fehler bei der Zustandsaktualisierung')
            end
        end
        
        % Reaktion des Objektes auf Zustands�nderung
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
    
    events
    end
end