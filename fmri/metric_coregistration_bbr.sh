#!/bin/bash

###################################################
# Project: metric
# File: metric_coregistration_bbr.sh
# Author: Joe Whittaker (whittakerj3@cardiff.ac.uk)
# =================================================
#
# 
#
###################################################

#source config and miscfunc files
source metric_config.sh
source metric_miscfunc.sh

# Usage function
function usage()
{
printf "\nUSAGE: %s
Arguments:
\n" "`basename $0`"
}

### Argument parsing

if [ $# -le 1 ]; then usage; exit 1; fi

### Compulsory arguments

epi=`get_arg "-epi" "$@"`
check_arg -epi $epi

t1=`get_arg "-t1" "$@"`
check_arg -t1 $t1

t1_brain=`get_arg "-t1_brain" "$@"`
check_arg -t1_brain $t1_brain

prefix=`get_arg "-prefix" "$@"`
check_arg -prefix $prefix

#### Options
noclean_opt=`exist_opt "-nocleanup" "$@"`
itk_opt=`exist_opt "-itk" "$@"`

## 1
# Run FSL epi_reg script
check_exe ${prefix}.nii.gz "${USRFSLDIR}/epi_reg --noclean --epi=${epi} --t1=${t1} --t1brain=${t1_brain} --out=${prefix} -v"

## 2
# Convert transform matrix to ITK format
if [ $itk_opt == "TRUE" ]
then
	check_exe ${prefix}_itk.mat "${CONVDIR}/c3d_affine_tool -ref ${t1_brain} -src ${epi} ${prefix}.mat -fsl2ras -oitk ${prefix}_itk.mat"
fi













