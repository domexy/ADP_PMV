% [p, g] = startGUI();
mega = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');
can = CANbus();
can.init();
r = Robot();
r.init(can,mega);
% d = DrumFeeder();
% d.init(can,mega);
% % p.isoDevice.robot.gripper.init(mega);
% % g.IsolationDevice_TabGroup.Visible = true;
% g = Gripper();
% g.init(mega);