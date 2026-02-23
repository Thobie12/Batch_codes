#!/bin/bash
#SBATCH --job-name=Mutect2_Filter
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/%x_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/%x_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load gatk
module load samtools

# ==============================
# >>> SET SAMPLE ID HERE <<<
SAMPLE="OICRM4HP-01-01-P"

# --- Paths ---
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"
COMBINED_VCF="${VCF_DIR}/${SAMPLE}_all.vcf.gz"
COMBINED_STATS="${VCF_DIR}/${SAMPLE}_all.vcf.gz.stats"
F1R2_MODEL="${VCF_DIR}/vcf/read-orientation-model.tar.gz"
FILTERED_VCF="${VCF_DIR}/vcf/${SAMPLE}_GATKfiltered.vcf.gz"
CLEAN_VCF="${VCF_DIR}/vcf/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.vcf.gz"

# Intervals to exclude
#REPEAT_MASKER="/cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/30XWGS_Feb2023/STR_regions/unzipped/hg38_repeatmasker.bed"
#ENCODE_BLACKLIST="/cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/Output_OICR_blood_as_tumor/merged_vcfs/unzipped/vaf_above_0.01/encode_blacklist_removed/hg38-blacklist.v2.bed"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

# ==============================
# Step 1: Learn Read Orientation Model
# ==============================
echo "[$(date)] Step 1: Running LearnReadOrientationModel"
INPUTS=""
for f in ${VCF_DIR}/${SAMPLE}_chr*.f1r2.tar.gz; do
    if [[ -f "$f" ]]; then
        INPUTS+="-I $f "
    fi
done

if [[ -z "$INPUTS" ]]; then
    echo "No f1r2 files found! Exiting."
    exit 1
fi

gatk --java-options "-Xmx16g" LearnReadOrientationModel $INPUTS -O "$F1R2_MODEL"

# ==============================
# Step 2: Filter Mutect Calls
# ==============================
echo "[$(date)] Step 2: Running FilterMutectCalls"
gatk --java-options "-Xmx16g" FilterMutectCalls \
    -R "$REF" \
    -V "$COMBINED_VCF" \
    --ob-priors "$F1R2_MODEL" \
    -O "$FILTERED_VCF"

# ==============================
# Step 3: Exclude blacklist and repeats
# ==============================
echo "[$(date)] Step 3: Running SelectVariants (exclude blacklist + repeats)"
gatk --java-options "-Xmx16g" SelectVariants \
    -R "$REF" \
    -V "$FILTERED_VCF" \
    --exclude-intervals "$REPEAT_MASKER" \
    --exclude-intervals "$ENCODE_BLACKLIST" \
    -O "$CLEAN_VCF" \
    --create-output-variant-index true

echo "[$(date)] Pipeline complete for $SAMPLE"
echo "Final cleaned VCF: $CLEAN_VCF"
