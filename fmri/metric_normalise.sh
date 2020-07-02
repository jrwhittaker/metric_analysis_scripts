#!/bin/bash

###################################################
# Project: metric
# File: metric_normalise.sh
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

input=(`get_arg_array "-input" "$@"`)
check_arg -input $input
ninps=${#input[@]}

prefix=(`get_arg_array "-prefix" "$@"`)
check_arg -prefix $prefix
npres=${#prefix[@]}

ref=`get_arg "-ref" "$@"`
check_arg -ref $ref

transform=(`get_arg_array "-transform" "$@"`)
check_arg -transform $transform

### Optional arguments
if [ `exist_opt "-sdc" "$@"` == "TRUE" ]
then
	sdc=`get_arg "-sdc" "$@"`
	check_arg -sdc $sdc
fi

#### Options
ts_opt=`exist_opt "-ts" "$@"`
noclean_opt=`exist_opt "-nocleanup" "$@"`

if [ "${ninps}" -ne "${npres}" ]; then errex "number of prefixes must equal the number of input files"; fi
nreps=`echo "${ninps} - 1" | bc`

### Constants
input_type=0
if [ $ts_opt == "TRUE" ]; then input_type=3; fi


### MAIN

cleanlist=()

if [ -v sdc ]
then
	for rep in `seq 0 ${nreps}`
	do
		check_exe ${prefix[${rep}]}.sdc.nii.gz "${AFNIDIR}/3dNwarpApply -prefix ${prefix[${rep}]}.sdc.nii.gz -nwarp ${sdc} -source ${input[${rep}]}"
		input[${rep}]=${prefix[${rep}]}.sdc.nii.gz
		cleanlist=(${cleanlist[@]} ${prefix[${rep}]}.sdc.nii.gz)
	done
fi

for rep in `seq 0 ${nreps}`
do
	exe="${ANTSDIR}/antsApplyTransforms -d 3 -e ${input_type} -i ${input[${rep}]}"
	exe="${exe} -r ${ref} -n Linear"
	for t in "${transform[@]}"
	do
		exe="${exe} -t ${t}"
	done
	exe="${exe} -o ${prefix[${rep}]}.mni.nii.gz"
	check_exe ${prefix[${rep}]}.mni.nii.gz "${exe}"
done

if [ $noclean_opt == "FALSE" ]
then
	for f in ${cleanlist[@]}; do cleanup $f; done
fi








