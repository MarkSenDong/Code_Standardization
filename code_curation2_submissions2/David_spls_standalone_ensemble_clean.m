%% DP SPLS standalone function

function dp_spls_standalone_ensemble_clean(datafile)

%% initialize analysis folders
load(datafile, 'input', 'setup');

nn=1;
if ~exist([setup.analysis_folder  '/' input.name],'dir')
    mkdir([setup.analysis_folder  '/' input.name]);
    analysis_folder = [setup.analysis_folder  '/' input.name];
else
    while nn < 100
        if exist([setup.analysis_folder  '/' input.name '_' num2str(nn)],'dir')
            nn=nn+1;
        else
            mkdir([setup.analysis_folder  '/' input.name '_' num2str(nn)])
            analysis_folder = [setup.analysis_folder  '/' input.name '_' num2str(nn)];
            nn=100;
        end
    end
end

%% 1. prepare analysis folders
mkdir([analysis_folder '/permutation']);
permutation_folder = [analysis_folder '/permutation']; % folder for permutation testing
mkdir([analysis_folder '/hyperopt']);
hyperopt_folder = [analysis_folder '/hyperopt']; % folder for permutation testing
mkdir([analysis_folder '/detailed_results']);
detailed_results = [analysis_folder '/detailed_results'];
mkdir([analysis_folder '/final_results']);
final_results = [analysis_folder '/final_results'];
mkdir([analysis_folder '/bootstrap']);
bootstrap_folder = [analysis_folder '/bootstrap'];

%% 2. set parameters for SPLS analysis
if isfield(input, 'MRI')
    load(input.MRI);
    X = MRI_for_analysis;
    clear('MRI_for_analysis');
else
    X = input.X;
end

if isfield(input, 'behavior')
    Y = input.behavior;
else
    Y = input.Y;
end

if ~isfield(input, 'permutations')
    input.permutations = 5000;
end
B = input.permutations;

if ~isfield(input, 'inner_folds')
    input.inner_folds = 10;
end
K = input.inner_folds;

if ~isfield(input, 'outer_folds')
    input.outer_folds = 10;
end
W = input.outer_folds;

FDRvalue = 0.05; % significance threshold for FDR testing, Default: 0.05

if ~isfield(input, 'size_sets_permutation')
    input.size_sets_permutation = round(input.permutations/40);
end
size_sets_permutation = input.size_sets_permutation;

if ~isfield(input, 'correlation_method')
    input.correlation_method = 'Spearman';
end
correlation_method = input.correlation_method;

if ~isfield(input, 'scaling_method')
    input.scaling_method = 'mean-centering';
end
scaling_method = input.scaling_method;

if ~isfield(input, 'type_analysis')
    input.type_analysis = 3;
end

if ~isfield(input, 'matrices_to_correct')
    input.matrices_to_correct = {'X', 'Y'};
end

if ~isfield(input, 'ensemble')
    input.ensemble = 0.1;
end

if ~isfield(input, 'cov_correction')
    input.cov_correction = 1;
end

if ~isfield(input, 'coun_ts_limit')
    input.coun_ts_limit = 1;
end

switch setup.type_analysis
    case 'LSOV'
        W   = size(input.sites,2);       % number of outer folds, Default: 10
end

if ~isfield(input, 'grid_x')
    input.grid_x = struct;
end

if ~isfield(input, 'grid_y')
    input.grid_y = struct;
end

% baseline = struct('matrices', {'none'}, 'dynamic',[1,1]); % 1st element: start of dynamic grid enforcement; 2nd element: 0-1, sparse-full grid
% if ~isfield(input, 'grid_dynamic')
%     input.grid_dynamic = baseline; % 1st element: start of dynamic grid enforcement; 2nd element: 0-1, sparse-full grid
%     input.grid_dynamic.baseline_upper = struct('cu', 1, 'cv', 1);
%     input.grid_dynamic.baseline_lower = struct('cu', 1, 'cv', 1);
%     input.grid_dynamic.follow_upper = struct('cu', 1, 'cv', 1);
%     input.grid_dynamic.follow_lower = struct('cu', 1, 'cv', 1);
% end


