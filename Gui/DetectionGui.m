function [outStruct,run] = DetectionGui(defValStruct)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%---             --- Main function of the detection GUI, that       ---
%--- Description --- creates the GUI window with all its elements.  ---
%---             --- The input of this function is a structure,     ---
%---             --- whode fields must match the values of the      ---
%---             --- variables in the s.path.fieldNames structure   ---
%----------------------------------------------------------------------
%---   Version   --- 2019-03-01:                                    ---
%---   History   ---   First version                                ---
%---             --- 2019-03-20:                                    ---
%---             ---   Modifying assignments to CloseRequestFcn,    ---
%---             ---   s.submit.cancel and s.submit.run callbacks.  ---
%---             ---   Adding s.bool.fieldNames.BOOL_TRANS_CONF and ---
%---             ---   s.real.fieldNames.REAL_TRANS_CONF_TH to be   ---
%---             ---   able to activate/set the compute detector    ---
%---             ---   confidence of transparent beads.             ---
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.



%-------------------------------------------------------------------------------
% Initialize structures
%-------------------------------------------------------------------------------

% defining constant variables in upper-case
s.path.fieldNames.PATH_SEQUENCE_DIR     = 'pathImages';
s.path.fieldNames.PATH_RESULTS_DIR      = 'pathResults';
s.path.fieldNames.PATH_SEQUENCE_FILE    = 'seqParamFile';
s.path.fieldNames.PATH_MASK_FILE        = 'baseMaskFile';
s.path.fieldNames.PATH_TRANS_FILE       = 'templateTransBeadFile';
s.path.fieldNames.PATH_DATA_PREFIX      = 'detectDataFilePrefix';
s.path.fieldNames.PATH_DATA_SUFFIX      = 'detectSettableParamFileSuffix';
s.bool.fieldNames.BOOL_REMOVE_BASE      = 'boolRemoveBase';
s.bool.fieldNames.BOOL_BLACK            = 'boolBlackBeadDetect';
s.bool.fieldNames.BOOL_TRANS            = 'boolTransBeadDetect';
s.bool.fieldNames.BOOL_TRANS_CONF       = 'boolTransBeadDetectConf';
s.bool.fieldNames.BOOL_WATER_LINE       = 'boolWaterLineDetect';
s.bool.fieldNames.BOOL_COMPUTE_PARALLEL = 'boolComputeParallel';
s.bool.fieldNames.BOOL_VISUALIZATION    = 'boolVisualizeDetections';
s.real.fieldNames.REAL_BLACK_TH         = 'threshBlackBeadDetect';
s.real.fieldNames.REAL_TRANS_TH         = 'threshTransBeadDetect';
s.real.fieldNames.REAL_TRANS_CONF_TH    = 'threshTransBeadDetectConf';
s.real.fieldNames.REAL_WATER_LINE_TH    = 'threshWaterLineStd';
s.real.fieldNames.REAL_TRANS_HMAX       = 'transBeadDetectHMax';
s.real.fieldNames.REAL_TRANS_RAD_FILT   = 'transBeadDetectRadFilt';
s.real.fieldNames.REAL_TRANS_NB_FILT    = 'transBeadDetectNbFilt';



% the path structure
s.path.defaultStructFields={...
    s.path.fieldNames.PATH_SEQUENCE_DIR,'';...
    s.path.fieldNames.PATH_RESULTS_DIR,'';...
    s.path.fieldNames.PATH_SEQUENCE_FILE,'';...
    s.path.fieldNames.PATH_MASK_FILE,'';...
    s.path.fieldNames.PATH_TRANS_FILE,'';...
    s.path.fieldNames.PATH_DATA_PREFIX,'detect_data';...
    s.path.fieldNames.PATH_DATA_SUFFIX,'settable_param'};

% the field s.path.defaultStructFields(i,1) will be displayed at the
% s.path.map(s.path.defaultStructFields(i,1)) vertically position in the 
% path group
%s.path.map=containers.Map(s.path.defaultStructFields(:,1),[3,7,2,6,5,1,4]);
s.path.map=containers.Map(s.path.defaultStructFields(:,1),...
    1:size(s.path.defaultStructFields,1));
