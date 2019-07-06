########################
## CV new pipeline
########################
# (c) JU_14062019

# This script runs literature informed optimisation pipeline for clustering. 
# Conceptual and methodological aspects can be found under:
# '/Users/Julian/Desktop/projects/COG_SUB_01062019/manuscript/'


# empty workspace, define general project path, load project functions
rm(list=ls())
project_path <- '/Users/Julian/Desktop/projects/COG_SUB_01062019'
setwd(paste0(project_path, '/project_functions/'))
sapply(list.files(), source)

# define project dirs and load/install packages needed
activate_pkg(list_of_packages = c('e1071', 'tidyr', 'fpc', 'rlist', 'caret', 'UBL', 'devtools', 'ggplot2', 'VIM', 'doBy')) # installs all relevant packages 
COG_SUB_paths(project_path, raw = 0, prepro = 1, clust = 1, MRI = 1)


####################################################################################################################

###############
## data entry
##############

# load in (uncorrected) patient data
setwd(prepro_results_dir)
data <- read.csv('data_no_imp.csv', header = TRUE, sep = ',', dec = '.')

# add edu variable to patient data
setwd(prepro_data_dir1)
data_edu_ROP <- read.csv('DataQuery_LKI_GA_04_2018_JU_Data_all_07-Nov-2018.csv', header = TRUE, sep = ',', dec = '.', na.strings='NaN')[, c('PSN', 'DEMOG_T0T1T2_31AA_EducationYears_T0')]
setwd(prepro_data_dir2)
data_edu_HC <- read.csv('DataQuery_LKI_JU_01_2019_Data_all_01-Feb-2019.csv', header = TRUE, sep = ',', dec = '.', na.strings='NaN')[, c('PSN', 'DEMOG_T0T1T2_31AA_EducationYears_T0')]
data <- merge(data, data_edu_ROP, by='PSN', all.x=T)
data_HC <- merge(data_HC, data_edu_HC, by='PSN', all.x=T)
names(data)[names(data)=='DEMOG_T0T1T2_31AA_EducationYears_T0'] <- 'Edu_years'
names(data_HC)[names(data_HC)=='DEMOG_T0T1T2_31AA_EducationYears_T0'] <- 'Edu_years'
data[is.na(data$Edu_years),'Edu_years'] <- median(data$Edu_years, na.rm=T)
data_HC[is.na(data_HC$Edu_years),'Edu_years'] <- median(data_HC$Edu_years, na.rm=T)

# variables indices for patient data
neuropsy_ind <- c(49:53, 58:131, 136:139) # indices of neuropsy vars
clinical_ind <- c(5:10, 132:134 ,41:48)   # indices of clinical vars 

# load in imputed healthy control data
data_HC <- read.csv('data_preprocessed_HC_2019-04-23.csv', header = TRUE, sep = ',', dec = '.')
colnames(data_HC)[colnames(data_HC)=='SEX_GAF_T0_Screening'] <- 'SEX_T0' 

# variable indices for healthy control data
np_ind_HC  <- c(39:43, 48:121, 126:129) # indices of NP vars in healthy controls

###############################
## specifications of pipeline
###############################

num_perm <- 5 # number of subsettings of the data set 
perm <- 1:num_perm # permutation range
perc <- 0.75  # amount of cases by which data is subset in percentage
num_cluster <- 2:5 # numbers of cluster to be investigated
clust_alg <- c('kmeans', 'hierach')  # clustering algorithms: 'kmeans', 'hierach' are allowed

#################################
## Start permutation analysis
#################################

# initialise data frame
optim_df_total <- data.frame(clus_alg=NULL, num_cluster=NULL, cluster_size=NULL, adasyn=NULL, cluster_size_adasyn=NULL, stability_subset=NULL, 
                             stability_noise=NULL, BAC=NULL, BAC_sig=NULL, permut=NULL )

# create list of unique random sequences for permutation of patients
repeat{
  seq_list <- list()
  for(perm in 1:num_perm){   
    rand_row_seq <- sample(1:nrow(data), nrow(data))  
    seq_list[[perm]] <- rand_row_seq[1:(round((nrow(data)*perc), digits=0))] 
  }
  
  # check whether permutation lists indeed are non-equal
  seq_list_sorted <- lapply(seq_list, sort)   # has to be sorted (increasingly)
  if(length(unique(seq_list_sorted)) < num_perm){  # if not every list is unique --> repeat process
    warning('Not perfect permutation. Permutation process has to be repeated.')
  } else if(length(unique(seq_list_sorted)) == num_perm){   # if every list is a unique case --> break cycle and continue with further analysis
    message('Permutation process successful. Continue with analysis.')
    break
  }
}


