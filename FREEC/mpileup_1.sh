#!/bin/bash
#SBATCH --job-name=mpileup_freec
#SBATCH --output=mpileup_freec_%j.log
#SBATCH --error=mpileup_freec_%j.err
#SBATCH --time=100:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --partition=pughlab

# Load Singularity if your cluster requires module loading
module load singularity

# Paths
SIF_PATH=/cluster/home/t922316uhn/UGBIO/ugbio_freec_1.5.5.sif
REF_FASTA=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
INPUT_CRAM=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram
OUTPUT_PILEUP=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/FREEC/OICRM4CA-07-01-P/OICRM4CA-07-01-P_minipileup.pileup

# Run mpileup inside Singularity container
singularity exec -B /cluster:/cluster $SIF_PATH \
  samtools mpileup \
    -f $REF_FASTA \
    -d 8000 \
    -Q 0 \
    -q 1 \
    -l /cluster/home/t922316uhn/FREEC/vcf/af-only-gnomad.hg38.AF_gt0.35.CHR1-24.vcf.gz \
    $INPUT_CRAM \
    > $OUTPUT_PILEUP
