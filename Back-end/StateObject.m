classdef StateObject < handle
    %STATEOBJECT Basis Klasse für alle Anlagenklassen
    %Muss an Anlagenklasse vererbt werden und diese muss den
    %Superkonstruktor aufrufen
    
    % Verwendete Module und Subklassen
    properties
        logger;
    end
    
    % Beobachtbare Zustände
    properties (SetAccess = private, SetObservable)
        state = 1;
        state_description = '-OFFLINE-';
    end
    
    % Definierte Konstanten
    properties (Constant, Hidden)
        OFFLINE = 1;    % Objekt ist Matlabseitig initialisiert, hat jedoch noch keine Verbindung zum physischen Objekt
        INACTIVE = 2;   % Objekt ist Einsatzbereit und hat keinen Auftrag
        ACTIVE = 3;     % Objekt führt einen Auftrag aus
        UNKOWN = 4;     % Objektzustand ist unbekannt
        STOPPED = 5;    % Objekt ist gestoppt und führt keine Aufträge aus
        ERROR = 6;      % Objekt hat einen Fehler und führt keine Aufträge aus
        STATE_STRINGS = {...
            'OFFLINE',...
            'INACTIVE',...
            'ACTIVE',...
            'UNKNOWN',...
            'STOPPED',...
            'ERROR'};
        READY_STATES = [1,2,3,4];
    end
    
    methods
        % Erstellt das Objekt
        function this = StateObject(logger)
            if isempty(logger)
                this.logger.debug = @disp;
                this.logger.info = @disp;
                this.logger.warning = @disp;
                this.logger.error = @disp;
            else
                this.logger = logger;
                if strcmp(class(logger),'Logger.Logger')
                    this.logger.addToForbiddenFiles();
                end
            end
%             this.setStateOffline();
        end
        
        % Getter für den Zustand
        function state = getState(this)
            state = this.state;
        end

        % Getter für Zustandsbeschreibung
        function state_description = getStateDescription(this)
            state_description = this.state_description;
        end
        
        % Setzt den Zustand auf Offline
        function setStateOffline(this, state_description)
            if nargin < 2
               state_description = '-Offline-'; 
            end
            this.setState(this.OFFLINE, state_description);
        end
        
        % Setzt den Zustand auf Inaktiv
        function setStateInactive(this, state_description)
            if nargin < 2
               state_description = '-Inactive-'; 
            end
            this.setState(this.INACTIVE, state_description);
        end
        
        % Setzt den Zustand auf Aktiv
        function setStateActive(this, state_description)
            if nargin < 2
               state_description = '-Active-'; 
            end
            this.setState(this.ACTIVE, state_description);
        end
        
        % Setzt den Zustand auf Unbekannt
        function setStateUnknown(this, state_description)
            if nargin < 2
               state_description = '-Unknown-'; 
            end
            this.setState(this.UNKOWN, state_description);
        end
        
        % Setzt den Zustand auf Gestoppt
        function setStateStopped(this, state_description)
            if nargin < 2
               state_description = '-Stopped-'; 
            end
                this.setState(this.STOPPED, state_description);
        end
        
        % Setzt den Zustand auf Gestört
        function setStateError(this, state_description)
            if nargin < 2
               state_description = '-Error-'; 
            end
                this.setState(this.ERROR, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf einen anderen
        function changeState(this, state, state_description)
            if this.getState() ~= state
               this.setState(state, state_description)
            end
        end
        
        % Verändert (falls neu) den Zustand auf Offline
        function changeStateOffline(this, state_description)
            if nargin < 2
               state_description = '-Offline-'; 
            end
            this.changeState(this.OFFLINE, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf Inaktiv
        function changeStateInactive(this, state_description)
            if nargin < 2
               state_description = '-Inactive-'; 
            end
            this.changeState(this.INACTIVE, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf Aktiv
        function changeStateActive(this, state_description)
            if nargin < 2
               state_description = '-Active-'; 
            end
            this.changeState(this.ACTIVE, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf Unbekannt
        function changeStateUnknown(this, state_description)
            if nargin < 2
               state_description = '-Unknown-'; 
            end
            this.changeState(this.UNKOWN, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf Gestoppt
        function changeStateStopped(this, state_description)
            if nargin < 2
               state_description = '-Stopped-'; 
            end
            this.changeState(this.STOPPED, state_description);
        end
        
        % Verändert (falls neu) den Zustand auf Gestört
        function changeStateError(this, state_description)
            if nargin < 2
               state_description = '-Error-'; 
            end
            this.changeState(this.ERROR, state_description);
        end
        
        % Gibt an ob das Objekt in einem Einsatzbereiten Zustand ist
        function ready = isReady(this)
            ready = any(this.getState() == this.READY_STATES);
        end
    end
    
    % Für den Nutzer nicht zugängliche Methoden
    methods (Access = private)
        % Setzt den Zustand, falls ein erlaubter Übergang vorliegt
        function setState(this,state, state_description)
            if isAllowedStateChange(this.state, state)
                state_change_message = [...
                    this.STATE_STRINGS{this.state}, '(', this.state_description,')'...
                    ' -> ', this.STATE_STRINGS{state}, '(', state_description,')'];
                this.onStateChange();
                this.state_description = state_description;
                % state erst nach state_description, da event_listeners direkt
                % auf state achten aber nur indirekt (via state) auf
                % state_description zugreifen. 
                % Sonst ist beim event_listener zugriff noch die alte
                % state_description gesetzt.
                this.state = state;
                this.logger.debug(state_change_message);
            else
                this.logger.warning(['Zustandsübergang von ', this.STATE_STRINGS{this.state},' nach ' this.STATE_STRINGS{state},' nicht erlaubt!']);
            end
        end
        
        function is_allowed = isAllowedStateChange(this, from_state, to_state)
            is_allowed = true;
            switch from_state
                case this.OFFLINE
                    if to_state ~= this.INACTIVE
                        is_allowed = false;
                    end
                case this.INACTIVE
                    
                case this.ACTIVE
                    if to_state == this.OFFLINE
                        is_allowed = false;
                    end
                case this.UNKOWN
                    if to_state == this.OFFLINE
                        is_allowed = false;
                    end
                    if to_state == this.ACTIVE
                        is_allowed = false;
                    end
                case this.STOPPED
                    if to_state == this.OFFLINE
                        is_allowed = false;
                    end
                    if to_state == this.INACTIVE
                        is_allowed = false;
                    end
                    if to_state == this.ACTIVE
                        is_allowed = false;
                    end
                case this.ERROR
                    if to_state ~= this.UNKNOWN
                        is_allowed = false;
                    end
            end
        end
    end
    
    methods (Abstract)
        updateState(this) 
        onStateChange(this)
    end
end