%% 5. LV loop

% this loop is repeated for the next vector pair u and v as long as the
% previous vector pair was significant. If the previous vector was not
% significant, then the loop will stop

% ff counts the iteration through the LV loops, so that the results for each
% LV can be stored in separate rows
ff = 1;

% define column names for matrices so that you can access them later by
% indexing
output.parameters_names = {'w', 'cu', 'cv', 'u', 'v', 'success', 'RHO', 'p', 'epsilon', 'omega', 'epsilon_all', 'omega_all'}; % names of parameters for optimal cu/cv combination of the w-th loop
opt_parameters_names = {'w', 'cu', 'cv', 'u', 'v', 'success', 'RHO', 'p', 'epsilon', 'omega', 'epsilon_all', 'omega_all'};

% preallocate placeholder matrices for higher speed
output.final_parameters = num2cell(nan(size(Y,2), numel(output.parameters_names))); % cell array to store final parameters for each LV iteration

% indices for later use
opt_u = strcmp(output.parameters_names,'u');
opt_v = strcmp(output.parameters_names,'v');
opt_p = strcmp(output.parameters_names,'p');

grid_default = struct;
size_sets_hyperopt = 20;
[cu_cv_combination, hyperopt_sets] = dp_cu_cv(X, Y, grid_default, grid_default, size_sets_hyperopt, hyperopt_folder);

% set up outer fold CV partitions, balanced for diagnoses
switch setup.type_analysis
    case 'LSOV'
        output.cv_outer = struct;
        output.cv_outer = dp_LSOVpartition(input.sites);
    otherwise
        switch input.framework(1)
            case 1
                try
                    output.cv_outer = struct;
                    output.cv_outer = nk_CVpartition2(1, W, input.data_collection.Diag);
                catch
                    disp(['Not enough subjects for nested cross-validation with ', num2str(W), ' outer folds']);
                end
            case 2
                try
                    output.cv_outer = struct;
                    output.cv_outer = dp_HOpartition(W, input.data_collection.Diag);
                catch
                    disp('Something went wrong with the hold-out partitions in the outer fold. Please check your label data.');
                end
        end
end

for i=1:W
    output.hold_out_Diag{i} = input.data_collection.Diag(output.cv_outer.TestInd{i},:);
end

for w=1:W
    keep_in_Diag = input.data_collection.Diag(output.cv_outer.TrainInd{w},:);
    switch input.framework(1)
        case 1
            try
                output.cv_inner.(['fold_', num2str(w)]) = nk_CVpartition2(1, K, keep_in_Diag);
            catch
                disp(['Not enough subjects for nested cross-validation with ', num2str(K), ' inner folds']);
            end
        case 2
            try
                output.cv_inner.(['fold_', num2str(w)]) = dp_HOpartition(K, keep_in_Diag);
            catch
                disp('Something went wrong with the hold-out partitions in the inner fold. Please check your label data.');
            end
    end
end

% set count for not significant LVs to 0, it is increased by 1 everytime an
% LV is not significant. If three LVs in a row are not significant, then
% the while loop stops and the algorithm is done. However, as soon as one
% LV is significant again, the count is set back to 0. This way, the
% algorithm only stops when three LVs in a row are not significant.
count_ns = 0;

