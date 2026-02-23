#!/bin/bash
#SBATCH --job-name=delly_sv2
#SBATCH --output=/cluster/home/t922316uhn/delly_%j.out
#SBATCH --error=/cluster/home/t922316uhn/delly_%j.err
#SBATCH --time=120:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH --partition=pughlab

module load delly
module load samtools


delly call \
  -g /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta \
  -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/VCF/OICRM4CA-07-01-P.delly.bcf \
  -x /cluster/home/t922316uhn/delly_excl/human.hg38.excl.tsv \
  /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram

#bcftools view /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/VCF/OICRM4CA-07-01-P.delly.bcf > /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/VCF/OICRM4CA-07-01-P.delly.vcf
