classdef Fcn2PropertyBinding < Binding.Binding  
    % Binding um das Auswertergebnis einer Funktion auf ein Objektattribut
    % zu übertragen.
    properties(Access = public)
        source_fcn_handle
        target_object
        target_prop_name
    end
    
    methods
        % Konstruktor
        % Akzeptiert:
        %   1 Function-handle +
        %   n * ( 1 Zielobjekt + 1 Zielattributnamen )
        function this = Fcn2PropertyBinding(source_fcn_handle,target_object,target_prop_name,varargin)
            this.source_fcn_handle = source_fcn_handle;
            this.target_object = {target_object};
            this.target_prop_name = {target_prop_name};
            if ~isempty(varargin)
                if mod(length(varargin),2)
                    error('Unmatched number of input arguments')
                end
                this.target_object = [this.target_object, varargin(1:2:end)];
                this.target_prop_name = [this.target_prop_name, varargin(2:2:end)];
            end
        end
        
        % Übertragungsfunktion
        function eval(this)
            source = this.source_fcn_handle();
            for i = 1:length(this.target_object)
                this.target_object{i}.(this.target_prop_name{i}) = source;
            end
        end
    end
end