% here starts the outer loop for each single LV, the next LV is only
% computed if the previous LV was significant (with FDR correction)
while count_ns<input.coun_ts_limit
    
    %% 3. Wide loop
    % repeats the entire process W times to obtain W different final p values,
    % which go into the omnibus hypothesis
    
    % matrix to store the optimal parameters of the w-th loop
    opt_parameters = num2cell(nan(W,numel(output.parameters_names)));
    
    if any(ff==input.grid_dynamic.onset)
        grid_x = input.grid_dynamic.(['LV_', num2str(ff)]).x;
        grid_y = input.grid_dynamic.(['LV_', num2str(ff)]).y;
        if ~isfield(input, 'size_sets_hyperopt')
            input.size_sets_hyperopt = round((grid_x.density*grid_y.density)/40);
        end
        size_sets_hyperopt = input.size_sets_hyperopt;
        
        if size_sets_hyperopt==0
            size_sets_hyperopt=1;
        end
        [cu_cv_combination, hyperopt_sets] = dp_cu_cv(X, Y, grid_x, grid_y, size_sets_hyperopt, hyperopt_folder);
    end
    
    for w=1:W
        
        %% hyper-parameter optimisation
        % remove hp% of the data randomly and keep it in a hold-out
        % dataset, the rest is called the keep_in data for training/testing
        % the algorithm
        
        switch setup.type_analysis
            case 'uncorrected'
                
                hold_out_x = X(output.cv_outer.TestInd{w},:);
                hold_out_y = Y(output.cv_outer.TestInd{w},:);

                keep_in_x = X(output.cv_outer.TrainInd{w},:);
                keep_in_y = Y(output.cv_outer.TrainInd{w},:);
                
                keep_in_Diag = input.data_collection.Diag(output.cv_outer.TrainInd{w},:);
                cv_inner = output.cv_inner.(['fold_', num2str(w)]);
                
                % standardize keep in partitions
                IN_x = struct; IN_y = struct;
                IN_x.method = scaling_method;
                IN_y.method = scaling_method;

                [keep_in_data_x,IN_x] = dp_standardize(keep_in_x, IN_x);
                [keep_in_data_y,IN_y] = dp_standardize(keep_in_y, IN_y);
                
                % apply same standardization on hold out partition
                [hold_out_data_x,~] = dp_standardize(hold_out_x, IN_x);
                [hold_out_data_y,~] = dp_standardize(hold_out_y, IN_y);
                
                save([hyperopt_folder '/keep_in_partition.mat'], 'keep_in_data_x', 'keep_in_data_y', 'keep_in_Diag', 'cv_inner', 'correlation_method');
                
            case 'correct'
                
                output.cov = [input.covariates, input.sites];
                
                hold_out_x = X(output.cv_outer.TestInd{w},:);
                hold_out_y = Y(output.cv_outer.TestInd{w},:);
                hold_out_covariates_temp = output.cov(output.cv_outer.TestInd{w},:);
                
                keep_in_x = X(output.cv_outer.TrainInd{w},:);
                keep_in_y = Y(output.cv_outer.TrainInd{w},:);
                keep_in_covariates_temp = output.cov(output.cv_outer.TrainInd{w},:);
                
                keep_in_Diag = input.data_collection.Diag(output.cv_outer.TrainInd{w},:);
                cv_inner = output.cv_inner.(['fold_', num2str(w)]);

                %% correct and scale data
                % scale covariate data
                IN_c_c = struct; 
                IN_c_c.method = scaling_method;
                [keep_in_covariates,IN_c_c] = dp_standardize(keep_in_covariates_temp, IN_c_c);
                
                % apply same standardization on hold out covariates
                [hold_out_covariates,~] = dp_standardize(hold_out_covariates_temp, IN_c_c);
                
                switch input.cov_correction
                    case 1
                        if ff==1
                            to_correct = true;
                        else
                            to_correct = false;
                        end
                    case 2
                        to_correct = true;
                end
                
                if to_correct
                    for ii=1:size(input.matrices_to_correct,2)
                        switch input.matrices_to_correct{ii}
                            case 'X'
                                IN_c_x = [];
                                IN_c_x.TrCovars = keep_in_covariates;
                                [c_keep_in_x, IN_c_x] = nk_PartialCorrelationsObj(keep_in_x, IN_c_x);
                                IN_c_x.TsCovars = hold_out_covariates;
                                [c_hold_out_x, ~] = nk_PartialCorrelationsObj(hold_out_x, IN_c_x);
                            case 'Y'
                                IN_c_y = []; IN_c_y.TrCovars = keep_in_covariates;
                                [c_keep_in_y, IN_c_y] = nk_PartialCorrelationsObj(keep_in_y, IN_c_y);
                                IN_c_y.TsCovars = hold_out_covariates;
                                [c_hold_out_y, ~] = nk_PartialCorrelationsObj(hold_out_y, IN_c_y);
                        end
                    end
                    
                    if ~strcmp(input.matrices_to_correct, 'X')
                        c_keep_in_x = keep_in_x;
                        c_hold_out_x = hold_out_x;
                    end
                    
                    if ~strcmp(input.matrices_to_correct, 'Y')
                        c_keep_in_y = keep_in_y;
                        c_hold_out_y = hold_out_y;
                    end
                else
                    c_keep_in_x = keep_in_x;
                    c_hold_out_x = hold_out_x;
                    c_keep_in_y = keep_in_y;
                    c_hold_out_y = hold_out_y;
                end

                % standardize keep in partitions
                IN_x = struct; IN_y = struct;
                IN_x.method = scaling_method;
                IN_y.method = scaling_method;
                [keep_in_data_x,IN_x] = dp_standardize(c_keep_in_x, IN_x);
                [keep_in_data_y,IN_y] = dp_standardize(c_keep_in_y, IN_y);
                
                % apply same standardization on hold out partition
                [hold_out_data_x,~] = dp_standardize(c_hold_out_x, IN_x);
                [hold_out_data_y,~] = dp_standardize(c_hold_out_y, IN_y);
                
