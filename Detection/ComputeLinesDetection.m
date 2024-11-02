function [waterLines, bedLines] = ComputeLinesDetection(imageNameList, dp, ...
    waterdata)
% Compute bedlines and waterlines on a sequence of images
% 
% NB : The algorythm is made for the parforloop (see "RunBedLineDetection" 
% algorythm for (maybe) better performance on simple forloop).

% Set boolean rather to detect waterlines or just copy content from waterdata
if nargin==3 && ~isempty(waterdata) && length(waterdata{1})==dp.bwlROI(3)
    detectwaterline = 0;
else
    detectwaterline = 1;
end

% define some variables
imSize = [dp.bwlROI(4),dp.bwlROI(3)];
midNbImForAverage = ceil(dp.nbImForAverage/2);
bottomLine = imSize(1)*ones(1,imSize(2),'uint16'); %here is just the first line of pixels
roi = {[dp.bwlROI(2)+1,dp.bwlROI(2)+dp.bwlROI(4)],...
    [dp.bwlROI(1)+1,dp.bwlROI(1)+dp.bwlROI(3)]};

% initialize detection cell array
waterLines = cell(1,dp.bwlNtot);
bedLines = cell(1,dp.bwlNtot);

% compute lines detection
v=ver;
if dp.boolComputeParallel && find(ismember({v.Name},'Parallel Computing Toolbox'))
    nbW = parcluster(parallel.defaultClusterProfile).NumWorkers;
    if isempty(gcp('nocreate')) && nbW~=0, parpool(nbW); end 
    t = now;
    ParforProgress(t,dp.bwlNtot);
    parfor i=1:dp.bwlNtot
        % get images
        images = zeros([imSize,dp.nbImForAverage],'uint8');
        for k = 1:dp.nbImForAverage
            m = i - 1 + k - midNbImForAverage;
            if m>=0 && m<=dp.bwlNtot-1
                images(:,:,k) = imread(imageNameList{dp.bwlStart + ...
                    m*dp.bwlStep},'PixelRegion',roi);
            end
        end
        
        % detect waterline if needed or just copy data from waterdata
        if detectwaterline==1
            waterLines{i} = DetectWaterLine(images(:,:,midNbImForAverage), ...
                dp.threshWaterLineStd);
        else
            waterLines{i} = waterdata{dp.bwlStart + (i-1)*dp.bwlStep};
        end
        
        % detect bedline on previously averaged images to get rid of moving particles
        averageImage = uint8(ExtractBackground(images));
        bedLines{i} = uint16(DetectBedLine(averageImage,bottomLine,waterLines{i}, ...
            dp.threshBedLine));
    
        ParforProgress(t,0,i);
    end
    ParforProgress(t,0);
    delete(gcp('nocreate'));
else
    t = now;
    ParforProgress(t,dp.bwlNtot);
    for i=1:dp.bwlNtot
        % get images
        images = zeros([imSize,dp.nbImForAverage],'uint8');
        for k = 1:dp.nbImForAverage
            m = i - 1 + k - midNbImForAverage;
            if m>=0 && m<=dp.bwlNtot-1
                images(:,:,k) = imread(imageNameList{dp.bwlStart + ...
                    m*dp.bwlStep},'PixelRegion',roi);
            end
        end
        
        % detect waterline if needed or just copy data from waterdata
        if detectwaterline==1
            waterLines{i} = DetectWaterLine(images(:,:,midNbImForAverage), ...
                dp.threshWaterLineStd);
        else
            waterLines{i} = waterdata{dp.bwlStart + (i-1)*dp.bwlStep};
        end
        
        % detect bedline on previously averaged images to get rid of moving particles
        averageImage = uint8(ExtractBackground(images));
        bedLines{i} = uint16(DetectBedLine(averageImage,bottomLine,waterLines{i}, ...
            dp.threshBedLine));
    
        ParforProgress(t,0,i);
    end
    ParforProgress(t,0);
end
