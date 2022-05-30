#!/bin/bash

#PBS -P DKSMWOP331
#PBS -q bioinformatics
#PBS -l walltime=3:00:00
#PBS -l nodes=1:ppn=16
#PBS -N EASYPAR_Runner
#PBS -o output.^array_index^.log
#PBS -e error.^array_index^.err
#PBS -J bwa_aligner1-25

# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=
# Automatic PBSpro script generated via easypar
# 2022-05-30 15:18:19
# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=

# Required modules
module load R/3.5.0 



# Input file and R script
file_input=${PBS_O_WORKDIR}/EASYPAR_PBSpro_input_jobarray.csv
R_script=${PBS_O_WORKDIR}/EASYPAR_PBSpro_Run.R

PER_TASK=1
START_NUM=$(( ($PBS_ARRAY_INDEX - 1) * $PER_TASK + 1 ))
END_NUM=$(( $PBS_ARRAY_INDEX * $PER_TASK ))
echo This is task $PBS_ARRAY_INDEX, which will do runs $START_NUM to $END_NUM


# Looping over tasks 
for (( run=$START_NUM; run<=$END_NUM; run++ )); do 
	echo This is PBSpro task $PBS_ARRAY_INDEX, run number $run 
	# Data loading 
	x=$( awk -v line=$run 'BEGIN {FS="\t"}; FNR==line {print $1}' $file_input)
	y=$( awk -v line=$run 'BEGIN {FS="\t"}; FNR==line {print $2}' $file_input)
	# Job run 
	Rscript $R_script $x $y
done 

date
