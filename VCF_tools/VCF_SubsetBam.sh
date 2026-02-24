#!/bin/bash
#SBATCH --job-name=vcf_BM_subset
#SBATCH --array=0-8
#SBATCH --mem=64G
#SBATCH --partition=superhimem
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/vcf_BM_subset_%A_%a.out
#SBATCH --error=logs/vcf_BM_subset_%A_%a.err
#SBATCH --time=4:00:00

module load samtools   # includes bgzip + tabix via htslib
module load bcftools

# ── Directories ────────────────────────────────────────────────────────────────
VCF_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/BMregions_BED/VCF_Illumina
BED_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/BMregions_BED/Bed
OUT_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/BMregions_BED/VCF_Subset

mkdir -p ${OUT_DIR}
mkdir -p logs

# ── Matched pairs (index 0–8) ──────────────────────────────────────────────────
BED_FILES=(
    "TFRIM4_0032_Bm_P_WG_M4-HP-01-01-O-DNA.filter.deduped.recalibrated.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0058_Bm_P_WG_CA-08-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0058_Bm_P_WG_CA-08.filter.deduped.recalibrated.bam_merged.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0059_Bm_P_WG_FZ-08-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0060_Bm_P_WG_FZ-09-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0062_Bm_P_WG_RE-01-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0179_Bm_P_WG_HP-05-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
    "TFRIM4_0183_Bm_P_WG_VA-09-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered_regions.bed"
)

VCF_FILES=(
    "TFRIM4_0032_Cf_P_PG_M4-HP-01-01-P-DNA.filter.deduped.recalib_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0057_Cf_P_PG_CA-07-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0058_Cf_P_PG_CA-08-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0058_Cf_P_PG_CA-08-R-P-DNA.filter.deduped.recalibrate_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0059_Cf_P_PG_FZ-08-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0060_Cf_P_PG_FZ-09-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0062_Cf_P_PG_RE-01-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0179_Cf_P_PG_HP-05-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
    "TFRIM4_0183_Cf_P_PG_VA-09-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.vcf"
)

# ── Per-task execution ─────────────────────────────────────────────────────────
IDX=${SLURM_ARRAY_TASK_ID}

BED=${BED_DIR}/${BED_FILES[$IDX]}
VCF=${VCF_DIR}/${VCF_FILES[$IDX]}
BASENAME=$(basename ${VCF} .vcf)
BGZIP_VCF=${VCF_DIR}/${BASENAME}.vcf.gz
OUT_VCF=${OUT_DIR}/${BASENAME}_BM_regions_subset.vcf.gz

echo "[$(date)] ── Task ${IDX} ──────────────────────────"
echo "  BED : ${BED}"
echo "  VCF : ${VCF}"
echo "  OUT : ${OUT_VCF}"

# ── bgzip + tabix index input VCF if not already done ─────────────────────────
if [ ! -f ${BGZIP_VCF} ]; then
    echo "  [$(date)] bgzipping..."
    bgzip -c ${VCF} > ${BGZIP_VCF}
fi

if [ ! -f ${BGZIP_VCF}.tbi ]; then
    echo "  [$(date)] tabix indexing..."
    tabix -p vcf ${BGZIP_VCF}
fi

# ── Filter VCF to BED regions ─────────────────────────────────────────────────
echo "  [$(date)] Running bcftools view..."
bcftools view \
    -R ${BED} \
    -O z \
    -o ${OUT_VCF} \
    ${BGZIP_VCF}

# ── Index output ──────────────────────────────────────────────────────────────
tabix -p vcf ${OUT_VCF}

echo "[$(date)] Done → ${OUT_VCF}"
