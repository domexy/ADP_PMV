classdef StateObject < handle
    %BASEOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    properties
        logger;
        components = struct();
    end
    
    properties (Access = private)
        state;
        state_description;
    end
    
    properties (Constant)
        OFFLINE = 1;
        ONLINE = 2;
        ACTIVE = 3;
        UNKOWN = 4;
        ERROR = 5;
        STATE_STRINGS = {...
            'OFFLINE',...
            'ONLINE',...
            'ACTIVE',...
            'UNKNWON',...
            'ERROR'};
    end
    
    methods
        function this = StateObject(logger)
            if isempty(logger)
                this.logger.debug = @disp;
                this.logger.info = @disp;
                this.logger.warning = @disp;
                this.logger.error = @disp;
            else
                this.logger = logger;
                this.logger.addToForbiddenFiles();
            end
            this.setStateOffline();
        end
        
        function addComponent(this, component_name, component)
            isStateObject = false;
            parents = superclasses(component);
            for i=1:length(parents)
                if strcmp(parents{i},class('StateObject'))
                   isStateObject = true; 
                end
            end
            if isStateObject
                this.components.(component_name) = component;
            else
               this.logger.warning([component_name, ' ist keine Unterklasse von StateObject']); 
            end
        end
        
        function state = getState(this)
            state = this.state;
        end
        
%         function state = checkState(this)
%             self_state = this.checkSelfState();
%             component_states = this.checkComponentStates();
%             if self_state == this.ERROR
%                 
%             elseif self_state ~= this.OFFLINE
%                 if max(component_states) > self_state
%                     this.setState(max(component_states), '
%                 end    
%             else max(component_states) == this.ERROR
%                 this.setStateError('Fehler einer Komponente');
%             end
%         end
%         
%         function states = checkComponentStates(this)
%             states = [];
%             fields = fieldsnames(this.components);
%             for i = 1:length(fields) 
%                 states(i) = this.components.(fields{i}).checkSelfState;
%             end
%         end
        
        function state_description = getStateDescription(this)
            state_description = this.state_description;
        end
        
        function setStateOffline(this, state_description)
            if nargin < 2
               state_description = '-Offline-'; 
            end
            this.setState(this.OFFLINE, state_description);
        end
        
        function setStateOnline(this, state_description)
            if nargin < 2
               state_description = '-Online-'; 
            end
            this.setState(this.ONLINE, state_description);
        end
        
        function setStateActive(this, state_description)
            if nargin < 2
               state_description = '-Active-'; 
            end
            this.setState(this.ACTIVE, state_description);
        end
        
        function setStateUnknown(this, state_description)
            if nargin < 2
               state_description = '-Unknown-'; 
            end
            this.setState(this.UNKOWN, state_description);
        end
        
        function setStateError(this, state_description)
            if nargin < 2
               state_description = '-Error-'; 
            end
                this.setState(this.ERROR, state_description);
        end
        
        function changeState(this, state, state_description)
            if this.getState() ~= state
               this.setState(state, state_description)
            end
        end
        
        function changeStateOffline(this, state_description)
            if nargin < 2
               state_description = '-Offline-'; 
            end
            this.changeState(this.OFFLINE, state_description);
        end
        
        function changeStateOnline(this, state_description)
            if nargin < 2
               state_description = '-Online-'; 
            end
            this.changeState(this.ONLINE, state_description);
        end
        
        function changeStateActive(this, state_description)
            if nargin < 2
               state_description = '-Active-'; 
            end
            this.changeState(this.ACTIVE, state_description);
        end
        
        function changeStateUnknown(this, state_description)
            if nargin < 2
               state_description = '-Unknown-'; 
            end
            this.changeState(this.UNKOWN, state_description);
        end
        
        function changeStateError(this, state_description)
            if nargin < 2
               state_description = '-Error-'; 
            end
            this.changeState(this.ERROR, state_description);
        end
    end
    
    methods (Access = private)
        function setState(this,state, state_description)
            state_change_message = [...
                this.STATE_STRINGS{this.state}, '(', this.state_description,')'...
                ' -> ', this.STATE_STRINGS{state}, '(', state_description,')'];
            this.state = state;
            this.state_description = state_description;
            this.logger.debug(state_change_message);
        end
    end
    
    methods (Abstract)
        updateState(this) 
    end
end

