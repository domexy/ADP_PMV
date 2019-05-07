classdef HandoffMediator   < handle
    properties
        requestor
        recipient
        listenerStart
    end
    
    methods
        function this = HandoffMediator(requestor,recipient)
            %HANDOFFNEGOTIATOR Construct an instance of this class
            %   Detailed explanation goes here
            this.requestor = requestor;
            this.recipient = recipient;
            
        end
        
        function prepareHandoff(this,~,~)
            
        end
        
        function executeHandoff(this,~,~)
            this.recipient.method1()
        end
    end
end

