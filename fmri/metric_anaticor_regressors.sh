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

csf=`get_arg "-csf" "$@"`
check_arg -csf $csf

wm=`get_arg "-wm" "$@"`
check_arg -wm $wm

### Optional arguments

if [ `exist_opt "-ref" "$@"` == "TRUE" ]
then
	ref=`get_arg "-ref" "$@"`
	check_arg -ref $ref
fi

if [ `exist_opt "-transform" "$@"` == "TRUE" ]
then
	transform=(`get_arg_array "-transform" "$@"`)
	check_arg -transform $transform
fi

if [ `exist_opt "-thr" "$@"` == "TRUE" ]
then
	thr=`get_arg "-thr" "$@"`
	check_arg -thr $thr
fi

### Options
localwm_opt=`exist_opt "-localwm" "$@"`
#erode=`exist_opt "-erode" "$@"`
tplmask_opt=`exist_opt "-tplmask" "$@"`
noclean_opt=`exist_opt "-nocleanup" "$@"`

### Constants
local_nbhd="SPHERE(20)"
local_gridred=1.5
tplcsf=${STDTPLDIR}/tpl-MNI152NLin2009cAsym_res-02_label-CSF_probseg.nii.gz
tplwm=${STDTPLDIR}/tpl-MNI152NLin2009cAsym_res-02_label-WM_probseg.nii.gz

### MAIN

if [ "${ninps}" -ne "${npres}" ]; then errex "number of prefixes must equal the number of input files"; fi
nreps=`echo "${ninps} - 1" | bc`

cleanlist=()

if [ -v ref ]
then
	if [ ! -v transform ]; then errex "-ref must be supplied with -transform"; fi
fi
if [ -v transform ]
then 
	if [ ! -v ref ];then  errex "-transform must be supplied with -ref"; fi
fi

if [ -v ref ]
then
	csfout=`dirname ${prefix}`/`basename ${csf%.*.*}`
	exe="metric_normalise.sh -input ${csf} -prefix ${csfout} -ref ${ref} -transform `echo ${transform[@]}`"
	check_exe ${csfout}.mni.nii.gz "${exe}"
	csf=${csfout}.mni.nii.gz
	wmout=`dirname ${prefix}`/`basename ${wm%.*.*}`
	check_exe ${wmout}.mni.nii.gz "metric_normalise.sh -input ${wm} -prefix ${wmout} -ref ${ref} -transform `echo ${transform[@]}`"
	wm=${wmout}.mni.nii.gz
	cleanlist=(${cleanlist[@]} ${csf} ${wm})
fi

if [ -v thr ]
then
	csfout=`dirname ${prefix}`/`basename ${csf%.*.*}`.thr.nii.gz
	check_exe ${csfout} "${AFNIDIR}/3dcalc -a ${csf} -expr "step\(a-${thr}\)" -prefix ${csfout}"
	csf=${csfout}
	wmout=`dirname ${prefix}`/`basename ${wm%.*.*}`.thr.nii.gz
	check_exe ${wmout} "${AFNIDIR}/3dcalc -a ${wm} -expr "step\(a-${thr}\)" -prefix ${wmout}"
	wm=${wmout}
	cleanlist=(${cleanlist[@]} ${csf} ${wm})
fi


if [ "${tplmask_opt}" == "TRUE" ]
then
	csfout=`dirname ${prefix}`/`basename ${csf%.*.*}`.tpl.nii.gz
	exe="${AFNIDIR}/3dcalc -a ${tplcsf} -b ${csf} -expr "step\(a-0.95\)*b" -prefix ${csfout}"
	check_exe ${csfout} "${exe}"
	csf=${csfout}

	wmout=`dirname ${prefix}`/`basename ${wm%.*.*}`.tpl.nii.gz
	exe="${AFNIDIR}/3dcalc -a ${tplwm} -b ${wm} -expr "step\(a-0.95\)*b" -prefix ${wmout}"
	check_exe ${wmout} "${exe}"
	wm=${wmout}
	cleanlist=(${cleanlist[@]} ${csf} ${wm})
fi

csfmask=${prefix}.csf_mask.nii.gz
check_exe ${csfmask} "cp ${csf} ${csfmask}"
wmmask=${prefix}.wm_mask.nii.gz
exe1="${ANTSDIR}/ImageMath 3 ${wmmask} GetLargestComponent ${wm}"
exe2="${USRFSLDIR}/fslmaths ${wmmask} -ero ${wmmask}"
check_exe ${wmmask} "${exe1}" "${exe2}"


for rep in `seq 0 ${nreps}`
do
	check_exe_out ${prefix[${rep}]}_csf.1D "${AFNIDIR}/3dmaskave -quiet -mask ${csfmask} ${input[${rep}]}" ${prefix[${rep}]}_csf.1D
	check_exe_out ${prefix[${rep}]}_wm.1D "${AFNIDIR}/3dmaskave -quiet -mask ${wmmask} ${input[${rep}]}" ${prefix[${rep}]}_wm.1D

	if [ "${localwm_opt}" == "TRUE" ]
	then
		# N.B It's a good idea to downsample so that this doesn't take forever, but 
		# there is some weird bug or strange behavoiur in 3dLocalstat whereby the -reduce_restore_grid option doesn't work for me ¯\_(ツ)_/¯
		# hence why 3dresample is used 
		
		exe1="${AFNIDIR}/3dLocalstat -stat mean -nbhd ${local_nbhd} -prefix ${prefix[${rep}]}.local_wm_killme.nii.gz" 
		exe1="${exe1} -mask ${wmmask} -use_nonmask -reduce_grid ${local_gridred} ${input[${rep}]}"
		exe2="${AFNIDIR}/3dresample -master ${input[${rep}]} -prefix ${prefix[${rep}]}.local_wm.nii.gz"
		exe2="${exe2} -inset ${prefix[${rep}]}.local_wm_killme.nii.gz"
		exe3="rm ${prefix[${rep}]}.local_wm_killme.nii.gz"	
		check_exe ${prefix[${rep}]}.local_wm.nii.gz "${exe1}" "${exe2}" "${exe3}"
	fi
done
		
if [ $noclean_opt == "FALSE" ]
then
	for f in ${cleanlist[@]}; do cleanup $f; done
fi









