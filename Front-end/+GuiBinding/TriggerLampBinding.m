classdef TriggerLampBinding < GuiBinding.GuiBinding
    properties (Constant, Access=private)
        lamp_colors = struct(...
                        'ACTIVE', [0,1,0],...
                        'INACTIVE', [0.1,0.1,0.1])  
    end
    
    properties(Access = private)
        fcn_handle
        lamp
    end
    
    methods
        function this = TriggerLampBinding(fcn_handle,lamp,varargin)
            this.fcn_handle = fcn_handle;
                this.lamp = {lamp};
            if ~isempty(varargin)
                this.lamp = [this.lamp, varargin(1:end)];
            end
        end
        
        function eval(this)
            if this.fcn_handle()
                for i = 1:length(this.lamp)
                    this.lamp{i}.Color = this.lamp_colors.ACTIVE;
                end
            else
                for i = 1:length(this.lamp)
                    this.lamp{i}.Color = this.lamp_colors.INACTIVE;
                end
            end
        end
    end
end

