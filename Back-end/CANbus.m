
classdef CANbus < StateObject
    properties
        channel;
        msg_robot = 0;
        msg_meas = 0;
        counter = 0;
    end
    
    methods
        % Konstruktor
        function this = CANbus(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        function init(this)
            try
                this.channel = canChannel('PEAK-System','PCAN_USBBUS1');
                % Versuche Channel zu starten 
                try
                    this.startChannel();
                % Ansonsten versuche den Channel zuerst zu schlie�en
                catch
                    this.stopChannel();
                    this.startChannel();
                end
                this.setStateInactive('Initialisiert');
            catch ME
               this.setStateError('Initialisierung fehlgeschlagen'); 
               this.logger.error(ME.message);
            end
        end
        % Destruktor
        function delete(this)
            try
                this.stopChannel();
            end
        end
        % Kanal starten
        function startChannel(this)
            start(this.channel);
            this.channel.MessageReceivedFcn = @this.receiveMsg;
            this.channel.MessageReceivedFcnCount = 1;
            

        end
        % Kanal stoppen
        function stopChannel(this)
            stop(this.channel);
        end
        % Nachricht senden
        function sendMsg(this, canID, data)
%             this.setStateActive('Sende Nachricht');
            % Versuche die Nachricht zu senden
            try
                msg = canMessage(canID, false, 1);
                msg.Data = data;
                transmit(this.channel,msg);
            % Ansonsten gibt einen Fehler aus
            catch ME
                this.setStateError('Fehler beim Senden der CAN-Nachricht');
                rethrow(ME)
            end
%             this.setStateInactive('Betriebsbereit');
        end
        % Nachricht empfangen
        function receiveMsg(this,ch)
%             this.setStateActive('Empfange Nachricht');
            msg = receive(ch, Inf);
            msg_1 = msg(1);
            analyseData(this,msg_1);
            
            if(length(msg) > 1)
                msg_2 = msg(2);
                analyseData(this,msg_2);
            end
%             this.setStateInactive('Betriebsbereit');
        end

        function analyseData(this,msg)
            switch msg.ID
                case 256 % Nachrichten von MicroMod0 (Roboter)
                    this.counter = this.counter +1;
                    if (this.msg_robot ~= msg.Data || this.counter >=10) % Wird bei Status�nderung oder alle 500ms aufgerufen
%                         disp('CANbus.m --> Roboterdaten aktualisiert');
                        this.msg_robot = msg.Data;
                        notify(this, 'Status_Robot_Changed');
                        this.counter = 0;
                    end
                    this.msg_robot = msg.Data;
                    
                case 257 % Nachrichten von MicroMod1 (Messsystem)
                     if this.msg_meas ~= msg.Data
%                         disp('CANbus.m --> Messsystemdaten ver�ndert');
                        this.msg_meas = msg.Data;
                        notify(this, 'Status_Measure_Changed');
                     end
                     this.msg_meas = msg.Data;
                 
                case 259
                    if msg.Data == 1
%                         disp('CANbus.m --> Lichtschranke unterbrochen');
                        notify(this,'LightBarrierInterruption');
                    else
%                         disp('CANbus.m --> Lichtschranke nicht mehr unterbrochen');
                    end
                case 518
%                     this.logger.info('Nachricht erhalten');
                    notify(this, 'StartMeasurement')
                     
             end
        end
        % Dummy-Funktion, die ein Signal vom Roboter simuliert, dass ein
        % neues Objekt zur Verf�gung steht
        function new(this)
            this.sendMsg(259, 1);
        end
        function startConveyorBelt(this)
            this.sendMsg(002, 1);
        end
        function stopConveyorBelt(this)
            this.sendMsg(002, 0);
        end
        function systemReady(this)
            this.sendMsg(001, 1);
        end
        function systemBusy(this)
            this.sendMsg(001, 0);
        end
        function status = statusLightBarrier1(this)
            status = bitget(this.msg_robot,5);
        end
        
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
    
    events
        Status_Robot_Changed;
        Status_Measure_Changed;
        NewPaperObject;
        StartConveyorBelt;
        StopConveyorBelt;
        SystemBusy;
        SystemReady;
        TakePhotos;
        Take3DImage;
        ClassifyCNN;
        LightBarrierInterruption;
        StartMeasurement;
    end
end