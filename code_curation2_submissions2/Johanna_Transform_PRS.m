function [PRS_Tables]=Transform_PRS(Data_Folder,PRS_Data,Visit)
%% [PRS_TABLES]=TRANSFORM_PRS(DATA_FOLDER, PRS_DATA)
% transforms genetic PRS data tables (received from Bonn) into the standard
% PRONIA table format
%
% INPUT:
% Data_Folder = string, path to folder where PRS data ist stored and newly
% generated PRS tables will be saved
% PRS_Data = csv file, containig genetic PRS data from Bonn
% Visit = string, containing visit name, can be 'T0' or 'T1'
%
% OUTPUT:
% PRS_Tables = string, path to folder where newly generated PRS tables are saved

% Created by Johanna Weiske
% Febuary 2019

%% ACT 1.1: Input checking

if nargin==3
    % check data format of first input
    if ischar(Data_Folder)
        base_folder=Data_Folder;
    else
        error('InputError:Transform_PRS',['The class of the first input is invalid. A ' class(Data_Folder) ' was provided, a char was expected.']);
    end
    % check data format of second input
    if strcmp(PRS_Data(end-3:end),'.csv')
        PRS=readtable(fullfile(base_folder,PRS_Data));
    else
        error('InputError:Transform_PRS',['The second input is invalid. A ' PRS_Data(end-3:end) ' file was provided, a .csv file was expected.']);
    end
    % check data format of third input
    if ischar(Visit)
        if strcmp(Visit,'T0')||strcmp(Visit,'T1')
            visit=Visit;
        else
            error('InputError:Transform_PRS',['The third input is invalid. "' Visit '" was provided, has to be "T0" or "T1"!']);
        end
    else
        error('InputError:Transform_PRS',['The class of the third input is invalid. A ' class(Visit) ' was provided, a char was expected.']);
    end
else
    error('InputError:Transform_PRS','Not enough input arguments!');
end


%% ACT 1.2: Definitions

addpath /opt/NM/distribute/NeuroMiner_Release/

aux_info_folder='/volume/data/PRONIA/DataDump/06-Sep-2018/table_export/table_export/';

reference_table='/opt/PRONIASoftware/Developpment/DataAllCron/PRONIA_JWCode/TablesAll_06-Sep-2018.mat';
load(reference_table,'TableNonPruned');

out_folder=[base_folder, '/Genetic_PRS'];
mkdir(out_folder)

%% ACT 2: Match PSNs form Reference table and PRS table

% convert PSN from PRS table into cell array of strings if necessary
if iscellstr(PRS.PSN)
    PRS_PSN=PRS.PSN;
elseif isnumeric(PRS.PSN)
    PRS_PSN=cellstr(num2str(PRS.PSN));
end

% Match PSNs form Reference table and PRS table
[aux_PRS,PSN]=nk_MatchID(TableNonPruned.PATIENT_ID,TableNonPruned,PRS_PSN,PRS);

% Warning if PSNs exists in PRS table only but not in Reference table, save
% in out_folder
[PRS_notRef,PSN_notRef]=nk_MatchID(PRS_PSN,PRS,TableNonPruned.PATIENT_ID,TableNonPruned,'src_not_dst');
if ~isempty(PSN_notRef)
    warning('There are PSNs in the Genetic PRS data that are not part fo the reference table! The PSNs and their PRS data will be saved as additional file with the outputs. Please check these PSNs!')
    save(fullfile(out_folder,['PSN_notRef_' visit '.mat']),'PSN_notRef','PRS_notRef')
end

%% ACT 3: Split into HC and PAT group
% this is done because the PRONIA Portal downloads are saved separately for
% HC and PAT

ind_HC=cellfun(@(x) strcmp(x,'HC'),aux_PRS.Studygroup);
aux_PRS=aux_PRS(:,9:end);
aux_PRS.Properties.RowNames={};

% HC
PRS_HC=aux_PRS(ind_HC,:);
PSN_HC=PSN(ind_HC);

