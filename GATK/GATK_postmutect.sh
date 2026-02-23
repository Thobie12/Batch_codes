#!/bin/bash
#SBATCH --job-name=Mutect2_Merge_Filter
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/%x_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/%x_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --partition=all

module load gatk
module load samtools

# ==============================
# >>> SET SAMPLE ID HERE <<<
SAMPLE="OICRM4CA-08-01-P"
# ==============================

# --- Paths ---
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}/Merged"
COMBINED_VCF="${VCF_DIR}/${SAMPLE}_all.vcf.gz"
COMBINED_STATS="${VCF_DIR}/${SAMPLE}_all.vcf.gz.stats"
F1R2_MODEL="${VCF_DIR}/read-orientation-model.tar.gz"
FILTERED_VCF="${VCF_DIR}/filtered.vcf.gz"

# ==============================
# Step 1: Merge chromosome VCFs and stats
# ==============================
echo "[$(date)] Step 1: Merging VCFs and stats for sample $SAMPLE"
cd "$VCF_DIR" || { echo "Failed to cd to $VCF_DIR"; exit 1; }

# --- Merge VCFs ---
VCF_LIST=""
for f in ${SAMPLE}_chr*.vcf.gz; do
    if [[ -f "$f" ]]; then
        VCF_LIST+=" -I $f"
    fi
done

if [[ -z "$VCF_LIST" ]]; then
    echo "No per-chromosome VCFs found! Exiting."
    exit 1
fi

gatk MergeVcfs $VCF_LIST -O "$COMBINED_VCF"

 --- Merge stats ---
STAT_LIST=$(ls ${SAMPLE}_chr*.vcf.gz.stats 2>/dev/null | sed 's/^/-stats /')
if [[ -n "$STAT_LIST" ]]; then
    gatk MergeMutectStats $STAT_LIST -O "$COMBINED_STATS"
else
    echo "No stats files found for merging!"
fi

# ==============================
# Step 2: Learn Read Orientation Model
# ==============================
echo "[$(date)] Step 2: Running LearnReadOrientationModel"
INPUTS=""
for f in ${SAMPLE}_chr*.f1r2.tar.gz; do
    if [[ -f "$f" ]]; then
        INPUTS+="-I $f "
    fi
done

if [[ -z "$INPUTS" ]]; then
    echo "No f1r2 files found! Exiting."
    exit 1
fi

gatk LearnReadOrientationModel $INPUTS -O "$F1R2_MODEL"

# ==============================
# Step 3: Filter Mutect Calls
# ==============================
echo "[$(date)] Step 3: Running FilterMutectCalls"
gatk FilterMutectCalls \
    -R "$REF" \
    -V "$COMBINED_VCF" \
    --ob-priors "$F1R2_MODEL"
    -O "$FILTERED_VCF"

echo "[$(date)] Pipeline complete for $SAMPLE"