%                 keep_in_data_x(:,isnan(keep_in_data_x(1,:))) = 0;
%                 keep_in_data_y(:,isnan(keep_in_data_y(1,:))) = 0;
%                 hold_out_data_x(:,isnan(hold_out_data_x(1,:))) = 0;
%                 hold_out_data_y(:,isnan(hold_out_data_y(1,:))) = 0;
                
                save([hyperopt_folder '/keep_in_partition.mat'], 'keep_in_data_x', 'keep_in_data_y', 'keep_in_Diag', 'IN_x', 'IN_y', 'cv_inner', 'correlation_method');
                
            case 'LSOV'
                
                output.hold_out_Diag = [];
                index_holdout = input.sites(:,w) == 1; %strcmp(sites_names,sites_names{1,w}))==1;
                
                IN_x = struct; IN_y = struct;
                keep_in_data_x = dp_standardize(X(~index_holdout,:), IN_x);
                keep_in_data_y = dp_standardize(Y(~index_holdout,:), IN_y);
                keep_in_Diag = input.data_collection.Diag(~index_holdout,:);
                output.hold_out_Diag{w} = input.data_collection.Diag(index_holdout,:);
%                 output.hold_out_labels = labels_outer(index_holdout,:);
                
                hold_out_data_x = dp_standardize(X(index_holdout,:), IN_x);
                hold_out_data_y = dp_standardize(Y(index_holdout,:), IN_y);
                %                 output.output.hold_out_labels = labels_outer(index_holdout,:);
                
                save([hyperopt_folder '/keep_in_partition.mat'], 'keep_in_data_x', 'keep_in_data_y', 'keep_in_Diag', 'K', 'input.framework', 'correlation_method');
                
        end
        
        mem_total           = 80;   % max: 40
        max_sim_jobs        = 40;   % max: 60
        
        [RHO_avg_collection_temp, success_opt] = dp_RHO_fullpara(setup.spls_standalone_path, hyperopt_folder, 'hyperopt', mem_total, max_sim_jobs, setup.queue_name_slave, hyperopt_sets, size_sets_hyperopt);
        
        while ~success_opt
            disp('Hyperopt step failed, job had to be resent again!');
            [RHO_avg_collection_temp, success_opt] = dp_RHO_fullpara(setup.spls_standalone_path, hyperopt_folder, 'hyperopt', mem_total, max_sim_jobs, setup.queue_name_slave, hyperopt_sets, size_sets_hyperopt);
        end
        
        RHO_avg_collection = RHO_avg_collection_temp;
        
