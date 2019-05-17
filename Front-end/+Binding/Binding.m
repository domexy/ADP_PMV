classdef Binding < handle
    %BINDING Framework f�r �bertragungsfunktionen durch Beobachter
    % Diese Klasse kann nur durch eine Subklasse erstellt werden.
    
    properties
    end
    
    methods
        function this = Binding()
        end
        
        % Wrapper Methode f�r eval() der Subklassen, stellt sicher das die
        % der Gesamtprozess auch bei fehlerhaften Bindings nicht ausf�llt
        function tryEval(this,varargin)
            try
                this.eval()
            catch ME
                if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                   delete(this); 
                end
                disp(ME.message)
            end
        end
    end
    
    % Abstrakte Methoden die durch die Subklassen Implementiert werden m�ssen
    methods (Abstract)
        
        % Die �bertragungsfunktion der Subklassen
        eval(this)
    end
end