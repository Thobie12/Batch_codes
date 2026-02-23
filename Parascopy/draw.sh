#!/bin/bash
#SBATCH --job-name=agcn_job            # Job name
#SBATCH --output=/cluster/home/t922316uhn/PLO/agcn_job_%j.out       # Standard output log (%j expands to jobId)
#SBATCH --error=/cluster/home/t922316uhn/PLO/agcn_job_%j.err        # Standard error log
#SBATCH --time=02:00:00                # Max runtime (HH:MM:SS)
#SBATCH --ntasks=1                     # Number of tasks (usually 1 for R scripts)
#SBATCH --cpus-per-task=4              # Number of CPU cores for your job
#SBATCH --mem=16G                     # Memory (adjust as needed)
# Partition/queue name (adjust to your cluster)

# Load R module if needed (check your cluster's module system)
module load R                    # or whatever R version is installed

# Run your R script with arguments
Rscript /cluster/home/t922316uhn/parascopy/parascopy/draw/agcn.r \
  --input /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth \
  --output /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth \
  --samples M4-CA-07-01-P-DNA