%         %     select the hyperparameter combination with the highest average
%         %     correlation, ie the one with the highest RHO_avg
%         opt_matrix = flipud(sortrows([RHO_avg_collection, cu_cv_combination],1)); 
%         
%         % take the top 10% and test them on the hold-out split
%         best_hyper_comb = opt_matrix(round(0.1*size(RHO_avg_collection,1)),2:3);
        
        %     select the hyperparameter combination with the highest average
        %     correlation, ie the one with the highest RHO_avg
        save([hyperopt_folder, '/checkpoint_hyperopt.mat'], 'RHO_avg_collection', 'RHO_avg_collection_temp', 'cu_cv_combination');
        cc=1;
        while cc<5
            try
                opt_matrix = flipud(sortrows([RHO_avg_collection, cu_cv_combination],1));
                cc=5;
            catch 
                cc=cc+1;
                if cc==4
                    disp(['Something is wrong in the hyperopt step. The RHO',...
                        ' collection cannot be concatenated to the cu_cv_combination',...
                        ' file. Check hyperopt folder. Operation is paused.',...
                        'A file called ''pause.mat'' is saved in hyperopt folder ',...
                        ', to restart operation, delete this file.']);
                    pause_file = true;
                    pause_path = [hyperopt_folder, '/pause.mat'];
                    save(pause_path, 'pause_file');
                    pause_dir = dir(pause_path);
                    while size(pause_dir,1)>0
                        pause_dir = dir(pause_path);
                    end
                    cc=1;
                else
                    clear('RHO_avg_collection');
                    dp_cleanup_files(hyperopt_folder, 'RHO');
                    dp_cleanup_files(hyperopt_folder, 'init');
                    [RHO_avg_collection_temp, success_opt] = dp_RHO_fullpara(setup.spls_standalone_path, hyperopt_folder, 'hyperopt', mem_total, max_sim_jobs, setup.queue_name_slave, hyperopt_sets, size_sets_hyperopt);
                    while ~success_opt
                        disp('Hyperopt step failed, job had to be resent again!');
                        [RHO_avg_collection_temp, success_opt] = dp_RHO_fullpara(setup.spls_standalone_path, hyperopt_folder, 'hyperopt', mem_total, max_sim_jobs, setup.queue_name_slave, hyperopt_sets, size_sets_hyperopt);
                    end
                    RHO_avg_collection = RHO_avg_collection_temp;
                end
            end
        end
        
        % take the top X% from the inner fold and test them on the hold-out split
        best_hyper_comb = opt_matrix(1:round(input.ensemble.selection*size(RHO_avg_collection,1)),2:3);
        
        IN = struct;
        IN.method = scaling_method;
        X_temp = dp_standardize(X, IN);
        
        IN = struct;
        IN.method = scaling_method;
        Y_temp = dp_standardize(Y, IN);
        
        RHO_max = 0;
        switch input.ensemble.method
            case 1 % best
                for i=1:size(best_hyper_comb,1)
                    [u_opt_temp, v_opt_temp, ~, ~, V_opt_temp, success_opt_temp]=dp_spls(keep_in_data_x, keep_in_data_y,best_hyper_comb(i,1), best_hyper_comb(i,2));
                    epsilon_opt_temp = hold_out_data_x * u_opt_temp;
                    omega_opt_temp = hold_out_data_y * v_opt_temp;
                    RHO_opt_temp = corr(epsilon_opt_temp,omega_opt_temp, 'Type', correlation_method);
                    if abs(RHO_opt_temp) > RHO_max
                        RHO_opt = RHO_opt_temp;
                        cu_opt = best_hyper_comb(i,1);
                        cv_opt = best_hyper_comb(i,2);
                        epsilon_opt = epsilon_opt_temp;
                        omega_opt = omega_opt_temp;
                        u_opt = u_opt_temp;
                        v_opt = v_opt_temp;
                        epsilon_all = X_temp * u_opt;
                        omega_all = Y_temp * v_opt;
                        success_opt = success_opt_temp;
                        RHO_max = abs(RHO_opt_temp);
                        V_opt = V_opt_temp;
                    end
                end
            case 2 % ensemble merging
                switch input.ensemble.measure
                    case 'mean'
                        ensemble_comb = mean(best_hyper_comb,1);
                    case 'median'
                        ensemble_comb = median(best_hyper_comb,1);
                end
                cu_opt = ensemble_comb(1);
                cv_opt = ensemble_comb(2);
                [u_opt, v_opt, ~, ~, V_opt, success_opt]=dp_spls(keep_in_data_x, keep_in_data_y,cu_opt, cv_opt);
                epsilon_opt = hold_out_data_x * u_opt;
                omega_opt = hold_out_data_y * v_opt;
                RHO_opt = corr(epsilon_opt,omega_opt, 'Type', correlation_method);
                RHO_max = abs(RHO_opt_temp);
                epsilon_all = X_temp * u_opt;
                omega_all = Y_temp * v_opt;
        end
        
        output.opt_matrix.(['LV_', num2str(ff)]).(['iteration_', num2str(w)]) = opt_matrix;
        output.best_hyper_comb.(['LV_', num2str(ff)]).(['iteration_', num2str(w)]) = best_hyper_comb;
        
        %% Statistical Evaluation
        
        %train the model with the optimal cu/cv combination on the previous
        %train/test data set to get u and v
