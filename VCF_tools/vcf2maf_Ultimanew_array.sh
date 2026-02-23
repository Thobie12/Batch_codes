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

# ------------------- SETUP -------------------
module load perl vep vcf2maf samtools

VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/vaf_filtered/vaf_full"
VCF_ARRAY=($(ls ${VCF_DIR}/*_fixed_gt.vcf.gz))
VCF_GZ=${VCF_ARRAY[$SLURM_ARRAY_TASK_ID]}

SAMPLE_ID=$(basename "$VCF_GZ" .vcf.gz)  # e.g. CA-07_vaf_full

# Extract base sample name (CA-07, CA-08-R, etc.)
BASE_SAMPLE=$(echo $SAMPLE_ID | sed 's/_vaf_full/_fixed_gt/')

# Map to VCF tumor column name
if [[ $BASE_SAMPLE == *-R-* ]]; then
    VCF_TUMOR_ID="M4-${BASE_SAMPLE}-P-DNA"  # M4-CA-08-R-P-DNA
else
    VCF_TUMOR_ID="M4-${BASE_SAMPLE}-P-DNA"  # M4-CA-07-P-DNA
fi

echo "Processing $SAMPLE_ID -> VCF tumor: $VCF_TUMOR_ID"

# Decompress
VCF_INPUT="${VCF_DIR}/${BASE_SAMPLE}_vaf_full.vcf"
zcat "$VCF_GZ" > "$VCF_INPUT"

# Output MAF (use BASE_SAMPLE for filename)
MAF_OUTPUT="${VCF_DIR}/${BASE_SAMPLE}_vaf_full.maf"

# References
REF_FASTA="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VEP_CACHE="/cluster/projects/pughlab/references/VEP_cache/112"

# ------------------- RUN vcf2maf -------------------
perl /cluster/home/t922316uhn/vcf2maf/vcf2maf.pl \
  --input-vcf "$VCF_INPUT" \
  --output-maf "$MAF_OUTPUT" \
  --tumor-id "$VCF_TUMOR_ID" \
  --ref-fasta "$REF_FASTA" \
  --vep-path /cluster/tools/software/centos7/vep/112 \
  --vep-data "$VEP_CACHE" \
  --ncbi-build GRCh38 \
  --species homo_sapiens \
  --retain-fmt "VAF,RAW_VAF,DP,AD_A,AD_C,AD_G,AD_T,AD" \
  --vep-forks 8

# ------------------- CLEANUP -------------------
rm "$VCF_INPUT"
