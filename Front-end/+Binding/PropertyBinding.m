classdef PropertyBinding < Binding.Binding    
    % Binding um ein Objektattribut auf ein anderes Objektattribut zu übertragen.
    properties(Access = private)
        source_object
        source_prop_name
        target_object
        target_prop_name
        listener
    end
    
    methods
        % Konstruktor
        % Akzeptiert:
        %   ( 1 Quellobjekt + 1 Quellattributnamen ) +
        %   n * ( 1 Zielobjekt + 1 Zielattributnamen )
        function this = PropertyBinding(source_object,source_prop_name,target_object,target_prop_name,varargin)
            this.source_object = source_object;
            this.source_prop_name = source_prop_name;
            this.target_object = {target_object};
            this.target_prop_name = {target_prop_name};
            if ~isempty(varargin)
                if mod(length(varargin),2)
                    error('Unmatched number of input arguments')
                end
                this.target_object = [this.target_object, varargin(1:2:end)];
                this.target_prop_name = [this.target_prop_name, varargin(2:2:end)];
            end
            
            this.listener = addlistener(source_object,source_prop_name,'PostSet', @this.tryEval);
        end
        
        % Übertragungsfunktion
        function eval(this)
            source = this.source_object.(this.source_prop_name);
            for i = 1:length(this.target_object)
                this.target_object{i}.(this.target_prop_name{i}) = source;
            end
        end
    end
end

