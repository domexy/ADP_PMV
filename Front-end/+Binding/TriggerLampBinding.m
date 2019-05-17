classdef TriggerLampBinding < Binding.Binding
    % Binding um den booleschen Zustand eines Objektattributs auf eine UILamp zu übertragen
    
    % Mapping von Zuständen auf Farben
    % Zugriff über Setter kontrolliert, damit die Feldnamen nicht
    % kompromitiert werden
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
        % Konstruktor
        % Akzeptiert:
        %   1 Objekt + 1 Attributnamen
        %   n * ( 1 UILamp )
        function this = TriggerLampBinding(source_object, source_prop_name, lamp,varargin)
            this.source_object = source_object;
            this.source_prop_name = source_prop_name;
            this.lamp = {lamp};
            if ~isempty(varargin)
                this.lamp = [this.lamp, varargin(1:end)];
            end
            
            this.listener = addlistener(source_object,source_prop_name,'PostSet', @this.tryEval);
        end
        
        % Übertragungsfunktion
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
        
        % Setter für Farbe bei Aktivität
        function setActiveColor(this, color)
            if size(color) ~= 3
               return 
            end
            this.lamp_colors.ACTIVE = color;
        end
        
        % Setter für Farbe bei Inaktivität
        function setInActiveColor(this, color)
            if size(color) ~= 3
               return 
            end
            this.lamp_colors.INACTIVE = color;
        end
    end
end

