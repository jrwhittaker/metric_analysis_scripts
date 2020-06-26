
###################################################
# Project: metric
# File: metric_config.sh
# Author: Joe Whittaker (whittakerj3@cardiff.ac.uk)
###################################################

DIR=$(dirname "$(readlink -f "$0")")

################## Directories ####################
FSDIR=/cubric/software/freesurfer.versions/5.3.0/bin
AFNIDIR=/cubric/software/afni.versions/19.1.21
USRFSLDIR=/cubric/software/fsl.versions/5.0.9/bin
MNIDIR=/cubric/software/fsl.versions/5.0.9/data/standard
HODIR=/cubric/software/fsl.versions/5.0.9/data/atlases/HarvardOxford
ANTSDIR=/cubric/software/ants.versions/2.1.0/bin
ANTSCRIPTDIR=/cubric/software/ants.versions/2.1.0/Scripts

CONVDIR=/home/sapjw12/code/metric/c3d-1.1.0-Linux-gcc64/bin

OASISTPLDIR=/home/sapjw12/code/metric/templates/MICCAI2012-Multi-Atlas-Challenge-Data
STDTPLDIR=/home/sapjw12/code/metric/templates/tpl-MNI152NLin2009cAsym

export AFNI_USE_ERROR_FILE=NO