s.path.mapKeys=SortMapByValue(s.path.map);
s.path=rmfield(s.path,'map');

% default Title for sub-buttongroup (the ith element in s.path.groupDefString
% corresponds to the ith element in s.path.defaultStructFields) but won't
% be necessarily displayed at the ith vertically position of the path group
% but at the s.path.map(s.path.defaultStructFields(i,1)) position
s.path.groupDefString={...
    'Sequence directory',...
    'Results directory',...
    'Parameter file',...
    'Base mask file',...
    'Transparent bead template file',...
    'Prefix name of the output file of detection results',...
    'Suffix name of the output file of detection settable parameters'};

% s.path.filterCells corresponds to the uigetfile filter for file
% or to an empty value for a directory
s.path.filterCells={...
    [],...
    [],...
    {'*.txt','Text files (*.txt)';'*.*','All files (*.*)'},...
    {'*.tif','Raster image files (*.tif)';'*.*','All files (*.*)'},...
    {'*.mat','MAT-files (*.mat)';'*.*','All files (*.*)'},...
    [],...
    []};

% indices of paths to browse (based on s.path.groupDefString and
% s.path.defaultStructFields) for file or directory
s.path.browseIdx=1:5;

% indices of paths to edit/type (based on s.path.groupDefString and
% s.path.defaultStructFields)
s.path.editIdx=6:7;



% the bool structure
s.bool.defaultStructFields={...
    s.bool.fieldNames.BOOL_REMOVE_BASE,1;...
    s.bool.fieldNames.BOOL_BLACK,1;...
    s.bool.fieldNames.BOOL_TRANS,1;...
    s.bool.fieldNames.BOOL_TRANS_CONF,1;...
    s.bool.fieldNames.BOOL_WATER_LINE,1;...
    s.bool.fieldNames.BOOL_COMPUTE_PARALLEL,0;...
    s.bool.fieldNames.BOOL_VISUALIZATION,1};

% the field s.bool.defaultStructFields(i,1) will be displayed at the
% s.bool.map(s.bool.defaultStructFields(i,1)) vertically position in the 
% bool group
%s.bool.map=containers.Map(s.bool.defaultStructFields(:,1),[3,5,4,1,7,2,6]);
s.bool.map=containers.Map(s.bool.defaultStructFields(:,1),...
    1:size(s.bool.defaultStructFields,1));
s.bool.mapKeys=SortMapByValue(s.bool.map);
s.bool=rmfield(s.bool,'map');

% default String for checkboxes (the ith element in s.bool.checkDefString
% corresponds to the ith element in s.bool.defaultStructFields) but won't
% be necessarily displayed at the ith vertically position of the bool group
% but at the s.bool.map(s.bool.defaultStructFields(i,1)) position
s.bool.checkDefString={...
    'Remove the base of the flume',...
    'Detect black beads',...
    'Detect transparent beads',...
    'Compute detector confidence of transparent beads',...
    'Detect water lines',...
    'Use parallel computing',...
    'Create visualization of detections'};



% the real structure
s.real.defaultStructFields={
    s.real.fieldNames.REAL_BLACK_TH,25;...
    s.real.fieldNames.REAL_TRANS_TH,0.25;...
    s.real.fieldNames.REAL_TRANS_CONF_TH,0.20;...
    s.real.fieldNames.REAL_WATER_LINE_TH,0.25;...
    s.real.fieldNames.REAL_TRANS_HMAX,44;...
    s.real.fieldNames.REAL_TRANS_RAD_FILT,1;...
    s.real.fieldNames.REAL_TRANS_NB_FILT,2};

% the field s.real.defaultStructFields(i,1) will be displayed at the
% s.real.map(s.real.defaultStructFields(i,1)) vertically position in the 
% real group
%s.real.map=containers.Map(s.real.defaultStructFields(:,1),[1,4,3,2,5,6,7]);
s.real.map=containers.Map(s.real.defaultStructFields(:,1),...
    1:size(s.real.defaultStructFields,1));
