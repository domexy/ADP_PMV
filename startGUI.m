function [process, gui] = startGUI()
addpath(genpath('Front-end'))
addpath(genpath('Back-end'))

logger = Logger.Logger();

% process_handle = '';
logger.info('Starte Prozessgenerierung...');
process = Process(logger);
logger.info('Prozessgenerierung abgeschlossen!')
pause(0.001)
logger.info('Starte GUI-Generierung...');
gui = ProcessGUI(process, logger);
logger.info('GUI-Generierung abgeschlossen!')

end

