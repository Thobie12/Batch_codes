#!/bin/bash
#SBATCH --job-name=Bgread_depth
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/cluster/home/t922316uhn/PLO/Bgread_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Bgread_%j.err

module load python3
source $(conda info --base)/etc/profile.d/conda.sh
conda activate paras_env

#parascopy depth -I /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/input-list.txt -g hg38 -f /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth

parascopy depth -I /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/input-list.txt -g hg38 -f /cluster/tools/data/genomes/human/hg38/iGenomes/Sequence/WholeGenomeFasta/genome.fa -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/CA-07/depth
