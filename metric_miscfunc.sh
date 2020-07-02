#!/bin/bash

###################################################
# Project: metric
# File: metric_miscfunc.sh
# Author: Joe Whittaker (whittakerj3@cardiff.ac.uk)
###################################################


################## Functions ####################

function errex()
{
printf "*** ERROR: ***\n %s \n" "$1" >&2
exit 1
}

function get_arg_array()
{

pattern=$1
shift

argc=$#
argv=("$@")
nopt=0

while (( $nopt < $argc ))
do
	if [ "${argv[$nopt]}" == "${pattern}" ]
	then
		((nopt++))
		if (( $nopt == $argc )) || [ "${argv[$nopt]:0:1}" == "-" ]
		then
			echo "ERROR_1"
		else
			count=0
			while [ "${argv[$nopt]:0:1}" != "-" ] && (( $nopt != $argc ))
			do
				arg_array[${count}]="${argv[$nopt]}"
				((count++))
				((nopt++))
			done
			echo ${arg_array[*]}
		fi
		exit 1
	fi
	((nopt++))	

done

}

function get_arg()
{

pattern=$1
shift

argc=$#
argv=("$@")
nopt=0

while (( $nopt < $argc ))
do
	if [ "${argv[$nopt]}" == "${pattern}" ]
	then
		((nopt++))
		if (( $nopt == $argc )) || [ "${argv[$nopt]:0:1}" == "-" ]
		then
			echo "ERROR_1"
		else
			echo "${argv[$nopt]}"
		fi
		exit 1
	fi
	((nopt++))
done

echo "ERROR_0"

}

function check_arg()
{
if [[ ${2:0:5} == "ERROR" ]]; then errex "no valid argument for $1"; fi
}

function check_parameter()
{
if [[ $2 == "ERROR_1" ]]; then errex "no valid argument for $1"; fi
}

function check_int()
{
case ${1} in
	'' | *[!0-9]*)
	echo "FALSE"
	;;
	*)
	echo "TRUE"
	;;
esac
}


function exist_opt()
{

pattern=$1
shift

argc=$#
argv=("$@")
nopt=0

while (( $nopt < $argc ))
do
	if [ "${argv[$nopt]}" == "${pattern}" ]
	then
		echo "TRUE"
		exit 1
	fi
	((nopt++))
done

echo "FALSE"

}

function cleanup()
{
f=$1
if [ -f $f ]
then
echo "removing `basename $f`"
rm $f
fi
}

function check_exe()
{
	if [ ! -f $1 ]
	then
		shift
		for cmd in `seq 1 $#`
		do
			$1
			shift
		done
	fi
}

function check_dir()
{
	d=$1
	if [ ! -d $d ]
	then
		echo "making directory `basename $d`"
		mkdir $d
	fi
}

function check_exe_out()
{
	if [ ! -f $1 ]
	then
		shift
		$1 >> $2
	fi
}














