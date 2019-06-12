% This is an examplary matlab script to show the proper documentation and
% coding styles when writting matlab code
%
% The original purpose of the script is the following:
% The function copies all images into one folder and then reorganises them
% into the PRONIA folder structure so that the pipeline tools will work on
% the wp3 server. 

%% User Defined Variables:
% The variables which need to be changed by future users in order to use
% the script.
% They should always be declaired at the beginning og the script, with
% proper explainations.

% Set the original directory of the images
original_dir='/volume/data/MUC/MRI/06-June-2019_nii/';
% Set the destination directoy of the images
copy_dir='/volume/data/MUC/MRI/06-June-2019_pronia/'; 
% Set the initial bogan_id for the data set. 
% Beware: every image must have a globally unique bogan_id!
bogan_id = 2000000;

%% Addpaths 
addpath /opt/PRONIASoftware/Developpment/Main/Utilities

%% Process
% Create a file for logging any errors occured during the reorganisation
% process.
fileID = fopen('copy_errors.txt','w');     

% Get a list of all folders within the original_dir
files = dir(original_dir);

% Iterate through every image in the original_dir
for k = 3:length(files)
    subjectID = files(k).name;

    try
        % Get the name of the image
        subname = strsplit(subjectID,'.');
        subname = subname(1,:);
        subname = char(subname(1));
        disp(subname);

        % Make the child directories
         system(['mkdir ' copy_dir subname]);
         system(['mkdir ' copy_dir subname '/Data']);
         system(['mkdir ' copy_dir subname '/Data/' num2str(bogan_id)]);
         system(['mkdir ' copy_dir subname '/xml_folder']);

        % Write the .xml file
         ss.(subname).T0.MRI_sMRI = num2str(bogan_id);        
         xmlpath=[copy_dir subname '/xml_folder'];
         struct2xml(ss,[xmlpath '/' subname '.xml']);

        % Copy the .nii.gz file and remove it from original location
        system(['cp ' original_dir subjectID ' ' copy_dir subname '/Data/' num2str(bogan_id) '/' subjectID]);
        % Zip the .nii file
        %system(['gzip ' copy_dir subname '/Data/' num2str(bogan_id) '/' subname '.nii']);

    catch err
        fprintf(fileID,'%s not copied\n',subjectID);
        rethrow(err); 
    end
    bogan_id = bogan_id + 1;
    % Clear the structure for each image
    clear ind ss;

end

fclose(fileID);