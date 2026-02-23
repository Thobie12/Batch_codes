#!/bin/bash
#SBATCH --job-name=mutect2_merge
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA-07_merge.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load gatk

# Same sample name as before
SAMPLE="M4-CA-07-01-P-DNA"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"
CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)

cd "${VCF_DIR}/Merged" || { echo "Failed to cd to ${VCF_DIR}/Merged"; exit 1; }

# Merge VCFs
VCF_LIST=""
for chr in "${CHRS[@]}"; do
    VCF_LIST+=" -I ${SAMPLE}_${chr}.vcf.gz"
done

echo "Merging VCFs..."
gatk MergeVcfs $VCF_LIST -O ${VCF_DIR}/${SAMPLE}_all.vcf.gz

# Merge stats files
COMBINED_STATS="${VCF_DIR}/${SAMPLE}_all.vcf.gz.stats"
echo "Merging Mutect2 stats for $SAMPLE..."
gatk MergeMutectStats \
    $(ls ${SAMPLE}_*.vcf.gz.stats | sed "s/^/-stats /") \
    -O "$COMBINED_STATS"

echo "VCF and stats merge complete for $SAMPLE"
