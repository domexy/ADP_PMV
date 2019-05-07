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
                if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                   delete(this); 
                   disp(1)
                end
                disp(ME.message)
            end
        end
    end
    methods (Abstract)
        eval(this)
    end
end