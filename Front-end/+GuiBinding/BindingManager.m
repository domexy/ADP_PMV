classdef BindingManager < handle
    %BINDINGMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bindings = {};
        timer_target_period = 2;
        timer_limited_period = 2;
        timer;
    end
    
    properties (Access = private)
       check_counter = 0;
       check_threshold = 10;
    end
    
    methods
        function this = BindingManager()
            this.timer = timer('BusyMode','drop','ExecutionMode','fixedRate');
            this.timer.Period = this.timer_target_period;
            this.timer.TimerFcn = @(~,~)this.evalBindings;
            this.timer.ErrorFcn = @(~,~)this.restart;
        end
                
        function setPeriod(this, period)
            period = round(period,3);
            if strcmp(this.timer.Running,'on')
                was_on = true;                
                stop(this.timer); 
            else
                was_on = false;
            end
            this.timer_limited_period = period;
            this.timer.Period = period;
            disp(['set period to ',num2str(period)])
            if was_on
                this.timer.start();
            end
        end
        
        function start(this)
            this.check_counter = 0;
            this.timer.start();
        end
        
        function stop(this)
            stop(this.timer);
        end        
        
        function restart(this)
            pause(this.timer_limited_period)
            this.timer.start();
        end
        
        function addBinding(this, binding)
            this.bindings = [this.bindings(:)', {binding}];
        end
        
        function evalBindings(this)
            %Überprüfe ob Periodenlänge Systemverträglich ist
            this.checkPeriod()
            %Ausführen der Bindings
            for i = 1:length(this.bindings)
                try
                    this.bindings{i}.tryEval();
                catch
                    warning(['Binding ', str(this.bindings{i}), ' failed to evaluate'])
                end
            end
        end
    end
    
    methods (Access=private)
        function checkPeriod(this)
            %Überprüfung nur alle this.check_threshold iterationen
            if this.check_counter > this.check_threshold
                this.check_counter = 0;
            else
                return
            end
            this.check_counter = this.check_counter+1;
            
            if isnan(this.timer.InstantPeriod)
                return
            end
            
            %Zielperiode unterschritten,
            if this.timer.Period < this.timer_target_period
                disp('under')
                this.setPeriod(this.timer_target_period)
            end
            if this.timer.InstantPeriod > this.timer_limited_period * 1.2 
                % Timer Periode ist zu kurz, verlängere Periode um System
                % zu entlasten
                disp('overload')
                this.setPeriod(this.timer_limited_period*1.5)
            else
                % System ist nicht ausgelastet, führe Periode an
                % Zielperiode heran
                
                timer_difference = -(this.timer_target_period - this.timer_limited_period)/this.timer_target_period;
                if timer_difference > 0.1
                    disp('underload')
                    this.setPeriod(this.timer_limited_period * 0.9)
                end
            end
        end
    end
end

