#!/bin/bash
#SBATCH --job-name=cnv_ref
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --output=/cluster/home/t922316uhn/PLO/cnvref_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/cnvref_%j.err
#SBATCH --partition=pughlab
module load python3
source $(conda info --base)/etc/profile.d/conda.sh
conda activate paras_env

#parascopy cn-using data/models_v1.2.5/EUR -I /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/input-list.txt -t /cluster/home/t922316uhn/parascopy/homology/homology_table/hg38.bed.gz -f /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta  -d /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/analysis1 -@ 8

#parascopy pretable -f /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta -@ 8 -o  /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/pretable.bed.gz

parascopy cn -I /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/input-list.txt -t /cluster/home/t922316uhn/parascopy/homology/homology_table/hg38.bed.gz -R /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/mm_targets2.bed -f /cluster/tools/data/genomes/human/hg38/iGenomes/Sequence/WholeGenomeFasta/genome.fa  -d /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/analysis2
