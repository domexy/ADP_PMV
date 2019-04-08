classdef testobject < StateObject
    %TESTOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1 = 0;
    end
    
    methods
        function this = testobject(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function method1(this)
            this.setStateActive('test')
            this.setStateActive('test2')
            this.logger.debug('bla')
        end
        
        function updateState(this)
            if this.Property1 <= 0
                this.changeStateError('prop kleiner 0');
            end
        end
    end
end

