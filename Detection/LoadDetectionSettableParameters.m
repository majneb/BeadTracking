function [dsp,flagError] = LoadDetectionSettableParameters(dspFullFile)
% Load the settable parameters of a previous detection from its file.
%
% INPUT ARGUMENTS:
%  dspFullFile: full file containing the detection settable parameters.
%
% OUTPUT ARGUMENTS:
%  dsp      : structure containing the detection settable parameters.
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

% EDIT 04/22 B.Dedieu
% Add parameters for bed/water lines detection
% Remove prefix and suffix file name parameter and add DetectBeadsFileName
% and DetectBWLFileName parameters
% Add roi management (bwlROI and ptvROI needed in settable_param file but
% can be set to None or false or 0... if not needed)
% This version is made to work with 2022 modified RunDetection version.

dsp=[];
flagError=false;
try
    fid=fopen(dspFullFile);
    C=textscan(fid,'%s = %s');
    fclose(fid);
    for p=1:length(C{1})
        dsp.(C{1}{p})=C{2}(p);
    end
catch
    warning(['Execution stopped: Inexistent or uncorrect file of detection ',...
        'settable parameters.']);
    flagError=true;
    return;
end
dsp.pathImages=char(dsp.pathImages);
dsp.pathResults=char(dsp.pathResults);
dsp.seqParamFile=char(dsp.seqParamFile);
dsp.baseMaskFile=char(dsp.baseMaskFile);
dsp.templateTransBeadFile=char(dsp.templateTransBeadFile);
dsp.detectBeadsFileName=char(dsp.detectBeadsFileName);
%dsp.detectDataFilePrefix=char(dsp.detectDataFilePrefix);
%dsp.detectSettableParamFileSuffix=char(dsp.detectSettableParamFileSuffix);
dsp.boolRemoveBase=strcmp(dsp.boolRemoveBase,'True');
dsp.boolBlackBeadDetect=strcmp(dsp.boolBlackBeadDetect,'True');
dsp.boolTransBeadDetect=strcmp(dsp.boolTransBeadDetect,'True');
dsp.boolTransBeadDetectConf=strcmp(dsp.boolTransBeadDetectConf,'True');
dsp.boolWaterLineDetect=strcmp(dsp.boolWaterLineDetect,'True');
dsp.boolComputeParallel=strcmp(dsp.boolComputeParallel,'True');
dsp.boolVisualizeDetections=strcmp(dsp.boolVisualizeDetections,'True');
dsp.threshBlackBeadDetect=str2double(dsp.threshBlackBeadDetect);
dsp.threshTransBeadDetect=str2double(dsp.threshTransBeadDetect);
dsp.threshTransBeadDetectConf=str2double(dsp.threshTransBeadDetectConf);
dsp.threshWaterLineStd=str2double(dsp.threshWaterLineStd);
dsp.transBeadDetectHMax=str2double(dsp.transBeadDetectHMax);
dsp.transBeadDetectRadFilt=str2double(dsp.transBeadDetectRadFilt);
dsp.transBeadDetectNbFilt=str2double(dsp.transBeadDetectNbFilt);

dsp.boolLinesDetect=strcmp(dsp.boolLinesDetect,'True');
dsp.detectBWLFileName=char(dsp.detectBWLFileName);
dsp.bwlStart=str2double(dsp.bwlStart);
dsp.bwlNtot=str2double(dsp.bwlNtot);
dsp.bwlStep=str2double(dsp.bwlStep);
dsp.threshBedLine=str2double(dsp.threshBedLine);
dsp.nbImForAverage=str2double(dsp.nbImForAverage);
dsp.ptvROI=cell2mat(textscan(char(dsp.ptvROI),'(%f,%f,%f,%f)'));
dsp.bwlROI=cell2mat(textscan(char(dsp.bwlROI),'(%f,%f,%f,%f)'));

end