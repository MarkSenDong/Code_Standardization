#!/bin/bash

# This is a bash script to extract MRI measures from ROI data in FSL preprocessed data
# Make sure you have:
# 1. Run preprocessing pipeline in FSL beforehand in the subjects directory
# 2. Binarised and named all masks appropropriately (ROI_01.nii, ROI_02.nii etc.) in the ROIs directory

# Put here the path to your data directory, where the preprocessed feat-directories and ROIs are located:
workingDir=/Users/data 

# For every ROI in ROIs directory...
for mask in `ls -1d $workingDir/ROIs/ROI_*.nii`
do
mask_name=$(basename ${mask} .nii)

# For every subject in subjects directory...
for subject in `ls -1d $workingDir/subjects/*.feat`
do
subject_name=$(basename ${subject} .nii.gz)

mkdir -p ${subject}/ROI

# Step 1a
echo Registering ${mask_name} to ${subject_name}
flirt -in ${mask} -ref ${subject}/example_func.nii* -applyxfm -init ${subject}/reg/standard2example_func.mat -out ${subject}/ROI/${mask_name}_registered

# Step 1b
echo Resizing and binarizing registered ${mask_name} ROI for Featquery accuracy
fslmaths ${subject}/ROI/${mask_name}_registered.nii* -thr 0.2 -bin ${subject}/ROI/${mask_name}_registered

#Step 2
echo Featquery 1 - extract mean percent BOLD signal change and total number of voxels from entire ${mask} 
featquery 1 ${subject} 1 stats/cope1 COPE1_${mask_name} -p ${subject}/ROI/${mask_name}_registered.nii*

done
done