s.real.mapKeys=SortMapByValue(s.real.map);
s.real=rmfield(s.real,'map');



if numel(fieldnames(s.path.fieldNames))...
        ~=(numel(s.path.browseIdx)+numel(s.path.editIdx))...
    || numel(fieldnames(s.path.fieldNames))~=size(s.path.defaultStructFields,1)...
    || numel(fieldnames(s.path.fieldNames))~=numel(s.path.groupDefString)...
    || numel(fieldnames(s.path.fieldNames))~=numel(s.path.filterCells)
        error(['One of these variable has not the correct dimensions ',...
            'or number of fields:\n',...
                '\ts.path.fieldNames\n',...
                '\ts.path.browseIdx\n',...
                '\ts.path.editIdx\n',...
                '\ts.path.defaultStructFields\n',...
                '\ts.path.groupDefString\n',...
                '\ts.path.filterCells\n']);
end
if numel(fieldnames(s.bool.fieldNames))~=size(s.bool.defaultStructFields,1)...
    || numel(fieldnames(s.bool.fieldNames))~=numel(s.bool.checkDefString)
        error(['One of these variable has not the correct dimensions ',...
            'or number of fields:\n',...
                '\ts.bool.fieldNames\n',...
                '\ts.bool.defaultStructFields\n',...
                '\ts.bool.checkDefString\n']);
end

fieldType={'path','bool','real'};
for n=1:length(fieldType)
    for m=1:size(s.(fieldType{n}).defaultStructFields,1)
        if ~isfield(defValStruct,s.(fieldType{n}).defaultStructFields{m,1})
            defValStruct.(s.(fieldType{n}).defaultStructFields{m,1})...
                =s.(fieldType{n}).defaultStructFields{m,2};
        end
    end
end

% font size for uibuttongroup Title
defTitleTextSize=12;
% font size for uicontrol String
defTextSize=10;
% background color of the figure
s.color=[0.6,0.6,0.6];

hf=figure('Units','normalized','Position',[0.2,0.1,0.6,0.8],'Color',s.color,...
    'MenuBar','none','ToolBar','none','Numbertitle','off',...
    'Name','Parameter selection');



%-------------------------------------------------------------------------------
% s.path
%-------------------------------------------------------------------------------
s.path.count=length(s.path.mapKeys); %nb paths to browse
s.path.color=[1,1,0.6];
s.path.hSubGr=nan(1,s.path.count);
s.path.hText=nan(1,s.path.count);
s.path.hPush=nan(1,s.path.count);
s.path.hEdit=nan(1,s.path.count);

% default String for text controls
s.path.textDefString=cell(1,s.path.count);
for m=1:s.path.count
    s.path.textDefString{It2DefStructFieldIdx(s.path,m)}...
        =defValStruct.(s.path.mapKeys{m});
end

s.path.hMainGr=uibuttongroup(...
    'Visible','on','Parent',hf,'Title','Directory/file parameters',...
    'FontSize',defTitleTextSize,'Position',[0.025,0.575,0.95,0.4],...
    'BackGroundColor',s.path.color);
s.path.h1=0.025; % horizontal empty space
s.path.v1=0.025; % vertical empty space
s.path.h=1-2*s.path.h1;
s.path.v=(1-(s.path.count+1)*s.path.v1)/s.path.count;

