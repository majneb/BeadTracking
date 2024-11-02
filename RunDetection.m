function RunDetection(dspIn, saveMat, saveH5, exitMatlab)
% Run detection of black/transparent beads, bedline, and waterline on a
% sequence of images. Results are stored in .mat/.h5 file. Detected
% positions are returned referenced to "image world" (z from top to bottom)
% 
% INPUT ARGS :
%   dspIn : file of settable parameters
%   saveMat : save results to .mat (automatically true if exitMatalb is 1 or 2)
%   saveH5 : save results to .h5
%   exitMatlab : useful if called from outside Matlab (default 0)
%       0 : do not close and copy data to matlab workspace
%       1 : close Matlab after taping keyboard
%       2 : close Matlab automatically when script finish  
% 
% MODES (set from dspIN) : 
%   - Beads detection (set boolBlackBeadDetect or/and boolTransBeadDetect)
%   with or without help of waterline (set boolWaterLineDetect),
%   - Lines Detection (set boolLinesDetect) : include bedlines AND
%   waterlines, no matter what boolWaterLineDetect is,
%   - Both beads and lines Detection
%
% Note that running just lines detection with no beads detection is less 
% precise as there will be no correction of the waterline in case of 
% floating black beads. 

% Set Default param 
if nargin < 4; exitMatlab = 0; end
if nargin < 3; saveH5 = true; end
if nargin < 2; saveMat = true; end
if exitMatlab == 1 || exitMatlab == 2; saveMat = true; end

% Load detection parameters from textfile
[dp,flagError]=LoadDetectionSettableParameters(dspIn);
if flagError, return; end
if (~dp.boolBlackBeadDetect && ~dp.boolTransBeadDetect && ~dp.boolLinesDetect)
    fprintf(['No beads detection nor lines detection asked, please check param' ...
        'file'])
    return;
end

% Get image name list
imageNameList=struct2cell(dir(fullfile(dp.pathImages,'*.tif')));
imageNameList=SortImageFullFiles(imageNameList(1,:));
imageNameList=fullfile(dp.pathImages,imageNameList);
if isempty(imageNameList)
    warning(['Execution stopped: Inexistent or uncorrect folder of images, ',...
        'or no images in the folder.']);
    return;
end

% Set other detection parameters from dp and sequence_param file
[dp,flagError]=SetDetectionParameters(dp,imageNameList);
if flagError, return; end

% Compute detection
if dp.boolBlackBeadDetect || dp.boolTransBeadDetect
    fprintf('Detecting beads...\n');
    [detectData,waterData,detectConfData]=ComputeDetection(imageNameList,dp);
else
    waterData={};  %initialisation for lines detection
end
if dp.boolLinesDetect
    fprintf('Detecting bedlines and waterlines...\n');
    [waterLines, bedLines] = ComputeLinesDetection(imageNameList, dp, waterData);
end

% Save data to .mat
if saveMat
    fprintf('Saving results to .mat...\n');
    if ~exist(dp.pathResults, 'dir'); mkdir(dp.pathResults); end
    if dp.boolBlackBeadDetect || dp.boolTransBeadDetect
        if exist(fullfile(dp.pathResults, ...
                [dp.detectBeadsFileName,'.mat']),'file')==2
            warning(['A mat file of beads detection results already ',...
                    'exists with the same name, it will be overwritten.']);
        end
        save(fullfile(dp.pathResults,[dp.detectBeadsFileName,'.mat']), ...
            'imageNameList','dp','detectData','waterData','detectConfData')
    end
    if dp.boolLinesDetect
        if exist(fullfile(dp.pathResults, ...
                [dp.detectBWLFileName,'.mat']),'file')==2
        warning(['A mat file of bedlines/waterlines detection results already ',...
                'exists with the same name, it will be overwritten.']);
        end
        save(fullfile(dp.pathResults,[dp.detectBWLFileName,'.mat']),'dp', ...
            'bedLines','waterLines')
    end
end

