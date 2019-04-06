classdef Classifier < handle
    properties
        model;
        modelCNN;
        CNN;
        trainingData;
        trainingLabels;
        featMean;
        featStd;
    end
    
    methods
        function this = Classifier()
            % Traingsdaten und entsprechende Labels laden
            % Diese sind dann in den Variablen trainingData und
            % trainingLabels gespeichert.
            load('.\Data\TrainingDataLabels.mat')
            load('.\Data\TrainingMeanStd.mat')
            this.trainingData = trainingData;
            this.trainingLabels = trainingLabels;
            this.featMean = featMean;
            this.featStd = featStd;
%             load('\Data\TrainingDataLabels.mat')
            % Model mit Trainingsdaten trainieren
            this.model = fitcecoc(trainingData, trainingLabels);
            
            % AlexNet mit Transfer Learning:
            load('.\Data\CNN.mat')
%             % Trainierte Support Vector Machine
%             load('C:\Users\Lokal\Desktop\Datenaufnahme_NEU\OOP\Data\modelCNN.mat')
            this.CNN = CNN;
%             this.modelCNN = modelCNN;
        end
        function result = classifyObject(this, data)
            % Trainiertes Model verwenden, um mit Hilfe der normierten
            % Daten des aktuellen Objekts das Objekt zu klassifizieren
%             data
            dataNorm = this.normalizeData(data);
            disp('Classifier.m --> Objekt klassifiziert');
            result = predict(this.model, dataNorm);
        end
        function predictedLabel = classifyCNN(this, img)
            predictedLabel = classify(this.CNN,img);
        end
        function data = normalizeData(this, data)
            % Daten werden auf gleiche Weise normiert wie Trainingsdaten.
            % Parameter wurden so bestimmt, dass Trainingsdaten für jede
            % Objekteingeschaft einen Mittelwert von µ = 0 und eine
            % Standardabweichung von s = 1 besitzen, da es so zu einer
            % gleichen Gewichtung der Merkmale kommt.
            disp('Classifier.m --> Messdaten normalisiert');
            data = (data-this.featMean)./(this.featStd);
        end
    end
    
    events
    end
end