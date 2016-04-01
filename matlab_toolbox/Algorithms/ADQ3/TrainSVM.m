clear all;
load('TrainingFeature.mat');
rng('shuffle')

% The percentage of data to be used for training. If less than 1, the rest
% will be used for evaluation.
TrainRatio=1;

for QualityInd=1:length(SingleFeatures)
    nDoubleExamples=length(DoubleFeatures{QualityInd});
    nSingleExamples=length(SingleFeatures{QualityInd});
    nTrainSingle=ceil(nSingleExamples*TrainRatio);
    nTrainDouble=ceil(nDoubleExamples*TrainRatio);
    
    %---Train by replicating Single Compression Examples
    %ClassRatio=floor(nDoubleExamples/nSingleExamples);
    %TrainData=[DoubleFeatures{QualityInd}(1:nTrainDouble,:);repmat(SingleFeatures{QualityInd}(1:nTrainSingle,:),ClassRatio,1)];
    %TrainLabels=[ones(nTrainDouble,1);zeros(ClassRatio*nTrainSingle,1)];
    %EvalData=[DoubleFeatures{QualityInd}(nTrainDouble+1:end,:);repmat(SingleFeatures{QualityInd}(nTrainSingle+1:end,:),ClassRatio,1)];
    %EvalLabels=[ones(nDoubleExamples-nTrainDouble,1);zeros(ClassRatio*(nSingleExamples-nTrainSingle),1)];
    
    %---Train by subsampling Double Compression Examples
    %DoublesRandomizer=randperm(length(DoubleFeatures{QualityInd}));
    %TrainData=[DoubleFeatures{QualityInd}(DoublesRandomizer(1:nTrainSingle),:);SingleFeatures{QualityInd}(1:nTrainSingle,:)];
    %TrainLabels=[ones(nTrainSingle,1);zeros(nTrainSingle,1)];
    %EvalData=[DoubleFeatures{QualityInd}(DoublesRandomizer(nTrainSingle+1:length(SingleFeatures{QualityInd})),:);SingleFeatures{QualityInd}(nTrainSingle+1:length(SingleFeatures{QualityInd}),:)];
    %EvalLabels=[ones(nSingleExamples-nTrainSingle,1);zeros(nSingleExamples-nTrainSingle,1)];
    
    %---Train without class balancing
    TrainData=[DoubleFeatures{QualityInd}(1:nTrainDouble,:);SingleFeatures{QualityInd}(1:nTrainSingle,:)];
    TrainLabels=[ones(nTrainDouble,1);zeros(nTrainSingle,1)];
    EvalData=[DoubleFeatures{QualityInd}(nTrainDouble+1:end,:);SingleFeatures{QualityInd}(nTrainSingle+1:end,:)];
    EvalLabels=[ones(nDoubleExamples-nTrainDouble,1);zeros(nSingleExamples-nTrainSingle,1)];
    
    TrainData=TrainData/64;
    EvalData=TrainData/64;
    options.MaxIter=50000;
    
    Model = svmtrain(TrainData,TrainLabels,'autoscale',false,'kernel_function','mlp','options',options);
    if TrainRatio<1
        [TrainRun, TrainDists] = svmclassify_dist(Model,TrainData);
        [EvalRun, EvalDists] = svmclassify_dist(Model,EvalData);
        TruePositives=sum(EvalRun==EvalLabels & EvalLabels==1);
        FalsePositives=sum(EvalRun~=EvalLabels & EvalLabels==0);
        FalseNegatives=sum(EvalRun~=EvalLabels & EvalLabels==1);
        
        EvalPrec=sum(TruePositives/(TruePositives+FalsePositives));
        EvalRec=sum(TruePositives/(TruePositives+FalseNegatives));
        disp(['Eval precision: ' num2str(EvalPrec) ' Eval recall: ' num2str(EvalRec)])
        disp(' ');
    end
    SVMStruct{QualityInd} = Model;
end
save('SVMs.mat','SVMStruct');