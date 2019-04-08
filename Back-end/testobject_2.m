classdef testobject_2 < StateObject
    %TESTOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
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
    end
end

