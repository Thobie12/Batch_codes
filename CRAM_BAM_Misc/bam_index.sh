#!/bin/bash
#SBATCH --job-name=index_bam
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/index_bam_%j.out
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/index_bam_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=pughlab

module load samtools  # or adjust to the available version

BAM=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Bam/OICRM4CA-07-01-P.bam

echo "Indexing $BAM..."
samtools index -@ 8 "$BAM"
echo "Indexing completed."
