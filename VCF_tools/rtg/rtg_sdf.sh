#!/bin/bash
#SBATCH --job-name=rtg_sdf
#SBATCH --output=rtg_sdf_%j.out
#SBATCH --error=rtg_sdf_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load java

FASTA=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
SDF=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/reference_sdf

if [ ! -d "$SDF" ]; then
    echo "Generating SDF from reference FASTA..."
    rtg format -o "$SDF" "$FASTA"
else
    echo "SDF already exists at $SDF, skipping generation."
fi
