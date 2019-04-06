classdef StateObject < handle
    %BASEOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        state;
        state_description;
    end
    
    properties (Constant)
        OFFLINE = 0;
        ONLINE = 1;
        ACTIVE = 2;
        UNKOWN = 3;
        ERROR = 4;
    end
    
    methods
        function this = StateObject()
            this.state = 0;
            this.state_description = 'Offline';
        end
        
        function state = getState(this)
            state = this.state;
        end
        
        function state_description = getStateDescription(this)
            state_description = this.state_description;
        end
        
        function setStateOffline(this, state_description)
            if nargin < 2
               state_description = '-Offline-'; 
            end
            this.setState(this.OFFLINE, state_description)
        end
        
        function setStateOnline(this, state_description)
            if nargin < 2
               state_description = '-Online-'; 
            end
            this.setState(this.ONLINE, state_description)
        end
        
        function setStateActive(this, state_description)
            if nargin < 2
               state_description = '-Active-'; 
            end
            this.setState(this.ACTIVE, state_description)
        end
        
        function setStateUnknown(this, state_description)
            if nargin < 2
               state_description = '-Unknown-'; 
            end
            this.setState(this.UNKOWN, state_description)
        end
        
        function setStateError(this, state_description)
            if nargin < 2
               state_description = '-Error-'; 
            end
            this.setState(this.ERROR, state_description)
        end
    end
    
    methods (Access = private)
        function setState(this,state, state_description)
            this.state = state;
            this.state = state_description;
        end
    end
end

