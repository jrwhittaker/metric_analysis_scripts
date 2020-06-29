#!/bin/bash

###################################################
# Project: metric
# File: metric_antsprocess_t1.sh
# Author: Joe Whittaker (whittakerj3@cardiff.ac.uk)
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


#### MAIN

# Robust FOV

check_exe ${prefix}.std.nii.gz "${USRFSLDIR}/fslreorient2std ${input} ${prefix}.std"
check_exe ${prefix}.robustfov.nii.gz "${USRFSLDIR}/robustfov -i ${prefix}.std -r ${prefix}.robustfov -m ${prefix}.robustfov"

# ANTS cortical thickness script
exe="${ANTSCRIPTDIR}/antsCorticalThickness.sh -d 3 -a ${prefix}.robustfov.nii.gz"
exe="${exe} -e ${OASISTPLDIR}/T_template0.nii.gz"
exe="${exe} -m ${OASISTPLDIR}/T_template0_BrainCerebellumProbabilityMask.nii.gz"
exe="${exe} -p ${OASISTPLDIR}/Priors2/priors%d.nii.gz"
exe="${exe} -o ${prefix}."

check_exe ${prefix}.CorticalThickness.nii.gz "${exe}"

# Segmentation masks

BE_SEGMENTATION=${prefix}.BrainSegmentation.nii.gz
BE_SEGMENTATION_PAD=${prefix}.BrainSegmentationPad.nii.gz
padvoxels=10

check_exe ${BE_SEGMENTATION_PAD} "${ANTSDIR}/ImageMath 3 ${BE_SEGMENTATION_PAD} PadImage ${BE_SEGMENTATION} $padvoxels"

check_exe ${prefix}.wm.nii.gz "${ANTSDIR}/ThresholdImage 3 ${BE_SEGMENTATION} ${prefix}.wm.nii.gz 3 3 1 0"
check_exe ${prefix}.gm.nii.gz "${ANTSDIR}/ThresholdImage 3 ${BE_SEGMENTATION} ${prefix}.gm.nii.gz 2 2 1 0"
check_exe ${prefix}.csf.nii.gz "${ANTSDIR}/ThresholdImage 3 ${BE_SEGMENTATION} ${prefix}.csf.nii.gz 1 1 1 0"

${ANTSDIR}/ImageMath 3 ${prefix}.wm.nii.gz GetLargestComponent ${prefix}.wm.nii.gz
${ANTSDIR}/ImageMath 3 ${prefix}.gm.nii.gz GetLargestComponent ${prefix}.gm.nii.gz


# Skull stripped

exe="${AFNIDIR}/3dcalc -a ${prefix}.BrainSegmentation0N4.nii.gz -b ${prefix}.BrainExtractionMask.nii.gz"
exe="${exe} -expr "a*b" -prefix ${prefix}.brain.nii.gz"
check_exe ${prefix}.brain.nii.gz "${exe}"

# MNI normalisation

fixed=${STDTPLDIR}/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz
moving=${prefix}.brain.nii.gz

ncores=`lscpu | grep Core\(s\) | awk '{print $4}'`

exe="${ANTSDIR}/antsRegistrationSyN.sh -d 3 -f ${fixed} -m ${moving} -n ${ncores} -o ${prefix}.mni."
check_exe ${prefix}.mni.Warped.nii.gz "${exe}"


if [ $noclean_opt == "FALSE" ]
then

	cleanlist=()
	cleanlist=(${cleanlist[@]} ${prefix}.ACTStage*Complete.txt ${prefix}.BrainSegmentationPosteriors*.nii.gz)
	for f in ${cleanlist[@]}; do cleanup $f; done

fi








