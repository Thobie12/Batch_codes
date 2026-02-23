#!/bin/bash
#SBATCH --job-name=bam2cram
#SBATCH --output=logs/bam2cram_%j.out
#SBATCH --error=logs/bam2cram_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=pughlab

set -euo pipefail

# Create logs directory if it doesn't exist
mkdir -p logs

# Paths
FASTA=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
BAM=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam/TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.realigned.merged.bam
CRAM="${BAM%.bam}.cram"

echo "Converting BAM to CRAM:"
echo "Input BAM: $BAM"
echo "Reference FASTA: $FASTA"
echo "Output CRAM: $CRAM"

# Convert BAM → CRAM using Sambamba with 8 threads
sambamba view -S -f cram -t 8 -T "$FASTA" -o "$CRAM" "$BAM"

# Index the CRAM using samtools
echo "Indexing CRAM file..."
samtools index "$CRAM"

echo "Conversion and indexing complete."