% PAT
PRS_PAT=aux_PRS(~ind_HC,:);
PSN_PAT=PSN(~ind_HC);

%% ACT 4: HC - Get auxiliary info for PRONIA table format
% try once with sMRI auxiliary info and for remaining PSNs with IC_EC
% questionnaire auxiliary info (this is due to the way PRONIA Portal
% downloads are saved)

% sMRI aux_info
load(fullfile([aux_info_folder,'/sMRI/auxiliary_information_' visit 'HC_MRI_sMRI.mat']))
[match_info_sMRI,match_PSN_sMRI]=nk_MatchID(aux_info_table.PATIENT_ID,aux_info_table,PSN_HC,PRS_HC);
[PRS_notsMRI,PSN_notsMRI]=nk_MatchID(PSN_HC,PRS_HC,aux_info_table.PATIENT_ID,aux_info_table,'src_not_dst');
% if not all PSNs accounted for, get info from IC_EC aux_info
if ~isempty(PSN_notsMRI)
    load(fullfile([aux_info_folder,'/Observer_Rating_Instruments/auxiliary_information_ScreeningHC_IC_EC.mat']));
    [match_info_ICEC,match_PSN_ICEC]=nk_MatchID(aux_info_table.PATIENT_ID,aux_info_table,PSN_notsMRI,PRS_notsMRI);
    [PRS_notICEC,PSN_notICEC]=nk_MatchID(PSN_notsMRI,PRS_notsMRI,aux_info_table.PATIENT_ID,aux_info_table,'src_not_dst');
end

% create empty table for PSNs that are not in the Reference tables but in
% PRS table
test=cell2table(cell(numel(PSN_notICEC),numel(aux_info_table.Properties.VariableNames)),'VariableNames',aux_info_table.Properties.VariableNames);
test.PATIENT_ID=PSN_notICEC;
test2=[test,PRS_notICEC];

% Merge total table and save
aux_total_table=[match_info_sMRI;match_info_ICEC;test2];
aux_total=table2struct(aux_total_table);
save(fullfile(out_folder,['complete_information_' visit 'HC_genetic_PRS.mat']),'aux_total_table','aux_total')


%% ACT 5: PAT - Get auxiliary info for PRONIA table format

% sMRI aux_info
load(fullfile([aux_info_folder,'/sMRI/auxiliary_information_' visit 'PAT_MRI_sMRI.mat']))
[match_info_sMRI,match_PSN_sMRI]=nk_MatchID(aux_info_table.PATIENT_ID,aux_info_table,PSN_PAT,PRS_PAT);
[PRS_notsMRI,PSN_notsMRI]=nk_MatchID(PSN_PAT,PRS_PAT,aux_info_table.PATIENT_ID,aux_info_table,'src_not_dst');
% if not all PSNs accounted for, get info from IC_EC aux_info
if ~isempty(PSN_notsMRI)
    load(fullfile([aux_info_folder,'/Observer_Rating_Instruments/auxiliary_information_ScreeningPAT_IC_EC.mat']));
    [match_info_ICEC,match_PSN_ICEC]=nk_MatchID(aux_info_table.PATIENT_ID,aux_info_table,PSN_notsMRI,PRS_notsMRI);
    [PRS_notICEC,PSN_notICEC]=nk_MatchID(PSN_notsMRI,PRS_notsMRI,aux_info_table.PATIENT_ID,aux_info_table,'src_not_dst');
end

% create empty table for PSNs that are not in the Reference tables but in
% PRS table
test=cell2table(cell(numel(PSN_notICEC),numel(aux_info_table.Properties.VariableNames)),'VariableNames',aux_info_table.Properties.VariableNames);
test.PATIENT_ID=PSN_notICEC;
test2=[test,PRS_notICEC];

% Merge total table and save
aux_total_table=[match_info_sMRI;match_info_ICEC;test2];
aux_total=table2struct(aux_total_table);
save(fullfile(out_folder,['complete_information_' visit 'PAT_genetic_PRS.mat']),'aux_total_table','aux_total')

%% ACT 6: Output
PRS_Tables=out_folder;
end
