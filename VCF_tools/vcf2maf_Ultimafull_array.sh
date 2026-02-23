#!/bin/bash
#SBATCH --job-name=vcf2maf_array
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.log
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.err
#SBATCH --partition=superhimem
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --array=0-8
# ↑ adjust array size (0-N) based on number of .vcf.gz files

# ------------------- SETUP -------------------
module load perl
module load vep
module load vcf2maf
module load samtools

#VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections"
#VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/vaf_filtered/vaf_full"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/"

# Get list of VCFs
VCF_ARRAY=($(ls ${VCF_DIR}/OICRM4*/*.vcf.gz))
VCF_GZ=${VCF_ARRAY[$SLURM_ARRAY_TASK_ID]}

# Extract sample name
SAMPLE_ID=$(basename "$VCF_GZ" .vcf.gz)

echo "Processing sample $SAMPLE_ID: $VCF_GZ"

# Decompress to temporary .vcf ; add a .gz to vcg decompression using gunzip  if needed
VCF_INPUT="${VCF_DIR}/MAFs/${SAMPLE_ID}_downsampled.vcf"

#Downsample vcf to be used for the next steps - remove this if not downsampling
bcftools view "$VCF_GZ" | \
  awk 'BEGIN {srand(42); rate=0.05} \
       /^#/ {print; next} \
       {if (rand() < rate) print}' \
  > "$VCF_INPUT"

# Output MAF
MAF_OUTPUT="${VCF_DIR}/MAFs/${SAMPLE_ID}.maf"

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
  --retain-fmt GT,AD,AF,DP \
  --vep-data /cluster/projects/pughlab/references/VEP_cache/112 \
  --vep-forks 8

# ------------------- CLEANUP -------------------
## add a rm for vcf input if neede; removing cos need raw vcf too

