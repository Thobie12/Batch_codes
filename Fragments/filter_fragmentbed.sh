#!/bin/bash
#SBATCH --job-name=FragmentBed
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Filter_%j.log
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Filter_%j.log
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --partition=superhimem

# Load modules
module load samtools


#Filter for mapq > 20 and zip it.

awk 'NR==1 || $5 > 20' /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Fragmentomics/OICRM4CA-07-01-P_fragment.bed | bgzip -@8 > /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Fragmentomics/OICRM4CA-07-01-P_fragment_MAPQ20.bed.gz
