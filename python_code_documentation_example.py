#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Jun  7 18:28:06 2019

@author: mdong

This is an examplary python code to show the proper documentation and coding styles when writing python codes.

The original purpose of the script is the following:
    This script intends to extract .img & .hdr files from .gz, 
    convert them into .nii files and then rezip again into .gz
"""

# Libraries needed for the script
from os import listdir
import nibabel as nb
import os


"""
User defined Variables: 
    The variables which need to be changed by future users in order to use the script.
    They should alway be declaired at the beginning of the script, with proper explainations.
"""
# Set the original folder of the files
original_folder = '//volume//data//MUC//MRI//06-June-2019//'
# Set the save folder for storing the converted .nii files
save_folder = '//volume//data//MUC//MRI//06-June-2019_nii//'


# Defined Functions
def unzip_gz(files,original_directory,extract_directory):
    # docstring: it is the string section in a function which explains the purpose of the function.
    # it should describe the purpose, the input arguments, the output returns
    """
    This function unzips .gz files with the same file names.
    Args:
        files: A list of strings, containing files names of the files to be unzipped
        original_directory: A string, containing the full path of the files' original directory 
        extract_directory: A string, containing the full path of the directory where the extracted files will be saved 
    Returns:
        None
    """
    for f in files:
        fname = original_directory + f
        unzip_name = extract_directory + f.replace('.gz','')
        os.system('zcat %s > %s' %(fname,unzip_name))

def convert_nii(images,directory):
    # docstring
    """
    This function converts mri images with .img or .hdr format into .nii format at the same location with the same file names.
    Args:
        images: A list of strings, containing images names of the images to be converted
        directory: A string, containing the full path of the images' directory 
    Returns:
        None
    """
    for im in images:
        fname = directory + im
        f_format = im.split('.')[-1]
        
        if f_format == 'img' or f_format == 'hdr':    
            # Convert file to .nii
            img = nb.load(fname)
            save_name = directory + im.replace('.%s'%f_format,'_%s.nii'%f_format)
            nb.save(img, save_name)
            # Remove original file
            os.system('rm %s' %fname)

def zip_gz(files,directory):
    # docstring
    """
    This function zips the input files into .gz files at the same location with the same file names.
    Args:
        files: A list of strings, containing files names of the files to be zipped
        directory: A string, containing the full path of the files' directory 
    Returns:
        None
    """
    for f in files:
        fname = directory + f
        os.system('gzip %s' %fname)


# To display the docstring of a function
help(unzip_gz)

"""Main script which runs the above functions"""
# Step 1. unzip
# Getting all the file names from the folder
files = listdir(original_folder)
unzip_gz(files,original_folder,save_folder)

# Step 2. convert .img and .hdr to nii 
# Getting all the file names from the folder
images = listdir(save_folder)
convert_nii(images,save_folder)

# Step3. zip
# Getting only the files with '.nii' file ending
images = [x for x in listdir(save_folder) if '.nii' in x]
zip_gz(images,save_folder)
