#!/bin/bash
#SBATCH --job-name=mosdepth
#SBATCH --output=/cluster/home/t922316uhn/PLO/mosdepth%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/mosdepth%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=pughlab


/cluster/home/t922316uhn/mosdepth//mosdepth --fast-mode --by 1000000 --threads 8 \
  --fasta /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta \
  /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/depth/OICRM4CA-07-01-P \
  /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram


