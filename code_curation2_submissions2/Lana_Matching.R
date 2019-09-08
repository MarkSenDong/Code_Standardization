# R-script to match data of PRONIA participants (clinical data & mri data) based on their PSN
# Data is converted from wide to long format and a plot for illustration is produced in the end
#
# --- INPUTS:
# ----------- data_file: PRONIA portal output of clinical data (csv format)
# ----------- aux_file: PRONIA portal output of aux variables (csv format)
# ----------- mri_file: PRONIA portal output of mri data (csv format)
# --- OUTPUTS:
# ----------- processed_data_long: data in long format (currently not saved to disk)
#
# Adapt data_file, aux_file and mri_file to your local directories to run
# Attention: Requires the following R-libraries to be installed: readr, reshape2, ggplot2, dplyr
# Created by: Linda Betz
# Modified by: Lana Kambeitz-Ilankovic
# Date: 11.06.2018

# load libraries
library(readr)
library(reshape2)
library(ggplot2)
library(dplyr) # load in LAST to avoid naming conflicts

# read data in
data_file <- read_csv("DataQuery_LKI_finalpaperRS_2018_Clinical_Data_all_29-Aug-2018.csv")
aux_file <- read_csv("DataQuery_LKI_finalpaperRS_2018_Clinical_aux_29-Aug-2018.csv")
mri_file <- read_csv("DataQuery_LKI_finalpaperRS_2018_MRI_Data_all_29-Aug-2018.csv")

# processing of data
processed_data <- data_file %>% 
  filter(Studygroup_T0 == "CHR"|Studygroup_T0 == "HC") %>%
  left_join(mri_file, by = "PSN") %>%
  filter(Inclusion_fullfilled_rsMRI_T0 == 1) %>%
  select(., matches("PSN|Studygroup_T0|BOGEN_ID_T0|GAF_DI")) %>%
  mutate(GAF_DI_PastMonth_T1 = if_else(is.na(GAF_DI_PastMonth_T1)==TRUE, GAF_DI_PastMonth_IV15, GAF_DI_PastMonth_T1)) %>%
  mutate(GAF_DI_PastMonth_T1 = if_else(is.na(GAF_DI_PastMonth_T1)==TRUE & is.na(GAF_DI_PastMonth_IV15)==TRUE, GAF_DI_PastMonth_IV12, GAF_DI_PastMonth_T1)) %>%
  mutate(GAF_DI_PastMonth_T1 = if_else(is.na(GAF_DI_PastMonth_T1)==TRUE & is.na(GAF_DI_PastMonth_IV15)==TRUE & is.na(GAF_DI_PastMonth_IV12)==TRUE, GAF_DI_PastMonth_IV6, GAF_DI_PastMonth_T1)) %>%
  transmute(PSN,
            BOGEN_ID_T0.x,
            Studygroup = Studygroup_T0.x,
            GAF_T0 = GAF_DI_PastMonth_Screening.x,
            GAF_T1 = GAF_DI_PastMonth_T1)

# conversion from wide to long format
processed_data_long <- melt(processed_data, 
                            #id.vars = c("PSN", "BOGEN_ID_T0.x", "Studygroup"), # this is not necessary
                            measure.vars = c("GAF_T0",
                                             "GAF_T1"))
# plot creation
processed_data_long %>% 
  na.omit %>% # leave out cases that have any NAs
  group_by(Studygroup, variable) %>% 
  summarize(GAF = mean(value),
            total_n = n(),
            SEM = GAF/sqrt(total_n)) %>% # get SEM for error bars
ggplot(., aes(x = variable, y = GAF, group=Studygroup, fill=Studygroup)) +
  geom_errorbar(aes(ymin=GAF-SEM, ymax=GAF+SEM), width=.2,
                position=position_dodge(.9)) + # add error bars before bars - it'll look nicer
  geom_bar(position = "dodge", stat = "identity") + 
  theme_classic() + # clean look of the graph
  xlab("Variable") # rename x-axis

# t-test illustration
t.test(GAF_T1 ~ Studygroup, data = processed_data)
