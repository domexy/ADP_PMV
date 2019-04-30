classdef StateLampBinding < GuiBinding.GuiBinding
    properties (Constant, Access=private)
        lamp_colors = struct(...
                        'OFFLINE', [0.65,0.65,0.65],...
                        'INACTIVE', [0.07,0.62,1],...
                        'ACTIVE', [0,1,0],...
                        'UNKNOWN', [1,1,0],...
                        'STOPPED', [0,0,0],...
                        'ERROR', [1,0,0])  
    end
    
    properties(Access = private)
        state_object
        lamp
        editfield
        listener
    end
    
    methods
        function this = StateLampBinding(state_object,lamp,editfield,varargin)
            this.state_object = state_object;
            this.lamp = {lamp};
            this.editfield = {editfield};
            if ~isempty(varargin)
                if mod(length(varargin),2)
                    error('Unmatched number of input arguments')
                end
                this.lamp = [this.lamp, varargin(1:2:end)];
                this.editfield = [this.editfield, varargin(2:2:end)];
            end
            this.listener = addlistener(state_object,'State','PostSet', @this.eval);
        end
        
        function eval(this)
            this.state_object.updateState();
            state = this.state_object.getState();
            state_description = this.state_object.getStateDescription();           
            for i = 1:length(this.lamp)
                this.lamp{i}.Color = this.lamp_colors.(this.state_object.STATE_STRINGS{state});
                this.editfield{i}.Value = state_description;
            end
        end
    end
end

