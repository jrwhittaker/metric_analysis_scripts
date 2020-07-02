#!/bin/bash

###################################################
# Project: metric
# File: metric_motion_correct.sh
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

input=(`get_arg_array "-input" "$@"`)
check_arg -input $input
ninps=${#input[@]}

prefix=(`get_arg_array "-prefix" "$@"`)
check_arg -prefix $prefix
npres=${#prefix[@]}

outdir=`dirname ${prefix[0]}`

#### Options
despike_opt=`exist_opt "-despike" "$@"`
separate_opt=`exist_opt "-separate" "$@"`
noclean_opt=`exist_opt "-nocleanup" "$@"`

if [ "${ninps}" -ne "${npres}" ]; then errex "number of prefixes must equal the number of input files"; fi
nreps=`echo "${ninps} - 1" | bc`


### MAIN

cleanlist=()

case "$despike_opt" in

	"TRUE")

	dspikeout=() 
	for rep in `seq 0 ${nreps}`
	do
		exe="${AFNIDIR}/3dDespike -prefix ${prefix[${rep}]}.despike.nii.gz ${input[${rep}]}"
		check_exe ${prefix[${rep}]}.despike.nii.gz "$exe"
		dspikeout=(${dspikeout[@]} ${prefix[${rep}]}.despike.nii.gz)
	done

	;;

	"FALSE")

	dspikeout=("${input[@]}")

	;;

esac

cleanlist=(${cleanlist[@]} ${dspikeout[@]})

case "$separate_opt" in

	"TRUE")

	## first stage
	fpassout=() 
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg_firstpass.nii.gz "
	exe="${exe} ${dspikeout[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg_firstpass.nii.gz "$exe"
	fpassout=(${fpassout[@]} ${prefix[${rep}]}.volreg_firstpass.nii.gz)
	done

	cleanlist=(${cleanlist[@]} ${fpassout[@]})

	spasstargetout=()
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dTstat -median -prefix ${prefix[${rep}]}.volreg_secondpasstarget.nii.gz ${prefix[${rep}]}.volreg_firstpass.nii.gz"
	check_exe ${prefix[${rep}]}.volreg_secondpasstarget.nii.gz "${exe}"
	spasstargetout=(${spasstargetout[@]} ${prefix[${rep}]}.volreg_secondpasstarget.nii.gz)
	cleanlist=(${cleanlist[@]} ${prefix[${rep}]}.volreg_secondpasstarget.nii.gz)
	done

	## second stage
	spassout=()
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg_secondpass.nii.gz"
	exe="${exe} -base ${prefix[${rep}]}.volreg_secondpasstarget.nii.gz"
	exe="${exe} ${input[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg_secondpass.nii.gz "$exe"
	spassout=(${spassout[@]} ${prefix[${rep}]}.volreg_secondpass.nii.gz)
	done

	cleanlist=(${cleanlist[@]} ${spassout[@]})

	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dTstat -median -prefix ${prefix[${rep}]}.volreg_finaltarget.nii.gz ${prefix[${rep}]}.volreg_secondpass.nii.gz"
	check_exe ${prefix[${rep}]}.volreg_finaltarget.nii.gz "${exe}"
	done	

	## final stage
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg.nii.gz"
	exe="${exe} -1Dfile ${prefix[${rep}]}.volreg.1D"
	exe="${exe} -base ${prefix[${rep}]}.volreg_finaltarget.nii.gz"
	exe="${exe} ${input[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg.nii.gz "$exe"

	exe="${AFNIDIR}/1d_tool.py -infile ${prefix[${rep}]}.volreg.1D -set_nruns 1 -demean -write ${prefix[${rep}]}.motion_demean.1D"
	check_exe ${prefix[${rep}]}.motion_demean.1D "${exe}"
	done

	;;

	"FALSE")

	## first stage
	fpassout=() 
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg_firstpass.nii.gz "
	exe="${exe} -base ${dspikeout[0]}[0] ${dspikeout[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg_firstpass.nii.gz "$exe"
	fpassout=(${fpassout[@]} ${prefix[${rep}]}.volreg_firstpass.nii.gz)
	done

	cleanlist=(${cleanlist[@]} ${fpassout[@]})

	if [ "${nreps}" -gt 0 ]
	then
	exe="${AFNIDIR}/3dTcat -prefix ${outdir}/killme.volreg_firstpass.nii.gz ${fpassout[@]}"
	check_exe ${outdir}/killme.volreg_firstpass.nii.gz "$exe"
	else
	mv ${fpassout[@]} ${outdir}/killme.volreg_firstpass.nii.gz
	fi

	cleanlist=(${cleanlist[@]} ${outdir}/killme.volreg_firstpass.nii.gz)

	exe="${AFNIDIR}/3dTstat -median -prefix ${outdir}/killme.volreg_secondpasstarget.nii.gz ${outdir}/killme.volreg_firstpass.nii.gz"
	check_exe ${outdir}/killme.volreg_secondpasstarget.nii.gz "$exe"

	cleanlist=(${cleanlist[@]} ${outdir}/killme.volreg_secondpasstarget.nii.gz)

	## second stage
	spassout=()
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg_secondpass.nii.gz"
	exe="${exe} -base ${outdir}/killme.volreg_secondpasstarget.nii.gz"
	exe="${exe} ${input[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg_secondpass.nii.gz "$exe"
	spassout=(${spassout[@]} ${prefix[${rep}]}.volreg_secondpass.nii.gz)
	done

	cleanlist=(${cleanlist[@]} ${spassout[@]})

	if [ "${nreps}" -gt 0 ]
	then
	exe="${AFNIDIR}/3dTcat -prefix ${outdir}/killme.volreg_secondpass.nii.gz ${spassout[@]}"
	check_exe ${outdir}/killme.volreg_secondpass.nii.gz "$exe"
	else
	mv ${spassout[@]} ${outdir}/killme.volreg_secondpass.nii.gz
	fi

	cleanlist=(${cleanlist[@]} ${outdir}/killme.volreg_secondpass.nii.gz)

	exe="${AFNIDIR}/3dTstat -median -prefix ${outdir}/volreg_finaltarget.nii.gz ${outdir}/killme.volreg_secondpass.nii.gz"
	check_exe ${outdir}/volreg_finaltarget.nii.gz "$exe"

	## final stage
	for rep in `seq 0 ${nreps}`
	do
	exe="${AFNIDIR}/3dvolreg -prefix ${prefix[${rep}]}.volreg.nii.gz"
	exe="${exe} -1Dfile ${prefix[${rep}]}.volreg.1D"
	exe="${exe} -base ${outdir}/volreg_finaltarget.nii.gz"
	exe="${exe} ${input[${rep}]}"
	check_exe ${prefix[${rep}]}.volreg.nii.gz "$exe"

	exe="${AFNIDIR}/1d_tool.py -infile ${prefix[${rep}]}.volreg.1D -set_nruns 1 -demean -write ${prefix[${rep}]}.motion_demean.1D"
	check_exe ${prefix[${rep}]}.motion_demean.1D "${exe}"
	done

	;;
esac

if [ $noclean_opt == "FALSE" ]
then
	for f in ${cleanlist[@]}; do cleanup $f; done
fi
















