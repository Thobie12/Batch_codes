#!/bin/bash
#SBATCH --job-name=vcf2maf_array
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.log
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.err
#SBATCH --partition=superhimem
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=1:00:00
#SBATCH --array=0-8
# ↑ adjust array size (0-N) based on number of .vcf.gz files

# ------------------- SETUP -------------------
module load perl
module load vep
module load vcf2maf
module load samtools

#VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/vaf_filtered/vaf_full"
# Get list of VCFs
VCF_ARRAY=($(ls ${VCF_DIR}/*.vcf.gz))
VCF_GZ=${VCF_ARRAY[$SLURM_ARRAY_TASK_ID]}

# Extract sample name
SAMPLE_ID=$(basename "$VCF_GZ" .vcf.gz)

# Decompress to temporary .vcf
VCF_INPUT="${VCF_DIR}/${SAMPLE_ID}.vcf"
zcat "$VCF_GZ" > "$VCF_INPUT"

# Output MAF
MAF_OUTPUT="${VCF_DIR}/${SAMPLE_ID}.maf"

# References
REF_FASTA="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VEP_PATH="/cluster/tools/software/centos7/vep/112"
VCF2MAF_PATH="/cluster/home/t922316uhn/vcf2maf/vcf2maf.pl"

# ------------------- RUN -------------------
perl $VCF2MAF_PATH \
  --input-vcf $VCF_INPUT \
  --output-maf $MAF_OUTPUT \
  --tumor-id $SAMPLE_ID \
  --ref-fasta $REF_FASTA \
  --vep-path $VEP_PATH \
  --ncbi-build GRCh38 \
  --species homo_sapiens \
  --retain-info DP,AD,AF,SB \
  --retain-fmt "VAF,RAW_VAF,t_AF,t_DP,t_alt_count,AD,DP" \
  --vep-data /cluster/projects/pughlab/references/VEP_cache/112 \
  --vep-forks 8

# ------------------- CLEANUP -------------------
rm "$VCF_INPUT"
