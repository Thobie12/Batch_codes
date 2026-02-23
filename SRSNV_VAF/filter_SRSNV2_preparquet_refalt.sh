#!/bin/bash
#SBATCH --job-name=vcf_clean
#SBATCH --partition=superhimem
#SBATCH --mem=64G
#SBATCH --cpus-per-task=2
#SBATCH --time=24:00:00
#SBATCH --output=vcf_clean_%j.log
#SBATCH --error=vcf_clean_%j.err

# =========================
# Variables
# =========================
BASE="OICRM4CA-07-01-P"
INPUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/${BASE}"
RAW_VCF="${INPUT_DIR}/${BASE}.raw.training_regions.vcf.gz"
CLEAN_VCF="${INPUT_DIR}/${BASE}.raw.training_regions.cleaned.vcf.gz"

# =========================
# Load modules
# =========================
module load samtools
module load tabix

# =========================
# 1) Identify ambiguous variants
# =========================
echo "Checking for ambiguous variants (non-ACGT REF/ALT)..."
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' "$RAW_VCF" \
| awk '$3 !~ /^[ACGT]$/ || $4 !~ /^[ACGT]$/' \
> "${INPUT_DIR}/${BASE}.ambiguous_variants.txt"

# Count how many ambiguous variants
AMB_COUNT=$(wc -l < "${INPUT_DIR}/${BASE}.ambiguous_variants.txt")
echo "Found $AMB_COUNT ambiguous variants. Details in ${BASE}.ambiguous_variants.txt"

# =========================
# 2) Filter out non-ACGT variants
# =========================
#echo "Filtering to only A/C/G/T REF and ALT..."
# Paths
#RAW_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/${BASE}/${BASE}.raw.training_regions.vcf.gz"
#CLEAN_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/${BASE}/${BASE}.raw.training_regions.cleaned.vcf.gz"

# Filter only A/C/G/T REF and ALT
echo "Filtering to only A/C/G/T REF and ALT..."
bcftools view \
  -i '(REF="A" || REF="C" || REF="G" || REF="T") && (ALT="A" || ALT="C" || ALT="G" || ALT="T")' \
  -Oz -o "$CLEAN_VCF" \
  "$RAW_VCF"

# Index the cleaned VCF
echo "Indexing cleaned VCF..."
tabix -p vcf "$CLEAN_VCF"

echo "Done. Clean VCF: $CLEAN_VCF"


#bcftools view \
#  -i 'REF="A" || REF="C" || REF="G" || REF="T"' \
#  -i 'ALT="A" || ALT="C" || ALT="G" || ALT="T"' \
#  -Oz -o "$CLEAN_VCF" \
#  "$RAW_VCF"

# =========================
# 3) Index the filtered VCF
# =========================
echo "Indexing cleaned VCF..."
tabix -p vcf "$CLEAN_VCF"

echo "Done. Clean VCF: $CLEAN_VCF"