%         [u_opt, v_opt, U_opt, S_opt, V_opt, success_opt]=dp_spls(keep_in_data_x, keep_in_data_y,cu_opt, cv_opt);
%         
%         %project the hold_out data set on the computed u and v vectors to
%         %get the absolute correlations between these projections
%         epsilon_opt = hold_out_data_x * u_opt;
%         omega_opt = hold_out_data_y * v_opt;
%         
%         disp('checkpoint projection');
% 
%         RHO_opt = corr(epsilon_opt,omega_opt, 'Type', 'Spearman');
%         RHO_opt_abs = abs(RHO_opt);

        %     Now comes the permutation step, where the order of the samples in one
        %     view (in this case the Y matrix) gets permuted and the algorithm is
        %     trained on the permuted data set with a destroyed relationship
        %     between X and Y, this process is repeated B times
        
        % write a bash script for hyperparameter optimization, which can
        % later be called
        % set parameters for queue submission
        mem_total           = 80;   % max: 40
        max_sim_jobs        = 40;   % max: 60
        rest_perm = mod(B,size_sets_permutation);
        
        if rest_perm>0
            disp('Please choose a number of permutation sets, which can be divided by 40!');
        end
        
        perm_sets = (B - rest_perm)/size_sets_permutation;
        
        % save the optimized parameters and the permutation matrix
        save([permutation_folder '/opt_param.mat'],...
            'keep_in_data_x',...
            'keep_in_data_y',...
            'hold_out_data_x',...
            'hold_out_data_y',...
            'cu_opt',...
            'cv_opt',...
            'keep_in_Diag', 'V_opt',...
            'correlation_method');
        
        [RHO_b_collection_temp, success_perm] = dp_RHO_fullpara(setup.spls_standalone_path, permutation_folder, 'permutation', mem_total, max_sim_jobs, setup.queue_name_slave, perm_sets, size_sets_permutation);
        
        while ~success_perm
            disp('Permutation step failed, job had to be resend again!');
            [RHO_b_collection_temp, success_perm] = dp_RHO_fullpara(setup.spls_standalone_path, permutation_folder, 'permutation', mem_total, max_sim_jobs, setup.queue_name_slave, perm_sets, size_sets_permutation);
        end
        
        RHO_b_collection = RHO_b_collection_temp;
        
        % test the following null hypothesis H_s: "There is no relationship
        % between the two views, therefore the correlation obtained with
        % the original data is not different from the correlation
        % obtained with the permuted data"
        
        % calculate how many times RHO_b was bigger than or equal to RHO_opt,
        % ie how many times the permutated data led to a higher correlation
        % using spls than the original data
