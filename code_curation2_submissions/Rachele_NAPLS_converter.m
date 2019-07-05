%% Script to get the NAPLS-calculator risk scores
% 
% This script calculates 1-year and 2-years outcome and risk for psychosis scores
% based on a limited amount of clinical and neuropsychological variables. It is based on doi:10.1176/appi.ajp.2016.15070890 
% (for an online version of the tool see: http://riskcalc.org:3838/napls/)

% Rachele, July 2019 @PRONIA

addpath(genpath('/opt/NM/NeuroMiner_Release')); %for NeuroMiner functions
addpath('/volume/NAPLS_calculator/ScrFun');


%% LOAD DATA 
% 1) load the PSN list you want to calculate the risk scores for 
% 2) set the path to a query-derived PRONIA-data table
% 3) set an output folder where to save the results

% load(whatevercellstringyouwant);
% ids = whatevercellstringyouwant;
% PathDataTable = whateverpathwherethetableis;
% outputFolder = whateveroutputfolderyouwant;


%% CALCULATE RISK SCORES
RiskScores = RiskCalculator;


%% PLOT RISK SCORES
histogram(RiskScores.Risk(:,1),'facecolor','green','facealpha',0.5,'edgecolor','none')
hold on
histogram(RiskScores.Risk(:,2),'facecolor','yellow','facealpha',0.5,'edgecolor','none') 
box off
axis tight
% legend('1yr outcome','2yr outcome','1yr risk','2yr risk','location','Best');
legend('1yr risk','2yr risk','location','Best');
legend boxoff


%% IMPUTATION OF NaNs
% 1) Scaling 
dataToImpute = table2array(RiskScores.riskVariables);

mapY.Tr.scale{1} = [];
mapY.Tr.scale{1}.IN.overmatflag = 0; 
mapY.Tr.scale{1}.IN.ZeroOne = 1;
mapY.Tr.scale{1}.IN.revertflag = 0;
mapY.Tr.scale{1}.IN.zerooutflag = 1;
mapY.Tr.scale{1}.IN.AcMatFl = [];
mapY.Tr.scale{1}.data = [];

[mapY.Tr.scale{1}.data,mapY.Tr.scale{1}.IN] = nk_PerfScaleObj(dataToImpute,mapY.Tr.scale{1}.IN);

% 2) Imputation 
mapY.Tr.impute.INcont.blockind = [];
mapY.Tr.impute.INcont.method = 'euclidean'; 
mapY.Tr.impute.INcont.X = mapY.Tr.scale{1,1}.data;
mapY.Tr.impute.INcont.k = 7; % number of nearest neighbors to impute --> in this case 7 features

[mapY.Tr.impute.data, mapY.Tr.impute.IN] = nk_PerfImputeObj(mapY.Tr.scale{1,1}.data, mapY.Tr.impute.INcont);

% 3) Reverse scaling
mapY.Tr.scale{1}.IN.revertflag = 1;
[dataImputed,mapY.Tr.scale{1}.IN] = nk_PerfScaleObj(mapY.Tr.impute.data,mapY.Tr.scale{1}.IN);
dataImputed = array2table(dataImputed);
dataImputed.Properties.VariableNames = {'age','BACS_RAW','GFSHighest','GFSLowest','SIPS_P1','SIPS_P2','HVLT'}; %create feature names


%% CREATE NEW RISK SCORES WITH IMPUTED DATA
% *First you need to re-code the SIPS P1P2 variables 
SIPS_P1P2 = [dataImputed.SIPS_P1,dataImputed.SIPS_P2];
SIPS_P1P2(SIPS_P1P2 < 3) = 0; 
SIPS_P1P2(SIPS_P1P2 == 3) = 1;
SIPS_P1P2(SIPS_P1P2 == 4) = 2;
SIPS_P1P2(SIPS_P1P2 == 5) = 3;
SIPS_P1P2(SIPS_P1P2 == 6) = 4;
P1P2 = SIPS_P1P2(:,1)+SIPS_P1P2(:,2); 

% calculate GFS decline past year
GFS_declinePastYear = dataImputed.GFSHighest - dataImputed.GFSLowest;

lp =   1.4468513 - 0.028694511 * dataImputed.age - 0.014936943 * dataImputed.BACS_RAW - 0.038728208 * dataImputed.HVLT ...
    + 0.20635307 * GFS_declinePastYear + 0.34883645 * P1P2;

year1OutcomeImputed = 0.9012041.^exp(lp); 
year2OutcomeImputed = 0.8695878.^exp(lp);

% take 1 minus scores obtained to compute for risk for conversion vs non-conversion:
year1RiskImputed = 1 - year1OutcomeImputed;
year2RiskImputed = 1 - year2OutcomeImputed;

OutcomeImputed = [year1OutcomeImputed,year2OutcomeImputed]; %concatenate Outcome and Risk variables
RiskImputed = [year1RiskImputed,year2RiskImputed];
RiskScores.OutcomeImputed = OutcomeImputed; %save them in a structure
RiskScores.RiskImputed = RiskImputed;


%% PLOT RISK SCORES with and without imputed data
histogram(RiskScores.Risk(:,1),'facealpha',0.5,'edgecolor','none') 
hold on
histogram(RiskScores.RiskImputed(:,2),'facecolor','r','facealpha',0.5,'edgecolor','none')
hold on
histogram(RiskScores.Risk(:,1),'facecolor','green','facealpha',0.5,'edgecolor','none')
hold on
histogram(RiskScores.RiskImputed(:,2),'facecolor','yellow','facealpha',0.5,'edgecolor','none') 
box off
axis tight
legend('1yr risk','2yr risk','1yr risk imp','2yr risk imp','location','Best');
legend boxoff
