function [Result] = rs_seed_repo_generator(Seeds,BOG_rsMRI,PSN_rsMRI,MainDataFolder,PipelineName)
% function [ADataDir,AMaskFilename, AROIDef,AResultFilename, ACovariablesDef, VorR_tag, MainOutputFolder] = seed_repo_generator(Seeds,BOG_rsMRI,PSN_rsMRI,MainDataFolder,PipelineName)
% Function that creates the necessary input arguments for the function rp_fc which generates FC maps. 
% The maps are then saved in a repository seed folder according to specific ROIs per BOGEN_ID.
% This function is made to work in conjunction  (within the same loops) with the rp_fc function, which is part of the RESTplus_1.2 toolbox.
%
% INPUTS:
% - Seeds             = jx4 numeric array, each seed j is represented by x,y,z MNI coordinates and radius in mm, respectively
% - BOG_rsMRI         = string, the bogen id of the rs MRI
% - PSN_rsMRI         = string, the PSN of the rs MRI
% - MainDataFolder    = string, the path to the data
% - PipelineName      = string, the full name of the folder in which the pipeline is ran

% created by Shalaila Haas and modified by Santiago Tovar @PRONIA
% 18-Mar-2019

if ~isnumeric(Seeds)
    error(['Error in : Seeds are not numeric values'])
end

Result = cell(size(Seeds,1),2);

for j = 1:size(Seeds,1)
    ACovariablesDef = {};
    VorR_tag = 'Voxel';
    
    ADataDir = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR_Smooth6_3D_WaveletDespike_Covremoved_detrend_filtered_3D/'];
    if ~exist(ADataDir)
        error(['Error seed_repo_generator: ',ADataDir,' does not exist'])
    else
        gunziprecursivenii(ADataDir);
    end
    
    Seedx = num2str(Seeds(j,1));
    if Seeds(j,1) < 0
        Seedx = ['m',num2str(abs(Seeds(j,1)))];
    end
    
    Seedy = num2str(Seeds(j,2));
    if Seeds(j,2) < 0
        Seedy = ['m',num2str(abs(Seeds(j,2)))];
    end
    
    Seedz = num2str(Seeds(j,3));
    if Seeds(j,3) < 0
        Seedz = ['m',num2str(abs(Seeds(j,3)))];
    end
    
    Seedr = num2str(Seeds(j,4));
    Seedr = strrep(Seedr,'.','p');
    
    Result{j,1} = ['xyz_',Seedx,'_',Seedy,'_',Seedz,'_r_',Seedr];
    
    MainOutputFolder = ['FCMaps_Repository/xyz_',Seedx,'_',Seedy,'_',Seedz,'_r_',Seedr];
    
    if ~exist([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/', MainOutputFolder, '/'],'dir')
        mkdir([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/', MainOutputFolder, '/'])
    end
    
    if exist([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii'],'file')
        AMaskFilename = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii'];
    elseif exist([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii.gz'],'file')
        gunzip([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii.gz'])
        AMaskFilename = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii'];
    else
        error(['Error seed_repo_generator: ',MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/GMMask.nii does not exist']);
    end
    
    AROIDef = {['ROI Center(mm)=(',num2str(Seeds(j,1)),',',num2str(Seeds(j,2)),',',num2str(Seeds(j,3)), ...
        '); Radius=',num2str(Seeds(j,4)),' mm.']};
    
    AResultFilename = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/', MainOutputFolder, '/FCMap_',BOG_rsMRI,'_',PSN_rsMRI,'_Covremoved_detrend_filtered'];
    
    if exist([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/',MainOutputFolder,'/','zFCMap_',BOG_rsMRI,'_',PSN_rsMRI,'_Covremoved_detrend_filtered.nii.gz'],'file')
        disp([datestr(datetime('now')) ' PSN  ' PSN_rsMRI  ' BOGEN ID ' BOG_rsMRI ' The seed at: ' MainOutputFolder ' has already been generated and was skipped']);
        Result{1,2} = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/',MainOutputFolder,'/','zFCMap_',BOG_rsMRI,'_',PSN_rsMRI,'_Covremoved_detrend_filtered.nii'];
    else
        try
            rp_fc(ADataDir,AMaskFilename, AROIDef,AResultFilename, ACovariablesDef, VorR_tag);
        catch err
            rethrow(err)
        end  
    end
    
    
    % check results
    Result{j,2} = [MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/',MainOutputFolder,'/','zFCMap_',BOG_rsMRI,'_',PSN_rsMRI,'_Covremoved_detrend_filtered.nii'];
    gziprecursivenii([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/',MainOutputFolder,'/']);   
end

gziprecursivenii([MainDataFolder,'/Data/',BOG_rsMRI,'/',PipelineName,'/RESTVAR/']);
gziprecursivenii(ADataDir);


% Report the results
if exist(fullfile(MainDataFolder,'Data',BOG_rsMRI,PipelineName,'report.xml'),'file')
    ss = clean_text_xml2struct(xml2struct(fullfile(MainDataFolder,'Data',BOG_rsMRI,PipelineName,'report.xml')));
else
    ss = struct;
end

if ~isfield(ss,'report')
    ss.report = struct;
end

if ~isfield(ss.report,'PIPELINE_CLASS')
    ss.report.PIPELINE_CLASS = struct;
end

if ~isfield(ss.report.PIPELINE_CLASS,'results')
    ss.report.PIPELINE_CLASS.results = struct;
end

for j = 1:size(Result,1)
    if ~isfield(ss.report.PIPELINE_CLASS.results,Result{j,1})
        ss.report.PIPELINE_CLASS.results.(Result{j,1}) = Result{j,2};
    else
        if isempty(ss.report.PIPELINE_CLASS.results.(Result{j,1}))
            ss.report.PIPELINE_CLASS.results.(Result{j,1}) = Result{j,2};
        else
            disp('results already exported')
        end
    end   
end

if ~isfield(ss.report.PIPELINE_CLASS.results,'timeseries')
    if exist([ADataDir,'/Filtered_4DVolume_00001.nii.gz'])
        ss.report.PIPELINE_CLASS.results.timeseries = [ADataDir,'/Filtered_4DVolume_00001.nii.gz'];
    end
end
struct2xml(ss,fullfile(MainDataFolder,'Data',BOG_rsMRI,PipelineName,'report.xml'));
end