for(perm in 1:num_perm){   # go through all subsets of the patient data set and (1) preprocess, (2) cluster, (3) classify 
  
  ############################################################
  ## Select current subsample and preprocess it
  ############################################################
  
  ## select random subsample (based on index list created above) of data for clustering for p'th permutation
  data_clustering_ind <- seq_list[[perm]]   # get first 80% of random indices of data set
  data_clustering <- data[data_clustering_ind,]  # data to preprocess and cluster

  ## scale the data
  data_clustering[, neuropsy_ind] <- scale(data_clustering[,neuropsy_ind])
  data_clustering[, clinical_ind] <- scale(data_clustering[,clinical_ind])
    
  ## imputation of missings using knn
  # np variables based on np variables
  data_clustering_imp_NP <- kNN(data_clustering, variable=names(data_clustering)[neuropsy_ind], k=round(sqrt(nrow(data_clustering))), dist_var=names(data_clustering)[neuropsy_ind], useImputedDist = F)    
  data_clustering_imp_NP <- data_clustering_imp_NP[,1:ncol(data_clustering)]   # delete impute logicals
  
  # clinical variables based on clinical variables
  data_clustering_imp_NP_clin <- kNN(data_clustering_imp_NP, variable=names(data_clustering_imp_NP)[clinical_ind], k=round(sqrt(nrow(data_clustering))), dist_var=names(data_clustering_imp_NP)[clinical_ind], useImputedDist = F)
  data_clustering_imp_NP_clin <- data_clustering_imp_NP_clin[,1:ncol(data_clustering)]   # delete impute logicals
  
  # rename again
  data_clustering <- data_clustering_imp_NP_clin
  
  ## regression of covariates --> site, sex, age, education year --> HC model applied to ROP
  np_vars2correct <- names(data_clustering)[neuropsy_ind]   # names of variables to be corrected by regression
  if(sum(names(data_HC)[np_ind_HC] == names(data_clustering)[neuropsy_ind])==ncol(data_clustering[,neuropsy_ind])){   # only if variables in both data sets match
    for(i in 1:length(np_vars2correct)){
      # create model on HC and apply it to ROP patients to correct/replace old values for covars corrected ones
      lm_HC<- lm(data_HC[,np_vars2correct[i]] ~ (SEX_T0 + Age_corrected + INSTITUTE_ID_T0 + Edu_years)^2 + (SEX_T0 + Age_corrected + INSTITUTE_ID_T0 + Edu_years)^3 + (SEX_T0 + Age_corrected + INSTITUTE_ID_T0 + Edu_years)^4, data= data_HC)   # build HC regression model
      pred_value <- predict(lm_HC, newdata = data_clustering[,c('SEX_T0', 'Age_corrected', 'INSTITUTE_ID_T0', 'Edu_years')])         # predict value of ROP data based on HC regression model
      data_clustering[,np_vars2correct[i]] <- data_clustering[,np_vars2correct[i]] - pred_value                    # get residuals for ROP data (corrected values)
    }
  } else {
    warning('variables do not match.')
  }
  
  ## intitialise optim data frame for current subsample based on specifications (cluster algorithm, range of cluster numbers) above
  optim_df <- tidyr::crossing(clust_alg, num_cluster)
  optim_df$cluster_size <- NA
  optim_df$adasyn <- 0
  optim_df$cluster_size_adasyn <- NA
  optim_df$stability_subset <- NA
  optim_df$stability_noise  <- NA
  optim_df$BAC <- NA
  optim_df$BAC_sig <- NA
  optim_df$permut <- perm
  
  ###################################################################################################################
  ## Loop through parameter (algorithm x cluster number) combination and calculate stability, BAC for current subsample
  ###################################################################################################################
  
  for(param in 1:nrow(optim_df)){
    
    ## clustering specifications
    num_resample <- 50    # times resampling the data --> recommendation Hennig (2019)
    num_subset <- round(0.5*nrow(data_clustering)) # number of cases for subsetting --> recommendation Hennig (2019)
    num_clust <- optim_df$num_cluster[param]  # number of clusters for clustering
    
    # clustering
    if(optim_df$clust_alg[param]=='kmeans'){
      clust_stab <- clusterboot(data_clustering[,neuropsy_ind], B = num_resample, bootmethod = c('subset', 'noise'), noisetuning = c(0.05, 4), subtuning = num_subset, clustermethod = kmeansCBI, criterion = 'ch', scaling=F, k=num_clust, seed=15555) 
    }
    if(optim_df$clust_alg[param]=='hierach'){
      clust_stab <- clusterboot(data_clustering[,neuropsy_ind], B = num_resample, bootmethod = c('subset', 'noise'), noisetuning = c(0.05, 4), subtuning = num_subset, clustermethod = hclustCBI, cut='number', method='mcquitty', scaling=F, k=num_clust, seed=15555) 
    }
    
    optim_df$stability_subset[param] <- mean(clust_stab$subsetmean)  # building the mean gets rid of the individual cluster stability values --> bad
    optim_df$stability_noise[param] <- mean(clust_stab$noisemean)  # building the mean gets rid of the individual cluster stability values --> bad
    optim_df$cluster_size[param] <- list(table(clust_stab$partition))
    data_clustering$cluster <- as.factor(clust_stab$partition)
    
    ## CLASSIFICATION
    # check whether (1) min cluster size large enough for cluster --> classification can be applied
    if(min(table(data_clustering$cluster)) >= (round(nrow(data_clustering)*0.05))){  # minimum cluster size (5% of cases) needed to calculate classification 
      
      # check whether (2) difference between smallest and largest cluster size too big --> adasyn observation generation
      if(max(table(data_clustering$cluster)) - min(table(data_clustering$cluster)) > (max(table(data_clustering$cluster))*0.50)){   # generate new data points if cluster sizes between smallest and largest cluster differ by 25%
        ## adasyn correction 
        warning('Artificial cases have to be generated as group sizes between smallest and biggest group differ by more than 50%')
        optim_df$adasyn[param] <- 1
        # neuropsy data
        num_k_min <- min(table(data_clustering$cluster)) - 1  # k minimum is one less than cluster size of minimum cluster where cases are generated for
        num_k <- ifelse(num_k_min >= 5, 5,num_k_min) # if minimum number of k > 5 --> k=5 (recommended by default); if it is lower, than minium k has to be chosen otherwise algorithm crashes
        data_clustering_adasyn <- AdasynClassif(cluster ~ ., data_clustering[,c(neuropsy_ind, clinical_ind, 142)], k=num_k, beta=1)
        data_clustering_class <- data_clustering_adasyn[, c(84:101)]     # ATTENTION HARD CODE!
        optim_df$cluster_size_adasyn[param] <- list(table(data_clustering_class$cluster))
      } else {
        optim_df$adasyn[param] <- 0
        data_clustering_class <- data_clustering[, c(clinical_ind, 142)]
        optim_df$cluster_size_adasyn[param] <- list(table(data_clustering_class$cluster))
      }
      
      # svm classification
      svmfit <- svm(cluster ~ ., data = data_clustering_class, kernel = "linear", cost = 1, scale = T)
      conf_mat <- confusionMatrix(data_clustering_class$cluster, predict(svmfit))
      optim_df$BAC[param] <- conf_mat$overall[1]
      optim_df$BAC_sig[param] <- ifelse(conf_mat$overall[6] < 0.05, 1,0)    # 1= significant p value
    
    
    } else if(min(table(data_clustering$cluster)) < (round(nrow(data_clustering)*0.05))){
      message('Mininum cluster size to calculate classification not reached.')
      optim_df$adasyn[param] <- 0
      optim_df$BAC[param] <- NA
      optim_df$BAC_sig[param] <- NA
      optim_df$cluster_size_adasyn[param] <- list(table(data_clustering$cluster))
    }
  }
  
  optim_df_total <- rbind(optim_df_total, optim_df)
}


#######################
## plotting of results
#######################

optim_df_total <- as.data.frame(optim_df_total) 
optim_df_total$clust.alg <- as.factor(paste(optim_df_total$num_cluster, optim_df_total$clust_alg, sep = "."))
optim_df_total <- summaryBy(stability_subset + stability_noise ~ clust.alg + permut, optim_df_total, FUN=mean)
optim_df_total$permut <- as.factor(optim_df_total$permut)

## plot stability values of resampling method 'subset' across all permutations
ggplot(optim_df_total, aes(x= permut, y=stability_subset.mean, group=clust.alg, colour=clust.alg)) + 
  geom_line() +
  geom_point()

## plot stability values of resampling method 'noise' across all permutations
ggplot(optim_df_total, aes(x= permut, y=stability_noise.mean, group=clust.alg, colour=clust.alg)) + 
  geom_line() +
  geom_point()






















