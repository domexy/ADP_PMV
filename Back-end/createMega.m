% Hilfsfunktion um erstellung des verwendeten Arduinoobjektes zu
% vereinheitlichen.
function this = createMega()
    this = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');
end

