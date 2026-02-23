#!/bin/bash
#SBATCH --job-name=depth_freec
#SBATCH --output=depth_freec_%j.log
#SBATCH --error=depth_freec_%j.err
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

# Load Singularity if required
module load singularity

# Paths
SIF_PATH=/cluster/home/t922316uhn/UGBIO/ugbio_freec_1.5.5.sif
REF_FASTA=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
INPUT_CRAM=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram
OUTPUT_BEDGRAPH=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/FREEC/OICRM4CA-07-01-P/OICRM4CA-07-01-P.bedgraph

# Run samtools depth inside Singularity
singularity exec -B /cluster:/cluster $SIF_PATH \
  samtools depth \
    -J \
    -Q 1 \
    --reference $REF_FASTA \
    $INPUT_CRAM | \
  awk '{print $1"\t"($2-1)"\t"$2"\t"$3}' > $OUTPUT_BEDGRAPH
