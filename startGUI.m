function [process_handle, gui_handle] = startGUI()
addpath(genpath('Front-end'))
addpath(genpath('Back-end'))

logger_handle = Logger.Logger();

process_handle = '';
% process_handle = Process();

gui_handle = ProcessGUI(process_handle, logger_handle);

end

