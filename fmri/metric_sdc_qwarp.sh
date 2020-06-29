#!/bin/bash

###################################################
# Project: metric
# File: metric_sdc_qwarp.sh
# Author: Joe Whittaker (whittakerj3@cardiff.ac.uk)
# =================================================
#
# 
#
###################################################

#source config and miscfunc files
source ww_config.sh
source ww_miscfunc.sh

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

ap=`get_arg "-ap" "$@"`
check_arg -ap $ap

pa=`get_arg "-pa" "$@"`
check_arg -pa $pa

prefix=`get_arg "-prefix" "$@"`
check_arg -prefix $prefix

#### Options
noclean_opt=`exist_opt "-nocleanup" "$@"`

## 1
# Register PA and AP images

fixed=$ap
moving=$pa
nm=${prefix}.pa2ap

exe="${ANTSDIR}/antsRegistration -d 3 -r [ $fixed, $moving ,1 ]"
exe="${exe} -m mattes[ $fixed, $moving, 1, 32, regular, 0.1 ]"
exe="${exe} -t translation[ 0.1 ]"
exe="${exe} -c [ 10000x100x10,1.e-8,20 ]"
exe="${exe} -s 4x2x1vox"
exe="${exe} -f 6x4x2 -l 1"
exe="${exe} -m mattes[  $fixed, $moving , 1 , 32, regular, 0.1 ]"
exe="${exe} -t rigid[ 0.1 ]"
exe="${exe} -c [ 10000x100x10,1.e-8,20 ]"
exe="${exe} -s 4x2x1vox"
exe="${exe} -f 3x2x1 -l 1"
exe="${exe} -o [ ${nm}. ]"
check_exe ${nm}.0GenericAffine.mat "${exe}"

check_exe ${nm}.Warped.nii.gz "${ANTSDIR}/antsApplyTransforms -d 3 -i $moving -r $fixed -n Linear -t ${nm}.0GenericAffine.mat -o ${nm}.Warped.nii.gz"

## 2
# Estimate susceptibility distortion warp field 

exe1="${AFNIDIR}/3dQwarp -source $ap -base ${nm}.Warped.nii.gz -plusminus -noXdis -noZdis -prefix ${prefix}"
exe2="${AFNIDIR}/3dAFNItoNIFTI -prefix ${prefix}.sdc.nii.gz ${prefix}_PLUS+orig"
exe3="${AFNIDIR}/3dAFNItoNIFTI -prefix ${prefix}.sdc_warp.nii.gz ${prefix}_PLUS_WARP+orig"
check_exe ${prefix}.sdc_warp.nii.gz "${exe1}" "${exe2}" "${exe3}"


if [ $noclean_opt == "FALSE" ]
then

	cleanlist=(${prefix}_PLUS* ${prefix}_MINUS* ${nm}*)
	for f in ${cleanlist[@]}; do cleanup $f; done

fi














