classdef BindingManager < handle
    %BINDINGMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bindings = {};
        timer_target_period = 2;
        timer_limited_period = 2;
        timer;
        logger;
        name;
    end
    
    properties (Access = private)
       check_counter = 0;
       check_threshold = 10;
    end
    
    methods
        function this = BindingManager(name, logger)
            if nargin < 2
                if nargin < 1
                    name = num2hex(now());
                    name = name(end-3:end);
                end
                this.logger.debug = @disp;
                this.logger.info = @disp;
                this.logger.warning = @disp;
                this.logger.error = @disp;
            else
                this.logger = logger;
            end
            this.name = name;
            this.timer = timer('Name',this.name,'BusyMode','drop','ExecutionMode','fixedRate');
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
            this.logger.info(['BindingMananger ', this.name, ' set period to ',num2str(period)]);
            disp()
            if was_on
                this.timer.start();
            end
        end
        
        function start(this)
            this.check_counter = 0;
            this.timer.start();
            this.logger.info(['BindingMananger ', this.name, ' started'])
        end
        
        function stop(this)
            stop(this.timer);
            this.logger.info(['BindingMananger ', this.name, ' started'])
        end        
        
        function restart(this)
            pause(this.timer_limited_period)
            this.timer.start();
        end
        
        function addBinding(this, binding)
            this.bindings = [this.bindings(:)', {binding}];
        end
        
        function evalBindings(this)
            %�berpr�fe ob Periodenl�nge Systemvertr�glich ist
            this.checkPeriod()
            %Ausf�hren der Bindings
            for i = 1:length(this.bindings)
                try
                    this.bindings{i}.tryEval();
                catch
                    this.logger.error(['Binding ', str(this.bindings{i}), ' failed to evaluate'])
                end
            end
        end
    end
    
    methods (Access=private)
        function checkPeriod(this)
%             this.logger.debug(['BindingMananger ', this.name, ': ',num2str(this.check_counter),'>',num2str(this.check_threshold)]);
            %�berpr�fung nur alle this.check_threshold iterationen
            if this.check_counter > this.check_threshold
                this.check_counter = 0;
            else
                this.check_counter = this.check_counter+1;
                return
            end
            
            if isnan(this.timer.InstantPeriod)
                return
            end
%             this.logger.debug(['BindingMananger ', this.name, ': PERIOD CHECK!']);
            %Zielperiode unterschritten,
            if this.timer.Period < this.timer_target_period
                this.setPeriod(this.timer_target_period)
            end
            if this.timer.InstantPeriod > this.timer_limited_period * 1.2 
                % Timer Periode ist zu kurz, verl�ngere Periode um System
                % zu entlasten
                this.logger.warning(['BindingMananger ', this.name, ' failed to hold period length @',num2str(this.timer_limited_period), 's'])
                this.setPeriod(this.timer_limited_period*1.5)
            else
                % System ist nicht ausgelastet, f�hre Periode an
                % Zielperiode heran
                
                timer_difference = -(this.timer_target_period - this.timer_limited_period)/this.timer_target_period;
                if timer_difference > 0.1
                    this.logger.warning(['BindingMananger ', this.name, ' has period of ', num2str(this.timer_limited_period), 's, but aims for ', num2str(this.timer_target_period),'s'])
                    this.setPeriod(this.timer_limited_period * 0.9)
                end
            end
        end
    end
end

