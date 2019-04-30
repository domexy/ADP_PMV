function [process, gui] = startGUI(process)
addpath(genpath('Front-end'))
addpath(genpath('Back-end'))

logger = Logger.Logger();

logger.info('Starte GUI...');

% process_handle = '';
if nargin < 1
    logger.info('Starte Prozessgenerierung...');
    process = Process(logger);
    logger.info('Prozessgenerierung abgeschlossen!')
    process_initialized = false;
else
    logger.info('Initialisierter Prozess übergeben!')
    process.logger.log_remote_fcn_active = 0;
    process_initialized = true;
end
pause(0.001)
logger.info('Starte GUI-Generierung...');
gui = ProcessGUI(process, logger);
logger.info('GUI-Generierung abgeschlossen!')

if process_initialized
    process.logger.log_remote_fcn_handle = @(varargin)gui.logToTable(varargin{:});
    process.logger.log_remote_fcn_active = 1;
    gui.Init_Button.Enable = false;
    gui.Start_Button.Enable = true;
end

end

