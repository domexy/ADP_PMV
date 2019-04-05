classdef test < handle
    properties
        handle;
        var;
    end
    
    methods
        function this = test()
            this.handle = app2(this);
            this.var = 0;
        end
        
        function run(this)
            while 1
                pause(1)
                this.var = this.var +1;
            end
        end
    end
end
            
