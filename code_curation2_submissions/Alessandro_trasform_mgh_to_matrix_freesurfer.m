%% Script taken from the main transform_mgh_to_matrix and modified for fsaverage
% This script allows the obtaining of a vector for brain measures (thickness,surface etc) based on fsaverage.
% The number of points of the vector depends on fsaverage. 
% i.e: fsaverage5 gives a vector of 10242 points for each hemisphere; fsaverage6 gives 40962
% ATTENTION: before running any script it is necessary to add the freesurfer matlabpath: 
% addpath /opt/freesurfer/freesurfer_v5.3/matlab

% Created by: Rachele Sanfelici
% Modified by: Alessandro Pigoni
% Date: february 2019

%% Get the LH mgh values for each participant 
subdir='/home/apigoni/Analisi/SUBJECTS';% setting the subjects dir folder to a local folder
aux_name=dir(fullfile(subdir,'CF_*'));% give the name of the subjects (i.e. CF_001 etc)
sv = cell(numel(aux_name),1); %pre-define cell for sv values

for i=1:numel(aux_name)    
    id{i}=aux_name(i).name;%file name
    subfile = sprintf('%s/%s/surf/lh.thickness_fsa5.mgh',subdir,id{i}); %the lh subdirectory where smoothed mgh files are store
    try
        [vol(:,i),sv{i}] = load_mgh(subfile); %the load function reads the mgh file and outputs a matrix with values (vol)
    catch 
        fprintf('Subject %s did not work\n\n',id{i}); %the catch command prevents the loop to stop printing out those subj who didn´t work, then keeps the loop going
    end
end

mgh_fsav6.vertices = vol; %create a structure
mgh_fsav6.vox2ras = sv;
mgh_fsav6.subjects = id;

clear i

save /home/apigoni/Analisi/SUBJECTS/name %save it in your own directory

%%Get the RH mgh values for each participant
subdir='/volume/CLASSIFEP/Data/SUBJECTS';% setting the subjects dir folder to a local folder

aux_name=dir(fullfile(subdir,'CF_*')); %give the name of the subjects (i.e. CF_001 etc)
svr = cell(numel(aux_name),1);

for i=1:numel(aux_name)
    id{i}=aux_name(i).name;%file name
    subfile = sprintf('%s/%s/surf/rh.thickness_fsa5.mgh',subdir,id{i});
    try
        [volr(:,i),svr{i}] = load_mgh(subfile);
    catch 
        fprintf('Subject %s did not work\n\n',id{i});
    end
end

mgh_fsav6.vertices_rh = volr; %save the vertices in the mgh structure
mgh_fsav6.vox2ras_rh = svr;

clear i

save /home/apigoni/Analisi/SUBJECTS/name %save it in your own directory
