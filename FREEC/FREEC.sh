#!/bin/bash
#SBATCH --job-name=FREEC
#SBATCH --output=/cluster/home/t922316uhn/PLO/FREEC/FREEC_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/FREEC/FREEC_%j.err
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=256G
#SBATCH --partition=superhimem

module load samtools
module load R
module load sambamba
module load bedtools

/cluster/home/t922316uhn/FREEC/FREEC-11.6b/src/freec -conf /cluster/home/t922316uhn/FREEC/Configs/test.txt
