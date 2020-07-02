#!/bin/bash

###################################################
# Project: metric
# File: metric_clean_filter.sh
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

### Optional arguments

if [ `exist_opt "-regress" "$@"` == "TRUE" ]
then
	regress=(`get_arg_array "-regress" "$@"`)
	check_arg -regress $regress
	nregs=${#regress[@]}
fi

if [ `exist_opt "-voxel_regress" "$@"` == "TRUE" ]
then
	voxel_regress=(`get_arg_array "-voxel_regress" "$@"`)
	check_arg -voxel_regress $voxel_regress
fi

if [ `exist_opt "-bandpass" "$@"` == "TRUE" ]
then
	bandpass=(`get_arg_array "-bandpass" "$@"`)
	check_arg -bandpass $bandpass
fi

if [ `exist_opt "-censor" "$@"` == "TRUE" ]
then
	censor=`get_arg "-censor" "$@"`
	check_arg -censor $censor
fi

if [ `exist_opt "-mask" "$@$"` == "TRUE" ]
then
	mask=`get_arg "-mask" "$@"`
	check_arg -mask $mask
fi	

#### Options
noclean_opt=`exist_opt "-nocleanup" "$@"`


### MAIN

if [ -v bandpass ]
then
	if [ ${#bandpass[@]} -gt 2 ]; then errex "-bandpass option must contain exactly two arguments!"; fi
	TR=`${AFNIDIR}/3dinfo -tr ${input}`
	printf "\n\nUsing TR of %6.3f for\n\n" "${TR}"
fi

exe="${AFNIDIR}/3dTproject -input ${input}"
for ort in ${regress[@]}
do
	exe="${exe} -ort ${ort}"
done
for dsort in ${voxel_regress[@]}
do
	exe="${exe} -dsort ${dsort}"
done
if [ -v censor ]; then exe="${exe} -censor ${censor} -cenmode 'NTRP'"; fi
if [ -v mask ]; then exe="${exe} -mask ${mask}"; fi
if [ -v bandpass ]; then exe="${exe} -bandpass ${bandpass[0]} ${bandpass[1]} -TR ${TR}"; fi
exe="${exe} -prefix ${prefix}.clean.nii.gz"

check_exe ${prefix}.clean.nii.gz "${exe}"














