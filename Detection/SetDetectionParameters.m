function [dp,flagError] = SetDetectionParameters(dsp,imageFullFiles)
% Set the detection parameters from the settable ones.
%
% INPUT ARGUMENTS:
%  dsp           : structure containing the detection settable parameters.
%  imageFullFiles: cell array of image full files.
%
% OUTPUT ARGUMENTS:
%  dp       : structure containing the detection parameters.
%  flagError: boolean saying if an error occured.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.
%
% EDIT 04/22 B.Dedieu : if no demand for beads detection (i.e. just lines
% detection), no need for sequence param file -> see changes line 82.
% Add roi management (bwlROI and ptvROI needed in settable_param file but
% can be set to None or false or 0... if not needed)
% This version needs boolLinesDetection param to be add to settable param file.
% It is made to work with 2022 modified RunDetection version.


%default values
threshBlackBeadDetectMin=25; %minimum threshold of black pixels in case is set automatically  
threshTransBeadDetect=0.25; %threshold of transparent bead detection
threshTransBeadDetectConf=0.20; %threshold of detector confidence of transparent bead detection
threshWaterLineStd=0.25; %threshold of standard deviation to validate water line

%intitalise flagError
flagError=false;
%copy the detection settable parameters
dp=dsp;

%update the detection settable parameters according to booleans
%bool remove base
if dp.boolRemoveBase && ~exist(fullfile(dp.pathImages,dp.baseMaskFile),'file')
    warning('Execution stopped: Inexistent or uncorrect file of base mask.');
    flagError=true;
    return;
elseif ~dp.boolRemoveBase
    dp.baseMaskFile=[];
end
%bool black bead detect (set a threshold even if bool is false)
if (dp.boolBlackBeadDetect && dp.threshBlackBeadDetect<0) || ...
        ~dp.boolBlackBeadDetect
    dp.threshBlackBeadDetect=max(ComputeAutomaticBlackThreshold(...
        imread(imageFullFiles{1})),threshBlackBeadDetectMin);
end
%bool transparent bead detect
if dp.boolTransBeadDetect && ...
        ~exist(fullfile(dp.pathImages,dp.templateTransBeadFile),'file')
    warning(['Execution stopped: Inexistent or uncorrect file of ',...
        'transparent bead template.']);
    flagError=true;
    return;
elseif dp.boolTransBeadDetect && dp.threshTransBeadDetect<0
    dp.threshTransBeadDetect=threshTransBeadDetect;
elseif ~dp.boolTransBeadDetect
    dp.boolTransBeadDetectConf=false;
    dp.templateTransBeadFile=[];
    dp.threshTransBeadDetect=[];
    dp.transBeadDetectHMax=[];
    dp.transBeadDetectRadFilt=[];
    dp.transBeadDetectNbFilt=[];
end
%bool transparent bead detector confidence
if dp.boolTransBeadDetectConf && dp.threshTransBeadDetectConf<0
    dp.threshTransBeadDetectConf=threshTransBeadDetectConf;
elseif ~dp.boolTransBeadDetectConf
    dp.threshTransBeadDetectConf=[];
end
%bool water line detect
if dp.boolWaterLineDetect && dp.threshWaterLineStd<0
    dp.threshWaterLineStd=threshWaterLineStd;
elseif ~dp.boolWaterLineDetect && ~dp.boolLinesDetect
    dp.threshWaterLineStd=[];
end

%ROI definition if not provided
if isempty(dp.ptvROI) || isempty(dp.bwlROI)
    imSize = size(imread(imageFullFiles{1}));
    if isempty(dp.ptvROI)
        dp.ptvROI=[[0,0] fliplr(imSize)];
    end
    if isempty(dp.bwlROI)
        dp.bwlROI=[[0,0] fliplr(imSize)];
    end
end

%additionnal parameters needed for the detection
%image size, nb images and bead radiuses in pixel
dp.nbImages=length(imageFullFiles);
if dp.boolBlackBeadDetect || dp.boolTransBeadDetect
    [sp,flagError]=LoadSequenceParameters(dp.seqParamFile);
    if flagError, return; end
    dp.mByPx=sp.mByPx;
    dp.fps=sp.fps;
    dp.radBlackBeadPx=round(round(sp.diamBlackBead/sp.mByPx)/2);
    dp.radTransBeadPx=round(round(sp.diamTransBead/sp.mByPx)/2);
    dp.radTransBeadPxInside=round(round(sp.diamTransBead/sp.mByPx)*...
        sp.rateDiamTransBeadInside/2);
end
end

function threshBlack = ComputeAutomaticBlackThreshold(image)
% Set automatically the threshold of black pixels according to gray intensity
% distribution. It is chosen as the first local peak of the distribution.
%
% INPUT ARGUMENTS:
%  image: grayscale image.
%
% OUTPUT ARGUMENTS:
%  threshBlack: threshold separating black pixels from the rest.

[nelements,centers]=hist(single(image(:)),50);
localPeakIdx=imregionalmax(nelements);
localPeakThresh=centers(localPeakIdx);
threshBlack=localPeakThresh(1);

end