for n=1:s.path.count
    defaultStructFieldsIdx=It2DefStructFieldIdx(s.path,n);
    s.path.hSubGr(n)=uibuttongroup('Visible','on',...
        'Title',s.path.groupDefString{defaultStructFieldsIdx},...
        'Parent',s.path.hMainGr,'Position',[s.path.h1,...
        (s.path.count-n+1)*s.path.v1+(s.path.count-n)*s.path.v,...
        s.path.h,s.path.v],'FontSize',defTextSize,...
        'BackGroundColor',get(s.path.hMainGr,'BackGroundColor'));
    if max(It2DefStructFieldIdx(s.path,n)==s.path.browseIdx)
        s.path.hText(n)=uicontrol('Style','text',...
            'String',s.path.textDefString{defaultStructFieldsIdx},...
            'Units','normalized','Position',[0.0125,0.1,0.875,0.9],...
            'HorizontalAlignment','Left','FontSize',defTextSize,...
            'FontSize',defTextSize,'Parent',s.path.hSubGr(n),...
            'HandleVisibility','off',...
            'BackgroundColor',get(s.path.hMainGr,'BackGroundColor'));
        s.path.hPush(n)=uicontrol('Style','push','String','Browse ...',...
            'Units','normalized','Position',[0.88,0.1,0.1,0.9],...
            'FontSize',defTextSize,'Parent',s.path.hSubGr(n),...
            'HandleVisibility','off');
        if isempty(s.path.filterCells{defaultStructFieldsIdx}) 
            set(s.path.hPush(n),'Callback',{@SetPath,hf,{}});
        else
            set(s.path.hPush(n),'Callback',{@SetPath,hf,...
                {s.path.fieldNames.PATH_SEQUENCE_FILE,...
                 s.path.fieldNames.PATH_MASK_FILE,...
                 s.path.fieldNames.PATH_TRANS_FILE}});
        end
    elseif max(It2DefStructFieldIdx(s.path,n)==s.path.editIdx)
        s.path.hEdit(n)=uicontrol('Style','edit',...
            'String',s.path.textDefString{defaultStructFieldsIdx},...
            'Units','normalized','Position',[0.0125,0.1,0.4,0.9],...
            'HorizontalAlignment','Left','FontSize',defTextSize,...
            'Parent',s.path.hSubGr(n),'HandleVisibility','off',...
            'BackgroundColor',[1,1,1]);
    end
end



%-------------------------------------------------------------------------------
% s.bool
%-------------------------------------------------------------------------------
s.bool.count=length(s.bool.mapKeys); %nb booleans to check/uncheck
s.bool.color=[0.6,1,1];
s.bool.hCheck=nan(1,s.bool.count);

% default String for text controls
s.bool.checkDefValue=nan(1,s.bool.count);
for m=1:s.bool.count
    s.bool.checkDefValue(It2DefStructFieldIdx(s.bool,m))...
        =defValStruct.(s.bool.mapKeys{m});
end

s.bool.hMainGr=uibuttongroup('Visible','on','Parent',hf,...
    'Title','Options parameters','FontSize',defTitleTextSize,...
    'Position',[0.025,0.15,0.4625,0.4],'BackGroundColor',s.bool.color);
s.bool.h1=0.025; % horizontal empty space
s.bool.v1=0.025; % vertical empty space
s.bool.h=1-2*s.bool.h1;
s.bool.v=(1-(s.bool.count+1)*s.bool.v1)/s.bool.count;

for n=1:s.bool.count
    defaultStructFieldsIdx=It2DefStructFieldIdx(s.bool,n);
    s.bool.hCheck(n)=uicontrol('Style','check','Units','normalized',...
        'String',s.bool.checkDefString{defaultStructFieldsIdx},...
        'Parent',s.bool.hMainGr,...
        'Value',s.bool.checkDefValue(defaultStructFieldsIdx),...
        'FontSize',defTextSize,'Position',[s.bool.h1,...
        (s.bool.count-n+1)*s.bool.v1+(s.bool.count-n)*s.bool.v,...
        s.bool.h,s.bool.v],...
        'BackGroundColor',get(s.bool.hMainGr,'BackGroundColor'));
end
set(s.bool.hCheck,'Callback',{@UpdateEnableStatesDetection,hf});



%-------------------------------------------------------------------------------
% s.real
%-------------------------------------------------------------------------------
s.real.count=length(s.real.mapKeys); %nb real values to set
s.real.color=[1,0.8,0.8];
s.real.hSubGr=nan(1,s.real.count);
s.real.hText=nan(1,s.real.count);
s.real.hEdit=nan(1,s.real.count);