% Save data to hdf5
if saveH5
    fprintf('Saving results to hdf5...\n');
    %set anoying warning message to off (just tell that data type
    %conversion could clamp some data, so it must be used carefully)
    warning('off','MATLAB:imagesci:hdf5dataset:datatypeOutOfRange')  
    if dp.boolBlackBeadDetect || dp.boolTransBeadDetect
        h5FilePath = fullfile(dp.pathResults,[dp.detectBeadsFileName,'.h5']);
        if exist(h5FilePath,'file')==2
            warning(['An hdf5 file of beads detection results already ',...
                    'exists with the same name, it will be overwritten.']);
            delete(h5FilePath);
        end
        fprintf('Saving beads data...\n')
        t=now;
        ParforProgress(t,dp.nbImages);
        for i = 1:dp.nbImages
            if size(detectData{1,i},1) > 0
                h5create(h5FilePath,['/beads/',num2str(i)],size(detectData{1,i}),'Datatype','single');
                h5write(h5FilePath,['/beads/',num2str(i)],detectData{1,i});
            end
            ParforProgress(t,0,i); 
        end
        ParforProgress(t,0);  
        h5create(h5FilePath,'/roi',4,'Datatype','uint32');
        h5write(h5FilePath,'/roi',dp.ptvROI);
        h5create(h5FilePath,'/ntot',1,'Datatype','uint32');
        h5write(h5FilePath,'/ntot',dp.nbImages);
        h5create(h5FilePath,'/thresh_blackbeads',1,'Datatype','uint8');
        h5write(h5FilePath,'/thresh_blackbeads',dp.threshBlackBeadDetect);
%         h5create(h5FileName,'/thresh_transbeads',1,'Datatype','uint8');
%         h5write(h5FileName,'/thresh_transbeads',dp.threshTransBeadDetect);
    end
    if dp.boolLinesDetect
        h5FilePath = fullfile(dp.pathResults,[dp.detectBWLFileName,'.h5']);
        if exist(h5FilePath,'file')==2
            warning(['An hdf5 file of bedlines/waterlines detection results' ...
                ' already exists with the same name, it will be overwritten.']);
            delete(h5FilePath);
        end
        fprintf('Saving bedline/waterline data...\n')
        t=now;
        ParforProgress(t,dp.nbImages);
        for i=1:dp.bwlNtot
            h5create(h5FilePath,['/waterlines/',num2str(i)],dp.bwlROI(3),'Datatype','uint16');
            h5write(h5FilePath,['/waterlines/',num2str(i)],waterLines{i});
            h5create(h5FilePath,['/bedlines/',num2str(i)],dp.bwlROI(3),'Datatype','uint16');
            h5write(h5FilePath,['/bedlines/',num2str(i)],bedLines{i});
            % TODO convert to real world
            ParforProgress(t,0,i);
        end
        ParforProgress(t,0);  
        h5create(h5FilePath,'/roi',4,'Datatype','uint32');
        h5write(h5FilePath,'/roi',dp.bwlROI);
        h5create(h5FilePath,'/ntot',1,'Datatype','uint32');
        h5write(h5FilePath,'/ntot',dp.bwlNtot);
        h5create(h5FilePath,'/start',1,'Datatype','uint32');
        h5write(h5FilePath,'/start',dp.bwlStart);
        h5create(h5FilePath,'/step',1,'Datatype','uint16');
        h5write(h5FilePath,'/step',dp.bwlStep);
        h5create(h5FilePath,'/thresh_bedline',1,'Datatype','uint8');
        h5write(h5FilePath,'/thresh_bedline',dp.threshBedLine);
        h5create(h5FilePath,'/thresh_waterline',1,'Datatype','double');
        h5write(h5FilePath,'/thresh_waterline',dp.threshWaterLineStd);
        h5create(h5FilePath,'/nb_image_for_average',1,'Datatype','uint8');
        h5write(h5FilePath,'/nb_image_for_average',dp.nbImForAverage);
    end
end

% Export to Matlab workspace or just exit Matlab
if exitMatlab == 0
    assignin('base','imageNameList',imageNameList);
    assignin('base','detectParam',dp);
    if dp.boolBlackBeadDetect || dp.boolTransBeadDetect
        assignin('base','detectData',detectData);
        assignin('base','waterData',waterData);
        assignin('base','detectConfData',detectConfData);
    end
    if dp.boolLinesDetect
        assignin('base','waterLines',waterLines);
        assignin('base','bedLines',bedLines);
    end
elseif exitMatlab == 1
    disp('Press a key to exit Matlab')
    pause;
    exit;
elseif exitMatlab == 2
    pause(2); % wait 2 seconds before closing
    exit;
end

end
