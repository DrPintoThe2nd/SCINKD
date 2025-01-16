#!/bin/bash

#SBATCH -c 16                  		# number of cores
#SBATCH --mem=24GB              	# specify additional memory to accomodate bbmap
#SBATCH -t 0-02:00          	    # wall time (D-HH:MM)
#SBATCH -p general      	        # Uses the 
#SBATCH -q private     	            # Submits job 
#SBATCH -o scinkd.%j.out       	 	# STDOUT (%j = JobId)
#SBATCH -e scinkd.%j.err       	 	# STDERR (%j = JobId)
#SBATCH --mail-type=ALL             # Send a notification when a job starts, stops, or fails
#SBATCH --mail-user=bpinto2@asu.edu # send-to address
#SBATCH --export=NONE

module purge

source activate scinkd

snakemake --use-conda -c 16 -s SCINKD/SCINKD.v2.0.1.beta.snakefile
