#!/bin/bash
#SBATCH --job-name=srsnv_illumina_batch
#SBATCH --output=srsnv_illumina_batch_%j.out
#SBATCH --error=srsnv_illumina_batch_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load bedtools
module load samtools
#module load bcftools

# === Inputs ===
SAMPLE_LIST="samples.txt"
SRSNV_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample"
#ILLUMINA_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/Illumina/SNPs"
ILLUMINA_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs"
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections/srsnv_illumina_bed"
mkdir -p "$OUTDIR"

# === Global summary file ===
SUMMARY_FILE="$OUTDIR/all_samples_BM_intersection_counts.tsv"
echo -e "Sample\tSRSNV\tIllumina\tIntersection" > "$SUMMARY_FILE"

# === Loop over samples ===
while read -r SAMPLE; do
    echo "Processing sample: $SAMPLE"

    # Define input files
    SRSNV_VCF="$SRSNV_BASE/${SAMPLE}/model/srsnv_inference_out/${SAMPLE}.tmp.dedup.vcf.gz"

    # Extract patient code (e.g. CA-07-01-P) from sample name
    PATIENT_CODE=$(echo "$SAMPLE" | grep -oE '[A-Z]{2}-[0-9]{2}-[0-9]{2}-O')

    # Find Illumina file
    ILLUMINA_VCF=$(ls $ILLUMINA_BASE/*${PATIENT_CODE}*.vcf.gz 2>/dev/null | grep -v ".csi" | head -n1)

    # Check inputs
    if [[ ! -f "$SRSNV_VCF" ]]; then
        echo "❌ SRSNV VCF not found for $SAMPLE: $SRSNV_VCF"
        continue
    fi

    if [[ -z "$ILLUMINA_VCF" ]]; then
        echo "❌ Illumina VCF not found for $SAMPLE (patient code $PATIENT_CODE)"
        continue
    fi

    echo "  SRSNV:    $SRSNV_VCF"
    echo "  Illumina: $ILLUMINA_VCF"

    # Output prefix
    PREFIX="$OUTDIR/${SAMPLE}"

    # Convert to BED
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$SRSNV_VCF" > "${PREFIX}_srsnv.bed"
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$ILLUMINA_VCF" > "${PREFIX}_illumina.bed"

    # Intersection
    bedtools intersect -a "${PREFIX}_srsnv.bed" -b "${PREFIX}_illumina.bed" > "${PREFIX}_intersection.bed"

    # Counts
    SRSNV_COUNT=$(wc -l < "${PREFIX}_srsnv.bed")
    ILLUMINA_COUNT=$(wc -l < "${PREFIX}_illumina.bed")
    INTERSECT_COUNT=$(wc -l < "${PREFIX}_intersection.bed")

    # Per-sample counts file
    echo -e "Comparison\tCount" > "${PREFIX}_counts.tsv"
    echo -e "SRSNV_only\t$SRSNV_COUNT" >> "${PREFIX}_counts.tsv"
    echo -e "Illumina_only\t$ILLUMINA_COUNT" >> "${PREFIX}_counts.tsv"
    echo -e "Intersection\t$INTERSECT_COUNT" >> "${PREFIX}_counts.tsv"

    # Append to global summary
    echo -e "${SAMPLE}\t${SRSNV_COUNT}\t${ILLUMINA_COUNT}\t${INTERSECT_COUNT}" >> "$SUMMARY_FILE"

    echo "✅ Done: $SAMPLE"
done < "$SAMPLE_LIST"

echo "All samples processed."
echo "Big summary: $SUMMARY_FILE"
