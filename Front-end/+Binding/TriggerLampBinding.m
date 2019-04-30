classdef TriggerLampBinding < Binding.Binding
    properties (SetAccess=private)
        lamp_colors = struct(...
                        'ACTIVE', [0,1,0],...
                        'INACTIVE', [0.1,0.1,0.1])  
    end
    
    properties(Access = public)
        source_object
        source_prop_name
        lamp
        listener
    end
    
    methods
        function this = TriggerLampBinding(source_object, source_prop_name, lamp,varargin)
            this.source_object = source_object;
            this.source_prop_name = source_prop_name;
            this.lamp = {lamp};
            if ~isempty(varargin)
                this.lamp = [this.lamp, varargin(1:end)];
            end
            
            this.listener = addlistener(source_object,source_prop_name,'PostSet', @this.tryEval);
        end
        
        function eval(this)
            if this.source_object.(this.source_prop_name)
                for i = 1:length(this.lamp)
                    this.lamp{i}.Color = this.lamp_colors.ACTIVE;
                end
            else
                for i = 1:length(this.lamp)
                    this.lamp{i}.Color = this.lamp_colors.INACTIVE;
                end
            end
        end
        
        function setActiveColor(this, color)
            this.lamp_colors.ACTIVE = color;
        end
        
        function setInActiveColor(this, color)
            this.lamp_colors.INACTIVE = color;
        end
    end
end

