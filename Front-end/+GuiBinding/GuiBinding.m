classdef GuiBinding < handle
    %GUIOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = GuiBinding()
        end
        
        function tryEval(this)
            try
                this.eval()
            catch ME
%                 disp(ME.stack(1))
%                 disp(ME.stack(2))
%                 disp(ME.message)
            end
        end
        
        function string = str(this)
            string = 'test';
        end
    end
    methods (Abstract)
        eval(this)
    end
end

