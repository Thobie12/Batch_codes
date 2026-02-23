#!/bin/bash
#SBATCH --job-name=CollectF1R2Counts
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/CollectF1R2Counts_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/CollectF1R2Counts_%j.err
#SBATCH --time=7-24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=26G
#SBATCH --partition=pughlab

# Load required modules
module load java
module load gatk

# --- USER VARIABLE: only change this ---
SAMPLE_ID="OICRM4CA-08-R-P"

# Construct file paths based on sample ID
CRAM="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE_ID}.cram"
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE_ID}"
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"

# Run GATK CollectF1R2Counts
gatk CollectF1R2Counts \
    -R $REFERENCE \
    -I $CRAM \
    -O $OUTDIR/${SAMPLE_ID}.f1r2.tar.gz
