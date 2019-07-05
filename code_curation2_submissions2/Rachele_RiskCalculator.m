function [RiskScores] = RiskCalculator(ids,pathDataTable,outputFolder)

%% Information about the calulator
% This function creates risk scores based on NAPLS risk-calculator (doi:10.1176/appi.ajp.2016.15070890)
% It is specifically constructed for PRONIA data, so names of variables are based on PRONIA 
% data organisation and naming convention. These are the variables needed in the risk-calculator formula:

%   age: 'Study_date_sMRI_T0_yrs'
%   ** RAVLT: 'GAVLT_Immediate_*_repetition_list_A_T0' (the middle value changes between 1 and 3)
%   BACS_RAW: 'GDSST_Correct_number_symbol_matchings_T0' 
%   GFS_declinePastYear: 'GF_S_3_HighPastYearT0_T0' - 'GF_S_2_LowPastYearT0_T0'
%   P1: 'SIPS_P1_01_OVERALL_QUALY_B_00_0_SeverityScale_Screening'
%   P2: 'SIPS_P2_01_QUALY_B_00_0_SeverityScale_Screening'

% NAPLS formula:
%   lp <-   1.4468513 - 0.028694511 * age - 0.014936943 * BACS_RAW -
%         0.038728208 * HVLT + 0.20635307 * GFS_declinePastYear +
%         0.34883645 * P1P2
%   1-year psychosis free probability: 0.9012041^exp(lp)
%   2-year psychosis free probability: 0.8695878^exp(lp)

% ** The original NAPLS calulator used HVLT-R and PRONIA scores are built on a translation formula for all 
% subjects except those coming from Turku, because HVLT-R was used in this site.

%% Inputs and outputs

% inputs:
%   ids             subjects' ids (for PRONIA usually PSNs) to calculate the risk scores for (cell of strings, n x 1)
%   pathDataTable   path to a data table derived from a PRONIA-query extraction (make sure all variables needed are extracted)
%   outputFolder    path to a folder where the results should be stored

% outputs:
%   riskScores  structure containing these fields:
%               1. ids              cell array of strings containing the ids imputed matched with the data table
%               2. Risk             n x 2 vector of doubles (1st column is 1-year risk, second column 2-years risk) 
%               3. Outcome          n x 2 vector of doubles (1st column is 1-year outcome, second column 2-years outcome)
%               4. idsMissing       cell array of strings containing eventual requested ids not found in the main data table
%               5. riskVariables    table containing variables used in the calculator  

% Rachele, July 2019 @PRONIA


if nargin == 0
    ids = '/volume/NAPLS_calculator/Data/24-Jan-2019/PSN.mat';
    pathDataTable = '/opt/PRONIASoftware/Developpment/DataAllCron/DataQuery/Testing/HARMONY_RS/HARMONY_RS/DATA/25-Jan-2019/HARMONY_RS_Data_all_25-Jan-2019.mat';
    outputFolder = '/volume/NAPLS_calculator/Data/24-Jan-2019/';
end

cd(outputFolder);


%% 1. Create the matached data table
dataTable = load(pathDataTable); dataTable = dataTable.data_table_all; %load the main extraction table
ids = load(ids); ids = ids.PSN;
dataTable.PSN = cellstr(num2str(dataTable.PSN)); %change to string (usually this variable is double)
temp_table = table(ids);
[dataMatched,idsMatched] = nk_MatchID(dataTable.PSN,dataTable,ids,temp_table,'intersect'); %match the main extraction table with the IDs requested as inputs

% --------------------------------------------------------------------------------------
RiskScores.idsMissing = ids(~ismember(ids,dataTable.PSN)); %in case there are missing ids these will be saved in the final structure
% --------------------------------------------------------------------------------------


%% 2. Create variables
%1) AGE
age = cell2mat(cellfun(@str2double,dataMatched.AGE_GAF_T0_Screening,'UniformOutput',false));

% 2) BACS_RAW
BACS_RAW = dataMatched.GDSST_Correct_number_symbol_matchings_T0;

