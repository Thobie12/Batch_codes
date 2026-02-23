#!/bin/bash
#SBATCH --job-name=mutect2_merge
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_merge_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_merge_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=pughlab
#SBATCH --dependency=afterok:5815971

module load gatk
module load samtools

# ----------------------------
# Sample-specific variables
# ----------------------------
#SAMPLE="423901-CFTMT_0001_3_B1-ppm0089-CATGCAGATGGCGAGAT"
#SAMPLE="423901-CFTMT_0003_1_E1-ppm0090-CTTCATGCATCTCAGAT"
#SAMPLE="423901-CFTMT_0004_3_H1-ppm0091-CATGCAAGTGTGATGAT"
SAMPLE="OICRM4CA-07-01-P"
# UPDATED: Output directory now GATK_Tumour
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/${SAMPLE}"


#VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/ucfDNA_MRDetect/GATK_Tumour/${SAMPLE}"
CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)

echo "Starting Mutect2 merge for sample: $SAMPLE"
cd "$VCF_DIR" || { echo "ERROR: Cannot cd to $VCF_DIR"; exit 1; }

# ----------------------------
# 1) Create VCF input list
# ----------------------------
VCF_LIST_FILE="${SAMPLE}_vcfs.list"
rm -f "$VCF_LIST_FILE"

for chr in "${CHRS[@]}"; do
    vcf="${SAMPLE}_${chr}.vcf.gz"
    if [[ ! -f "$vcf" ]]; then
        echo "ERROR: Missing VCF $vcf"
        exit 1
    fi
    echo "$vcf" >> "$VCF_LIST_FILE"
done

echo "VCF list created:"
cat "$VCF_LIST_FILE"

# ----------------------------
# 2) Merge VCFs
# ----------------------------
MERGED_VCF="${SAMPLE}_all.vcf.gz"

echo "Merging VCFs..."
gatk MergeVcfs \
    -I "$VCF_LIST_FILE" \
    -O "$MERGED_VCF"

# ----------------------------
# 3) Merge Mutect2 stats
# ----------------------------
STATS_LIST_FILE="${SAMPLE}_stats.list"
rm -f "$STATS_LIST_FILE"

for chr in "${CHRS[@]}"; do
    stats="${SAMPLE}_${chr}.vcf.gz.stats"
    if [[ ! -f "$stats" ]]; then
        echo "ERROR: Missing stats file $stats"
        exit 1
    fi
    echo "$stats" >> "$STATS_LIST_FILE"
done

MERGED_STATS="${MERGED_VCF}.stats"

echo "Merging Mutect2 stats..."
gatk MergeMutectStats \
    $(sed 's/^/-stats /' "$STATS_LIST_FILE") \
    -O "$MERGED_STATS"

echo "✅ Merge complete for $SAMPLE"
echo "Merged VCF:   $MERGED_VCF"
echo "Merged stats: $MERGED_STATS"
