%##############
% ACHTUNG: optische Aufheller müssen noch angepasst werden !!!
%           manchmal wird ein Teil des Hintergrunds als Objekt erkannt
%           (z.B. Nr 327 oder 379 +/- 1 oder 2)
%##############

classdef DataAnalyzer < handle
    properties
        imgRGB
        imgHSV
        img2HSV
        imgUV
        imgBW
%         roi = [45 15 445 635]; 
%         imgSize = [534 676];
%         roi = [200 70 1733 2525]; 
        roi = [293 121 1733 2565]; 
        imgSize = [2134 2704];
        regionprops
        
        features
        classifier
    end
    
% 1	Masse
% 2	Länge
% 3	Breite
% 4	Fläche
% 5	Quadratigkeit
% 6	Flächenmasse
% 7	Anteil Schwarz
% 8	Anteil Dunkelgrau
% 9	Anteil Grau
% 10	Anteil Braun
% 11	Anteil Weiß
% 12	Mittelwert Farbton
% 13	Std.Abw. Farbton
% 14	Mittelwert Stättigung
% 15	Std.Abw. Sättigung
% 16	Mittelwert Helligkeit
% 17	Std. Abw. Helligkeit
% 18	Textur
% 19	Mittelwert Optische Aufheller
% 20	Std.Abw. Optischer Aufheller
    
    methods
        function this = DataAnalyzer()
            load('paperClassifier.mat', 'paperClassifier');
            this.classifier = paperClassifier;
        end
        
        function extractFeatures(this, imgRGB, imgUV, mass)
%             if nargin == 4
%                 this.imgUV = imread(img2);
%                 this.features(1) = mass;
%             elseif nargin == 3
%                 this.imgUV = imread(img2);
%                 this.features(1) = 1;
%             else
%                 this.imgUV = imread(img);
%                 this.features(1) = 1;
%             end
                    
            this.imgRGB = imgRGB;
            this.imgUV = imgUV;
            this.features(1) = mass;
            
            this.img2binary();
            this.roi2img();     % Randbereiche abschneiden       
            this.extractRegionprops();
            
            this.imgRGB2imgHSV;
            this.extractColorFeatures();
        end
        
        function classifyObject(this)
            prediction = this.classifier.predictFcn(this.features) 
        end
        
        function img2binary(this)
            mask = zeros(this.imgSize(1),this.imgSize(2));
            mask(this.roi(1):(this.roi(1)+this.roi(3)),this.roi(2):(this.roi(2)+this.roi(4))) = 1;

            % Weichzeichner anwenden
            step2 = imgaussfilt(this.imgRGB,1);

            % Umwandlung in Biärbild
            step3 = im2bw(step2,0.12);

            % Binärbild maskieren, sodass nur der ROI betrachtet wird
            step4 = step3 .* mask;
            
            % Kleine weiße Objekte entfernen
            step5 = bwareaopen(step4, 5000);

            % schwarze Löcher in Binärbild entfernen
            this.imgBW = logical(imfill(step5,'holes'));
        end
        
        function imgRGB2imgHSV(this)
            this.imgHSV = rgb2hsv(this.imgRGB);

        end
        
        function roi2img(this)
            this.imgRGB = this.imgRGB .* uint8(this.imgBW);
 
        end
        
        function extractRegionprops(this)
