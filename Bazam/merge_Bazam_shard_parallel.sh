#!/bin/bash
#SBATCH --job-name=merge_realign
#SBATCH --output=/cluster/home/t922316uhn/PLO/Bazam/logs/merge_realign_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Bazam/logs/merge_realign_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=pughlab

module load samtools

# ================================
# Parameters (edit SAMPLE_ID only)
# ================================

SAMPLE_ID="TFRIM4_0032_Pb_R_PG"
#SAMPLE_ID="TFRIM4_0179_Pb_R_HP-05-01-B-DNA"
#SAMPLE_ID="TFRIM4_0062_Pb_R_WG_RE-01-03-B-DNA"
#SAMPLE_ID="TFRIM4_0060_Pb_R_WG_FZ-09-03-B-DNA"
#SAMPLE_ID="TFRIM4_0059_Pb_R_WG_FZ-08-01-B-DNA"
OUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam"
THREADS=8
MERGED_BAM="${OUT_DIR}/${SAMPLE_ID}.realigned.merged.bam"

# ================================
# Merge BAM shards
# ================================
echo "Merging shards for sample: ${SAMPLE_ID}"

samtools merge -@ $THREADS "$MERGED_BAM" \
  ${OUT_DIR}/${SAMPLE_ID}.filter.deduped.recalibrated.realigned.shard*.bam

samtools index -@ $THREADS "$MERGED_BAM"

echo "✅ Merged BAM complete: $MERGED_BAM"