% default String for text controls
l=zeros(1,s.real.count);
for k=1:length(l)
    l(k)=length(s.real.mapKeys{k});
end
s.real.textDefString=cellfun(@(x)[x,repmat(' ',1,max(l)-length(x))],...
    s.real.mapKeys,'uni',0);

% default String for edit controls
s.real.editDefString=cell(1,s.real.count);
for m=1:length(s.real.mapKeys)
    s.real.editDefString{m}=defValStruct.(s.real.mapKeys{m});
end

s.real.hMainGr=uibuttongroup('Visible','on','Parent',hf,...
    'Title','Value parameters','FontSize',defTitleTextSize,...
    'Position',[0.5125,0.15,0.4625,0.4],'BackGroundColor',s.real.color);
s.real.h1=0.025; % horizontal empty space
s.real.v1=0.025; % vertical empty space
s.real.h=1-2*s.real.h1;
s.real.v=(1-(s.real.count+1)*s.real.v1)/s.real.count;

for n=1:s.real.count
    s.real.hSubGr(n)=uibuttongroup('Visible','on','Title','',...
        'Parent',s.real.hMainGr,'Position',[s.real.h1,...
        (s.real.count-n+1)*s.real.v1+(s.real.count-n)*s.real.v,...
        s.real.h,s.real.v],...
        'BackGroundColor',get(s.real.hMainGr,'BackGroundColor'),...
        'FontSize',defTextSize,'BorderType','none');
    s.real.hText(n)=uicontrol('Style','text','String',s.real.textDefString{n},...
        'Units','normalized','Position',[0.05,0.1,0.5,0.5],...
        'HorizontalAlignment','Left','FontSize',defTextSize,...
        'FontName','courier','FontSize',defTextSize,...
        'Parent',s.real.hSubGr(n),'HandleVisibility','off',...
        'BackgroundColor',get(s.real.hSubGr(n),'BackgroundColor'));
    s.real.hEdit(n)=uicontrol('Style','edit','String',s.real.editDefString{n},...
        'Units','normalized','Position',[0.57,0.0,0.2,0.8],...
        'HorizontalAlignment','Left','FontSize',defTextSize,...
        'FontName','courier','FontSize',defTextSize,'Parent',s.real.hSubGr(n),...
        'HandleVisibility','off','BackgroundColor',[1,1,1]);
end



%-------------------------------------------------------------------------------
% submit buttons
%-------------------------------------------------------------------------------
submitFontsize=30;
s.submit.cancel=uicontrol('Style','push','String','CANCEL',...
    'Units','normalized','Position',[0.5125,0.025,0.2188,0.1],...
    'Parent',hf,'HandleVisibility','off','FontSize',submitFontsize,...
    'BackGroundColor',[1,0.4,0.4]);
s.submit.run=uicontrol('Style','push','String','RUN','Units','normalized',...
    'Position',[0.7562,0.025,0.2188,0.1],'Parent',hf,'HandleVisibility','off',...
    'FontSize',submitFontsize,'BackGroundColor',[0.4,1,0.4]);
s.submit.info=uicontrol('Style','text','String','',...
    'HorizontalAlignment','Left','Units','normalized',...
    'Position',[0.025,0.025,0.4625,0.1],'Parent',hf,'HandleVisibility','off',...
    'FontSize',defTitleTextSize,'BackGroundColor',s.color,...
    'ForegroundColor',[0.8,0.0,0.0]);

set(s.submit.cancel,'Callback',{@SubmitDetection,hf});
set(s.submit.run,'Callback',{@SubmitDetection,hf});

guidata(hf,s);

for m=1:length(s.bool.hCheck)
    UpdateEnableStatesDetection(s.bool.hCheck(m),[],hf);
end

set(hf,'CloseRequestFcn',{@SubmitDetection,hf});
waitfor(hf);

end