%             figure(1)
%             imshow(this.imgRGB);
            figure(2)
            imshow(this.imgBW);
            hold on
            
            this.regionprops = regionprops(this.imgBW, 'Centroid','Area', 'BoundingBox', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');
            bBoxes = cat(1, this.regionprops.BoundingBox);
            majorAxis = cat(1, this.regionprops.MajorAxisLength);
            minorAxis = cat(1, this.regionprops.MinorAxisLength);
            if length(this.regionprops) > 0
                [maxVal, maxIdx] = max([this.regionprops.Area]);
                rectangle('Position', bBoxes(maxIdx,1:4),'EdgeColor','r', 'LineWidth', 1)
                
                hold off
            end
            
            this.features(2) = majorAxis(maxIdx);
            this.features(3) = minorAxis(maxIdx);
            this.features(4) = maxVal;
            this.features(5) = minorAxis(maxIdx) / majorAxis(maxIdx);
            this.features(6) = this.features(1) / maxVal;
            
            figure(1)
            imshow(this.imgRGB)

            t = linspace(0,2*pi,50);

            hold on
            for k = 1:length(this.regionprops)
                a = this.regionprops(k).MajorAxisLength/2;
                b = this.regionprops(k).MinorAxisLength/2;
                Xc = this.regionprops(k).Centroid(1);
                Yc = this.regionprops(k).Centroid(2);
                phi = deg2rad(-this.regionprops(k).Orientation);
                x = Xc + a*cos(t)*cos(phi) - b*sin(t)*sin(phi);
                y = Yc + a*cos(t)*sin(phi) + b*sin(t)*cos(phi);
                plot(x,y,'r','Linewidth',1)
            end
            hold off
        end
        
        function extractColorFeatures(this)
            black = this.channelsInRangeProportion(this.imgHSV,[2 0.01 0.5],[3 0 0.1]);
            darkGray = this.channelsInRangeProportion(this.imgHSV,[2 0 0.5],[3 0.1 0.4]);
            lightGray = this.channelsInRangeProportion(this.imgHSV,[2 0 0.5],[3 0.4 0.47]);
            white = this.channelsInRangeProportion(this.imgHSV,[2 0 0.5],[3 0.47 1]);
            brown = this.channelsInRangeProportion(this.imgHSV,[1 20/360 40/360],[2 0.5 1]);
            total = black + darkGray + lightGray + white + brown;
%             disp([black darkGray lightGray white brown total]);

            [meanHue,stdHue] = this.channelMeanSigma(this.imgHSV,1);
            [meanSaturation,stdSaturation] = this.channelMeanSigma(this.imgHSV,2);
            [meanValue,stdValue] = this.channelMeanSigma(this.imgHSV,3);
            
            
            [meanValueUV,stdValueUV] = this.channelMeanSigma(rgb2hsv((2*this.imgUV-this.imgRGB).*uint8(this.imgBW)),3);
            

            this.features(7) = black;
            this.features(8) = darkGray;
            this.features(9) = lightGray;
            this.features(10) = brown;
            this.features(11) = white;
            this.features(12) = meanHue;
            this.features(13) = stdHue;
            this.features(14) = meanSaturation;
            this.features(15) = stdSaturation;
            this.features(16) = meanValue;
            this.features(17) = stdValue;
            this.features(19) = meanValueUV;
            this.features(20) = stdValueUV;
        end
        
        function extractMassFeatures(this)
            features(5) = this.mass;
            features(6) = this.mass 
        end
    end
    
    
    
    methods(Static)
        
        function [mu, sig] = channelMeanSigma(img, channelNo)
        %CHANNELMEANSIGMA - Berechnet Mittelwert und Standardabweichung
        %eines Kanals eines Fotos. Die Funktion Funktion kann daher z.B. dazu
        %verwendet werden, die mittlere Farbtonsättigung und Standardabweichung eines
        %Papierobjekts zu berechnen, indem ein HSV-Foto und die Kanalnummer
        %2 für die Sättigungs-Kanal übergeben wird. Nullen werden als
        %Hintergrund gewertet und daher nicht die Berechnung mit einbezogen
        %
        % Syntax:  [mu, sig] = channelMeanSigma(img, channelNo)
        %
        % Inputs:
        %    img - Bild-Matrix der Form (Länge x Breite x Kanäle)
        %    channelNo - Nummer des zu verwendenden Kanals
        %
        % Outputs:
        %    mu - Mittelwert des Kanal
        %    sigma - Standardabweichung des Kanals
        %
        % Example: 
        %    % Mittlere Farbtonsättigung berechnen:
        %    [mu, sig] = this.channelMeanSigma(this.imgHSV, 2)
        %
        %------------- BEGIN CODE --------------    
            channel = img(:,:,channelNo);
            channel(channel == 0) = NaN;
            mu = mean(channel(:),'omitnan');
            sig = std(channel(:),'omitnan');


        end
        
        function proportion = channelsInRangeProportion(img, varargin)
        %CHANNELSINRANGEPROPORTION - Berechnet den Anteil der Pixel, die
        %eine oder mehrere Bedingungen an die Kanäle erfüllen. So kann
        %beispielweise der Anteil an weißen Pixeln bestimmt werden, indem
        %ein HSV-Foto und einen Vektor mit dem Value-Kanal 3 mit dem
        %Minimalwert 0.99 und dem Maximalwert 1 übergeben wird. Mehrere
        %Bedingungen können durch mehrere solcher Vektoren gefordert
        %werden.
        %Nullen werden als Hintergrund gewertet und daher nicht die Berechnung mit einbezogen
        %
        % Syntax:  proportion = channelsInRangeProportion(img, varargin)
        %
        % Inputs:
        %    img - Bild-Matrix der Form (Länge x Breite x Kanäle)
        %    varargin - Vektoren der Form [Kanal minWert maxWert]
        %
        % Outputs:
        %    proportion - Prozentualer Anteil der Pixel, die die
        %    Bedingungen erfüllen
        %
        % Example: 
        %    % Anteil an weißen Pixeln berechnen
        %    [mu, sig] = this.channelsInRangeProportion(this.imgHSV, [3, 0.99, 1])
        %
        %------------- BEGIN CODE --------------
            channel = [];
            minValue = [];
            maxValue = [];

            for i = 2:nargin
                arg = varargin{i-1};
                id = length(channel) + 1;
                channel(id) = arg(1);
                minValue(id) = arg(2);
                maxValue(id) = arg(3);
            end

            for i = 1:length(channel)

                matrix = img(:,:,channel(i));
                mask = (matrix >= minValue(i)) .* (matrix <= maxValue(i));
                if (i == 1)
                    totalMask = mask;
                else
                    totalMask = totalMask .* mask;
                end

            end


            pixel = sum(totalMask(:) == 1);

            proportion = pixel / sum(matrix(:) ~= 0);

        end

  
    end
end