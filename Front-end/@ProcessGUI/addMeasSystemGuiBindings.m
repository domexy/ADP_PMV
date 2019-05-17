function addMeasSystemGuiBindings(app,binding_logger)
% FÜGT BINDINGS ZUR GUI HINZU

    meas_bm = Binding.BindingManager('Measurement_System',binding_logger);
            app.binding_managers.meas = meas_bm;

    weiss_lamp_b = Binding.TriggerLampBinding(...
                app.process.measSystem.cam.light,'white',...
                app.WeissLamp);
    weiss_lamp_b.setActiveColor([1,1,1]);
    meas_bm.addBinding(... %weiße LEDs
                weiss_lamp_b);
            
    blau_lamp_b = Binding.TriggerLampBinding(...
                app.process.measSystem.cam.light,'blue',...
                app.BlauLamp);
    blau_lamp_b.setActiveColor([0,0,1]);
    meas_bm.addBinding(... %blaue LEDs
                blau_lamp_b);
            
    grun_lamp_b = Binding.TriggerLampBinding(...
                app.process.measSystem.cam.light,'green',...
                app.GrunLamp);
    grun_lamp_b.setActiveColor([0,1,0]);
    meas_bm.addBinding(... %grüne LEDs
                grun_lamp_b);
            
    rot_lamp_b = Binding.TriggerLampBinding(...
                app.process.measSystem.cam.light,'red',...
                app.RotLamp);
    rot_lamp_b.setActiveColor([1,0,0]);
    meas_bm.addBinding(... %rote LEDs
                rot_lamp_b);
            
    uv_lamp_b = Binding.TriggerLampBinding(...
                app.process.measSystem.cam.light,'uv',...
                app.UVLamp);
    uv_lamp_b.setActiveColor([0.72,0.27,1.00]); %Lila
    meas_bm.addBinding(... %uv LEDs
                uv_lamp_b);
            
    meas_bm.addBinding(... %Masse über Waage
                Binding.PropertyBinding(...
                app.process.measSystem.scale, 'mass',...
                app.GewichtEditField, 'Value'));
            
    meas_bm.addBinding(... %Tor
                Binding.TriggerLampBinding(...
                app.process.measSystem,'gate_position',...
                app.TorLamp));
            
    meas_bm.addBinding(... %Förderband in Messzelle
                Binding.TriggerLampBinding(...
                app.process.measSystem.weighingBelt,'is_active',...
                app.MessForderbandAktiv_Lamp));
            
    meas_bm.addBinding(... %Lichtschranke Isolierung
                Binding.TriggerLampBinding(...
                app.process.measSystem,'light_barrier_blocked',...
                app.MeasLichtschrankeLamp));
end

