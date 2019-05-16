classdef ObjectDetection < StateObject
    % Verwendete Module und Subklassen
    properties
        cam
        cam2
        % Diese Attribute wurden aus historischen Gründen hier belassen
        roi = [58 429 307 194];
        roiMask
        imgSize
        small_object_threshold = 1000;
    end
    
    % Beobachtbare Zustände
    properties(SetAccess = private, SetObservable)
        frame
    end
    
    methods
        % Erstellt das Objekt
        function this = ObjectDetection(logger)
            if nargin < 1
                logger = [];
            end
            this = this@StateObject(logger);
        end
        
        % Initialisiert das Objekt und macht es funktional
        function init(this)
            try
                this.cam = webcam('C922 Pro Stream Webcam');
                this.cam.FocusMode = 'manual';
                this.cam.Focus = 0;
                this.cam.ExposureMode = 'manual';


                this.imgSize = [480 640];
                this.roiMask = createRoiMask(this);
                this.autoExposure();

                this.setStateInactive('Initialisiert');
            catch ME
               this.setStateError('Initialisierung fehlgeschlagen'); 
               this.logger.error(ME.message);
            end
        end
        
        % Stellt die Beleuchtung ein
        function autoExposure(this)
            this.setStateActive('Belichtungszeit einstellen...');
            for i=-9:-2
                this.cam.Exposure = i;
                pause(0.5)
                if this.objectOnTable == true
                    this.cam.Exposure = i-1;
                    break;
                end                
            end
            this.logger.debug(['Belichtungszeit auf ', num2str(this.cam.Exposure), ' gesetzt'])
            this.setStateInactive('Betriebsbereit');                
        end
        
        % Foto mit Webcam aufnehmen und bearbeiten
        function pic = takePicture(this)
            this.setStateActive('Foto Aufnehmen');
            frame1 = snapshot(this.cam);
            
            % Weichzeichner anwenden
            frame2 = imgaussfilt(frame1,5);
            
            % Umwandlung in Biï¿½rbild
            frame3 = im2bw(frame2,0.27);
            
            % Binärbild maskieren, sodass nur der ROI betrachtet wird
            frame4 = frame3 .* this.roiMask;

            % schwarze Löcher in Binärbild entfernen
            frame5 = logical(imfill(frame4,'holes'));
            
            pic = frame5;
            this.setStateInactive('Foto aufnehmen beendet');
        end
        
        % Maske für Region of Interest erstellen
        function mask = createRoiMask(this)
            mask = zeros(this.imgSize(1),this.imgSize(2));
            mask(this.roi(1):(this.roi(1)+this.roi(3)),this.roi(2):(this.roi(2)+this.roi(4))) = 1;

        end
        
        % Schauen, ob Objekt auf Objekttisch liegt
        function status = objectOnTable(this)
            status = 0;
            this.setStateActive('Objekt detektieren');
            % Foto aufnehmen
            img = this.takePicture();
            
            % Schwerpunkte aller Objekte auf Binï¿½rbild finden
            s = regionprops(img, 'Centroid','Area', 'BoundingBox');
            
            % Kleine Objekte aussortieren
            smallObjectIds = find([s.Area] < this.small_object_threshold);
            s(smallObjectIds) = []; 
            
            if (length(s) > 0)
                this.logger.info('Objekt auf dem Tisch');
                status = 1;
            else
                this.logger.warning('Kein Objekt auf dem Tisch');
            end
            this.setStateInactive('Betriebsbereit');
        end
        
        % Objekt lokalisieren
        function [x,y, success] = locateObject(this)
            this.setStateActive('Objekt lokalisieren');
            % Foto aufnehmen
            img = this.takePicture();
%             
%             % Weichzeichner anwenden
%             frame2 = imgaussfilt(frame1,7);
%             
%             % Umwandlung in Biï¿½rbild
%             frame3 = im2bw(frame2,0.5);
%             
%             % Binï¿½rbild maskieren, sodass nur der ROI betrachtet wird
%             frame4 = frame3 .* this.roiMask;
% 
%             
%             % schwarze Lï¿½cher in Binï¿½rbild entfernen
%             frame5 = logical(imfill(frame4,'holes'));
            

            % Schwerpunkte aller Objekte auf Binï¿½rbild finden
            s = regionprops(img, 'Centroid','Area', 'BoundingBox');
            figure(2)
            imshow(img)
            hold on
            % Kleine Objekte aussortieren
            smallObjectIds = find([s.Area] < this.small_object_threshold);
            s(smallObjectIds) = [];
            centroids = cat(1, s.Centroid);
            bBoxes = cat(1, s.BoundingBox);
            
            % Falls mindestens ein Objekt gefunden wurde
            if length(s) > 0
                % Kontrollfoto fï¿½r Schwerpunkte anzeigen
                
                plot(centroids(:,1),centroids(:,2), 'r*')
                hold on 

                % Pixel-Koordinaten des grï¿½ï¿½ten Objekts fï¿½r Rï¿½ckgabe
                % bestimmen

                [maxVal, maxIdx] = max([s.Area]);
                
                rectangle('Position', bBoxes(maxIdx,1:4),'EdgeColor','r', 'LineWidth', 1)
                hold off
                
                px = centroids(maxIdx,1);
                py = centroids(maxIdx,2);

                disp(num2str([px,py]))
                [x,y] = this.pixelToCoords(px,py);
                
                success = 1;
            % Falls kein Objekt gefunden wurde
            else
                x = 0;
                y = 0;
                success = 0;
            end
        end
        
        % Umrechnung von Pixel-Koordinaten in Roboterkoordinaten
        function [x,y] = pixelToCoords(this, px, py)
            % Roboter X-Achse ist Kamera Y-Achse !
            % Roboter Y-Achse ist Kamera X-Achse !
            
            % x-Richtung --> x(px) = m*px+t
            % f(173px) = -440 mm
            % f(354px) = -728 mm
            % Berechnung: [m,t] = [173 1; 354 1] \ [-440; -728]
            % m = -1.591    t = -164.7
            y = -1.591*py -164.7;

            % y-Richtung --> y(py) = m*py+t
            % f(591px) = 86 mm
            % f(468px) = -107 mm
            % Berechnung: [m,t] = [591 1; 468 1] \ [86; -107]
            % m = 1.569   t = -841.3
            x = 1.569*px -841.3;
            
            this.logger.info(['Bild: [',num2str(px),', ',num2str(py),'] -> Roboter: [',num2str(x),', ',num2str(y),']' ]);
        end
        
        % Umkehrfunktion von pixelToCoords
        function [px, py] = coordsToPixel(this,x,y)
            px = (x+164.7)/-1.591;
            py = (y+841.3)/1.569;
            this.logger.info(['Roboter: [',num2str(x),', ',num2str(y),'] -> Bild: [',num2str(px),', ',num2str(py),']']);
        end
        
        % Methode zur Zustandsbestimmung
        function updateState(this)
            if this.getState ~= this.OFFLINE
                
            end
        end
        
        % Reaktion des Objektes auf Zustandsänderung
        function onStateChange(this)
            if ~this.isReady()

            end
        end
    end
end
