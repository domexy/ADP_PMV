[p, g] = startGUI();
mega = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');
p.isoDevice.robot.gripper.init(mega);
g.IsolationDevice_TabGroup.Visible = true;