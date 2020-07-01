#!/bin/bash

###################################################
# Project: metric
# File: metric_boldref.sh
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

input=`get_arg "-input" "$@"`
check_arg -input $input

prefix=`get_arg "-prefix" "$@"`
check_arg -prefix $prefix

#### Options
noclean_opt=`exist_opt "-nocleanup" "$@"`

### Constants
betfrac=0.4
autoclfrac=0.4

cleanlist=()

check_exe ${prefix}.truncate.nii.gz "${ANTSDIR}/ImageMath 3 ${prefix}.truncate.nii.gz TruncateImageIntensity ${input} 0.01 0.999 256"

## 1
# Calculate tentative mask by registering to fMRIPrep EPI boldref template

fixed=${prefix}.truncate.nii.gz
moving=${STDTPLDIR}/tpl-MNI152NLin2009cAsym_res-02_desc-fMRIPrep_boldref.nii.gz

nm=${prefix}.tpl2bold

exe="${ANTSDIR}/antsRegistration -d 3 -r [ $fixed, $moving ,1 ]"
exe="${exe} -m mattes[ $fixed, $moving, 1, 32, regular, 0.1 ]"
exe="${exe} -t translation[ 0.1 ]"
exe="${exe} -c [ 10000x0x0,1.e-8,20 ]"
exe="${exe} -s 4x2x1vox"
exe="${exe} -f 6x4x2 -l 1"
exe="${exe} -m mattes[  $fixed, $moving , 1 , 32, regular, 0.1 ]"
exe="${exe} -t rigid[ 0.1 ]"
exe="${exe} -c [ 10000x0x0,1.e-8,20 ]"
exe="${exe} -s 4x2x1vox"
exe="${exe} -f 3x2x1 -l 1"
exe="${exe} -m mattes[  $fixed, $moving , 1 , 32, regular, 0.1 ]"
exe="${exe} -t affine[ 0.1 ]"
exe="${exe} -c [ 10000x0x0,1.e-8,20 ]"
exe="${exe} -s 4x2x1vox"
exe="${exe} -f 3x2x1 -l 1"
exe="${exe} -m mattes[  $fixed, $moving , 0.5 , 32 ]"
exe="${exe} -m cc[  $fixed, $moving , 0.5 , 4 ]"
exe="${exe} -t SyN[ .20, 3, 0 ]"
exe="${exe} -c [ "100x0x0,0,5" ]"
exe="${exe} -s 1x0.5x0vox"
exe="${exe} -f 4x2x1 -l 1 -u 1 -z 1"
exe="${exe} -o [ ${nm}.,${nm}.diff.nii.gz,${nm}.inv.nii.gz] --verbose"
check_exe ${nm}.inv.nii.gz "${exe}"

moving=${STDTPLDIR}/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
exe1="${ANTSDIR}/antsApplyTransforms -d 3 -i $moving -r $fixed -n NearestNeighbor"
exe1="${exe1} -t ${nm}.1Warp.nii.gz -t ${nm}.0GenericAffine.mat -o ${nm}.Warped.nii.gz"

## 2
# Binary dilation of tentative mask
exe2="${ANTSDIR}/ImageMath 3 ${nm}.Warped.nii.gz MD ${nm}.Warped.nii.gz 3"
check_exe ${nm}.Warped.nii.gz "${exe1}" "${exe2}"

cleanlist=(${cleanlist[@]} ${prefix}.truncate.nii.gz `ls ${nm}*`)

## 3
# Bias field correction of input using tentative mask instead of internal thresholding
check_exe ${prefix}.N4corrected.nii.gz "${ANTSDIR}/N4BiasFieldCorrection -d 3 -i ${input} -x ${nm}.Warped.nii.gz -o ${prefix}.N4corrected.nii.gz"

## 4
# Loose mask using FSL bet
exe1="${USRFSLDIR}/bet ${prefix}.N4corrected ${prefix}.N4corrected_bet -m -n -f ${betfrac}"
exe2="${ANTSDIR}/ImageMath 3 ${prefix}.N4corrected_bet_mask.nii.gz MD ${prefix}.N4corrected_bet_mask.nii.gz 1"
check_exe ${prefix}.N4corrected_bet_mask.nii.gz "${exe1}" "${exe2}"

## 5
# Mask the bias corrected image with latest mask and then standardise T2* contrast distribution with AFNI
exe="${AFNIDIR}/3dcalc -a ${prefix}.N4corrected.nii.gz -b ${prefix}.N4corrected_bet_mask.nii.gz -expr "a*b" -prefix ${prefix}.N4corrected_masked.nii.gz"
check_exe ${prefix}.N4corrected_masked.nii.gz "${exe}"
exe="${AFNIDIR}/3dUnifize -EPI -prefix ${prefix}.N4corrected_unifized.nii.gz -input ${prefix}.N4corrected_masked.nii.gz"
check_exe ${prefix}.N4corrected_unifized.nii.gz "${exe}"

## 6
# Make new mask with AFNI after step 5's contrast enhancement
check_exe ${prefix}.automask.nii.gz "${AFNIDIR}/3dAutomask -clfrac ${autoclfrac} -prefix ${prefix}.automask.nii.gz ${prefix}.N4corrected_unifized.nii.gz"

## 7
# Final mask as intersection of steps 4 and 6 masks
check_exe ${prefix}.final_mask.nii.gz "${AFNIDIR}/3dcalc -a ${prefix}.N4corrected_bet_mask.nii.gz -b ${prefix}.automask.nii.gz -expr "a*b" -prefix ${prefix}.final_mask.nii.gz"

## 8
# Apply final mask to unifized image create boldref image
check_exe ${prefix}.boldref.nii.gz "${AFNIDIR}/3dcalc -a ${prefix}.final_mask.nii.gz -b ${prefix}.N4corrected_unifized.nii.gz -expr "a*b" -prefix ${prefix}.boldref.nii.gz"

if [ $noclean_opt == "FALSE" ]
then
	cleanlist=(${cleanlist[@]} ${prefix}.N4corrected.nii.gz ${prefix}.N4corrected_bet_mask.nii.gz ${prefix}.N4corrected_masked.nii.gz)
	cleanlist=(${cleanlist[@]} ${prefix}.N4corrected_unifized.nii.gz ${prefix}.automask.nii.gz)
	for f in ${cleanlist[@]}; do cleanup $f; done
fi