%         nan_count = sum(isnan(RHO_b_collection));
        RHO_count_b = sum(RHO_b_collection > RHO_max);
        
        % calculate the p value to test whether the null hypothesis is true
        %         p = ((1+RHO_count_b)/(B+1-nan_count));
        p = (RHO_count_b+1)/(B+1);
        
        % store all parameters of the w-th wide loop into a matrix
        opt_parameters(w,:) = {w cu_opt cv_opt u_opt v_opt success_opt RHO_opt p epsilon_opt omega_opt, epsilon_all, omega_all};
        save([detailed_results '/opt_parameters_' num2str(ff) '.mat'],'opt_parameters', 'opt_parameters_names', 'RHO_avg_collection', 'RHO_b_collection', 'best_hyper_comb', 'opt_matrix');
        
    end
    
    %% test the omnibus hypothesis using the p values
    
    % Omnibus hypothesis H_omni: "All the null hypotheses H_s are true" if
    % any of the p values are lower than the FDR-corrected threshold,
    % then the omnibus hypothesis can be rejected after that.
    
    % Search for the statistically significant w-th iteration with the
    % lowest p value, if more than one iteration has the same p value,
    % select the one that has the highest RHO value => this is the final
    % w-th iteration with the corresponding cu/cv features and u/v scores
    
    % calculate FDR-corrected p value
    output.pvalue_FDR(ff,1) = dp_FDR([opt_parameters{:,opt_p}], FDRvalue);
    
    IN = struct;
    IN.matrix_names = opt_parameters_names;
    IN.matrix = opt_parameters;
    IN.type_analysis = input.type_analysis;
    IN.p = output.pvalue_FDR(ff,1);
    
    if output.pvalue_FDR(ff,1)~=0
        output.final_parameters(ff,:) = dp_find_opt(IN);
    else
        log_p_min = cell2mat(opt_parameters(:,opt_p))==min(cell2mat(opt_parameters(:,opt_p)));
        output.final_parameters(ff,:) = opt_parameters(log_p_min,:);
    end
    
    disp('checkpoint omnibus');
    
    % the p value of this LV is updated from the previously set value of
    % zero to the actual p value of the LV, if this p value is lower than
    % the FDR_rate then the while loop continues after matrix deflation and
    % it keeps looking for the next possible significant LV. If the p value
    % is higher than the FDR_rate, then the while loop is discontinued and
    % the algorithm stops. Therefore, this function generates all possible
    % significant LVs and also the first non-significant LV, afterwards the
    % algorithm stops.
    p_LV = output.final_parameters{ff,opt_p};
    
    % ff counts through the most outside LV while loop = counts the amount
    % of significant LVs
    
    if p_LV > output.pvalue_FDR(ff,1)
        count_ns = count_ns+1;
    else
        count_ns = 0;
        
        %% Matrix Deflation => Projection Deflation
        % This method removes the covariance explained by u and v from X
        % and Y by projecting the data matrices onto the space spanned by the
        % corresponding weight vector, and subtracting this from the data:
        u = output.final_parameters{ff,opt_u}; % weight vector for X
        v = output.final_parameters{ff,opt_v}; % weight vector for Y
        [X,Y] = proj_def(X, Y, u, v);
        disp('checkpoint deflation');

    end
    
    save([final_results, '/preliminary_result.mat'], 'input', 'output', 'setup');
    
    ff = ff+1;
    
end

% after the LVs are computed, clean up the final parameters matrix by removing empty rows
output.final_parameters(ff:end,:) = [];

save([final_results, '/result.mat'], 'input', 'output', 'setup');
delete([final_results, '/preliminary_result.mat']);

cd(final_results);

rmdir(hyperopt_folder, 's');
rmdir(permutation_folder,'s');
rmdir(bootstrap_folder, 's');
end