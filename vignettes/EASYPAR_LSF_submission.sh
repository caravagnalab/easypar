#!/bin/bash

#BSUB -J bwa_aligner[1-25]
#BSUB -P DKSMWOP331
#BSUB -q bioinformatics
#BSUB -n 1
#BSUB -R "span[hosts=1]"
#BSUB -W 168:00
#BSUB -o EASYPAR_Runner.output.%J.%I
#BSUB -e EASYPAR_Runner.errors.%J.%I

# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=
# Automatic LSF script generated via easypar
# 2019-09-29 00:05:22
# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=

# Required modules
module load R/3.4.0 


# Input file and R script
file_input=EASYPAR_LSF_input_jobarray.csv
R_script=EASYPAR_LSF_Run.R
line=$LSB_JOBINDEX

# Data loading
x=$( awk -v line=$line 'BEGIN {FS="\t"}; FNR==line {print $1}' $file_input)
y=$( awk -v line=$line 'BEGIN {FS="\t"}; FNR==line {print $2}' $file_input)

# Job run
Rscript $R_script $x $y
