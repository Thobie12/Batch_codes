#!/bin/bash
#SBATCH --job-name=multi_snv_intersect
#SBATCH --output=multi_snv_intersect_%j.out
#SBATCH --error=multi_snv_intersect_%j.err
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load bedtools
module load samtools

# --- Directories ---
SRSNV_DIR_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample"
ILLUMINA_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/Illumina/SNPs"
BM_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs"

OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections/multi_sample"
mkdir -p "$OUTDIR"

# --- Input sample mapping file ---
SAMPLES_FILE="samples_comp.txt"   # adjust path if needed

# --- Combined summary file ---
SUMMARY_FILE="$OUTDIR/combined_counts.tsv"
echo -e "Sample\tSRSNV_only\tIllumina_only\tBM_only\tSRSNV_vs_Illumina\tSRSNV_vs_BM\tBM_vs_Illumina" > "$SUMMARY_FILE"

# --- Loop through each sample ---
while IFS=$'\t' read -r SAMPLE BM_FILE ILLUMINA_FILE; do
    echo "Processing sample: $SAMPLE"

    # Construct SRSNV path
    SRSNV="$SRSNV_DIR_BASE/$SAMPLE/model/srsnv_inference_out/${SAMPLE}.tmp.dedup.vcf.gz"
    BM="$BM_DIR/$BM_FILE"
    ILLUMINA="$ILLUMINA_DIR/$ILLUMINA_FILE"

    SAMPLE_OUT="$OUTDIR/$SAMPLE"
    mkdir -p "$SAMPLE_OUT"

    # --- Convert VCFs to BED ---
    echo "Converting VCFs to BED..."
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$SRSNV" > "$SAMPLE_OUT/srsnv.bed"
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$ILLUMINA" > "$SAMPLE_OUT/illumina.bed"
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$BM" > "$SAMPLE_OUT/bm.bed"

    # --- Pairwise intersections ---
    echo "Intersecting SRSNV vs Illumina..."
    bedtools intersect -a "$SAMPLE_OUT/srsnv.bed" -b "$SAMPLE_OUT/illumina.bed" > "$SAMPLE_OUT/srsnv_vs_illumina.bed"

    echo "Intersecting SRSNV vs BM..."
    bedtools intersect -a "$SAMPLE_OUT/srsnv.bed" -b "$SAMPLE_OUT/bm.bed" > "$SAMPLE_OUT/srsnv_vs_bm.bed"

    echo "Intersecting BM vs Illumina..."
    bedtools intersect -a "$SAMPLE_OUT/bm.bed" -b "$SAMPLE_OUT/illumina.bed" > "$SAMPLE_OUT/bm_vs_illumina.bed"

    # --- Count variants ---
    SRSNV_COUNT=$(wc -l < "$SAMPLE_OUT/srsnv.bed")
    ILLUMINA_COUNT=$(wc -l < "$SAMPLE_OUT/illumina.bed")
    BM_COUNT=$(wc -l < "$SAMPLE_OUT/bm.bed")
    SRSNV_ILLUMINA_COUNT=$(wc -l < "$SAMPLE_OUT/srsnv_vs_illumina.bed")
    SRSNV_BM_COUNT=$(wc -l < "$SAMPLE_OUT/srsnv_vs_bm.bed")
    BM_ILLUMINA_COUNT=$(wc -l < "$SAMPLE_OUT/bm_vs_illumina.bed")

    # --- Write counts to TSV for this sample ---
    echo -e "Comparison\tCount" > "$SAMPLE_OUT/counts.tsv"
    echo -e "SRSNV_only\t$SRSNV_COUNT" >> "$SAMPLE_OUT/counts.tsv"
    echo -e "Illumina_only\t$ILLUMINA_COUNT" >> "$SAMPLE_OUT/counts.tsv"
    echo -e "BM_only\t$BM_COUNT" >> "$SAMPLE_OUT/counts.tsv"
    echo -e "SRSNV_vs_Illumina\t$SRSNV_ILLUMINA_COUNT" >> "$SAMPLE_OUT/counts.tsv"
    echo -e "SRSNV_vs_BM\t$SRSNV_BM_COUNT" >> "$SAMPLE_OUT/counts.tsv"
    echo -e "BM_vs_Illumina\t$BM_ILLUMINA_COUNT" >> "$SAMPLE_OUT/counts.tsv"

    # --- Append to combined summary ---
    echo -e "${SAMPLE}\t${SRSNV_COUNT}\t${ILLUMINA_COUNT}\t${BM_COUNT}\t${SRSNV_ILLUMINA_COUNT}\t${SRSNV_BM_COUNT}\t${BM_ILLUMINA_COUNT}" >> "$SUMMARY_FILE"

    echo "Finished sample: $SAMPLE"
done < "$SAMPLES_FILE"

echo "All samples processed!"
echo "Combined summary: $SUMMARY_FILE"
