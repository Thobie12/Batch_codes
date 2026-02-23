#!/bin/bash
#SBATCH --job-name=rtg_vcfeval
#SBATCH --output=rtg_Illumina_%j.out
#SBATCH --error=rtg_Illumina_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --partition=superhimem

module load java
# export PATH=/cluster/home/t922316uhn/rtg-tools/rtg-tools-3.12.1:$PATH

# --- Paths ---
SDF=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/reference_sdf
ULTIMA_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/iIllumina_cfDNA
ILLUMINA_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/Illumina_BM
BED_REGIONS=/cluster/projects/pughlab/references/Ultima/SRSNV/ug_hcr.bed
OUTDIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/vcfeval_results_Illumina
mkdir -p "$OUTDIR"

# --- Loop over each sample in the table ---
tail -n +2 samples.txt | while read -r SAMPLE BM_ID CF_ID; do
    echo ">>> Processing $SAMPLE"

    UG_VCF="$ULTIMA_DIR/${SAMPLE}.vcf.gz"
    BASELINE_VCF="$ILLUMINA_DIR/${SAMPLE}.vcf.gz"

    if [ ! -f "$BASELINE_VCF" ]; then
        echo "⚠️ Baseline VCF not found for $SAMPLE, skipping."
        continue
    fi

    if [ ! -f "$UG_VCF" ]; then
        echo "⚠️ UG VCF not found for $SAMPLE, skipping."
        continue
    fi

    SAMPLE_OUT="$OUTDIR/${SAMPLE}"

    echo "Running vcfeval for $SAMPLE with samples: BM=$BM_ID, cfDNA=$CF_ID"

    rtg vcfeval \
        -b "$BASELINE_VCF" \
        -c "$UG_VCF" \
        -o "$SAMPLE_OUT" \
        -t "$SDF" \
        --decompose \
        --squash-ploidy \
        --sample="$BM_ID","$CF_ID" \
        --bed-regions "$BED_REGIONS" \
        -f QUAL
done
