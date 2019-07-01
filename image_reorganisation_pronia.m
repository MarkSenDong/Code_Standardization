function image_reorganisation_pronia(originalDir,copyDir,boganId)
%% image_reorganisation_pronia(originalDir,copyDir,boganId)
% The function copies all images into one folder and then reorganises them
% into the PRONIA folder structure so that the pipeline tools will work on the wp3 server. 
%
% Inputs:
%   originalDir: string, set the original directory of the images
%   copyDir: string, set the destination directoy of the images
%   boganId: int, set the initial bogan_id for the data set, beware: every image must have a globally unique boganId!
%
% Outputs:
%   None

% author: Mark Sen Dong
% date: 06 Jun 2019
% version: 1.0

%% Constants
% These values should not be changed by users
% Use all capitals to name contants
addpath /opt/PRONIASoftware/Developpment/Main/Utilities
% Create a file for logging any errors occured during the reorganisation process.
FILE_ID = fopen('copy_errors.txt','w');     

%% The main process
files = dir(originalDir);
% Iterate through every image in the originalDir to process them
for k = 3:length(files)
    subjectID = files(k).name;
    
    try
        % Get the name of the image
        subName = strsplit(subjectID,'.');
        subName = subName(1,:);
        subName = char(subName(1));
        disp(subName);

        % Make the child directories
        system(['mkdir ' copyDir subName]);
        system(['mkdir ' copyDir subName '/Data']);
        system(['mkdir ' copyDir subName '/Data/' num2str(boganId)]);
        system(['mkdir ' copyDir subName '/xml_folder']);

        % Write the .xml file
        ss.(subName).T0.MRI_sMRI = num2str(boganId);        
        xmlpath=[copyDir subName '/xml_folder'];
        struct2xml(ss,[xmlpath '/' subName '.xml']);

        % Copy the .nii.gz file and remove it from original location
        system(['cp ' originalDir subjectID ' ' copyDir subName '/Data/' num2str(boganId) '/' subjectID]);
        % Zip the .nii file
        %system(['gzip ' copyDir subName '/Data/' num2str(boganId) '/' subName '.nii']);
    
    catch err
        fprintf(FILE_ID,'%s not copied\n',subjectID);
        rethrow(err); 
    end % end of try and catch
    
    boganId = boganId + 1;
    % Clear the structure for each image
    clear ind ss;
end % end of files iteration loop

fclose(FILE_ID);
end % end of function
