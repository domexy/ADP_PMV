classdef Binding < handle
    %GUIOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = Binding()
        end
        
        function tryEval(this,varargin)
            try
                this.eval()
            catch ME
                disp(ME.message)
            end
        end
    end
    methods (Abstract)
        eval(this)
    end
end