% 3) GFS_decline
GFS_declinePastYear = dataMatched.GF_S_3_HighPastYearT0_T0 - dataMatched.GF_S_2_LowPastYearT0_T0;

% 4) SIPS_P1P2
% Rescale the P1 and P2 variables (SIPS) such that 6 = 4, 5 = 3, 4 = 2, 3 = 1, 0-2 = 0
SIPS_P1 = 'SIPS_P1_01_OVERALL_QUALY_B_00_0_SeverityScale_Screening';
SIPS_P2 = 'SIPS_P2_01_QUALY_B_00_0_SeverityScale_Screening';
SIPS_P1P2 = dataMatched{:,{SIPS_P1,SIPS_P2}};

SIPS_P1P2(SIPS_P1P2 < 3) = 0; 
SIPS_P1P2(SIPS_P1P2 == 3) = 1;
SIPS_P1P2(SIPS_P1P2 == 4) = 2;
SIPS_P1P2(SIPS_P1P2 == 5) = 3;
SIPS_P1P2(SIPS_P1P2 == 6) = 4;
P1P2 = SIPS_P1P2(:,1)+SIPS_P1P2(:,2); %sum of P1 and P2 re-coded

% 5) HVLT
% a) for Turku: sum of HVLT 1-3
% b) for all other sites: a.*RAVLT_sum + b, where a = 0.4190959291 (slope of regression calculated on 37 HC) and b = 15.1473609862591 (intercept of regression calculated on 37 HC)
repetition1 = dataMatched.GAVLT_Immediate_1_repetition_list_A_T0;
repetition2 = dataMatched.GAVLT_Immediate_2_repetition_list_A_T0;
repetition3 = dataMatched.GAVLT_Immediate_3_repetition_list_A_T0;

% RAVLT re-coding 
RAVLT_sum = repetition1 + repetition2 + repetition3; %Sum of the first 3 RAVLT repetitions

a = 0.4190959291;  % a coefficient (slope of regression calculated on 37 HC) 
b = 15.1473609862591; % b coefficient (intercept of regression calculated on 37 HC)

% substitute for all subjects except those from Turku the translation to HVLT-R
for i=1:size(dataMatched,1)
    if ~strcmp(dataMatched.INSTITUTE_SHORTNAME_Screening(i),{'Uni Turku'})
        RAVLT_sum(i) = a.*RAVLT_sum(i) + b;
    end
end

HVLT = RAVLT_sum;

% Save variables into a table
riskVariables = table(age,BACS_RAW,dataMatched.GF_S_3_HighPastYearT0_T0,dataMatched.GF_S_2_LowPastYearT0_T0,dataMatched{:,{SIPS_P1,SIPS_P2}},HVLT); %create matrix of data that needs to be scaled containing all NaNs that need to be imputed
riskVariables.Properties.VariableNames = {'age','BACS_RAW','GFSHighest','GFSLowest','SIPS_P1P2','HVLT'}; %create feature names
RiskScores.riskVariables = riskVariables;


%% 3. Calculate the risk scores
lp =   1.4468513 - 0.028694511 * age - 0.014936943 * BACS_RAW - 0.038728208 * HVLT ...
    + 0.20635307 * GFS_declinePastYear + 0.34883645 * P1P2;

year1Outcome = 0.9012041.^exp(lp); 
year2Outcome = 0.8695878.^exp(lp);

%take 1 minus scores obtained to compute for risk for conversion vs non-conversion:

year1Risk = 1 - year1Outcome;
year2Risk = 1 - year2Outcome;

Outcome = [year1Outcome,year2Outcome]; %concatenate Outcome and Risk variables
Risk = [year1Risk,year2Risk];
RiskScores.Outcome = Outcome; %save them in a structure
RiskScores.Risk = Risk;
RiskScores.idsMatched = idsMatched;


%% 4. Save outputs
save([outputFolder 'RiskScores_' date '.mat'], 'RiskScores');


end