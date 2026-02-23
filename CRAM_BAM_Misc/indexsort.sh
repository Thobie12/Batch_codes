#!/bin/bash
#SBATCH --job-name=sort_index
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=03:00:00
#SBATCH --output=/cluster/home/t922316uhn/PLO/sort_index_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/sort_index_%j.err
#SBATCH --partition=pughlab

module load samtools 

samtools index \
  -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Dedup/OICRM4CA-07-01-P.sorted.cram.crai \
  /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Dedup/OICRM4CA-07-01-P.sorted.cram
