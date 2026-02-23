#!/bin/bash
#SBATCH --job-name=ultima_illumina_compare
#SBATCH --output=ultima_illumina_compare_%j.out
#SBATCH --error=ultima_illumina_compare_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load bedtools
module load samtools
#module load bcftools

# === Directories ===
ULTIMA_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/Illumina_cfDNA"
ILLUMINA_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/Illumina_BM"
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections/ultima_vs_illumina"
mkdir -p "$OUTDIR"

# === Global summary ===
SUMMARY_FILE="$OUTDIR/all_samples_intersection_counts2.tsv"
echo -e "Sample\tUltima\tIllumina\tIntersection" > "$SUMMARY_FILE"

# === Loop over all Ultima VCFs ===
for ULTIMA_VCF in "$ULTIMA_BASE"/*.vcf.gz; do
    SAMPLE=$(basename "$ULTIMA_VCF" .vcf.gz)

    echo "Processing sample: $SAMPLE"

    # Extract patient code (e.g. CA-07-01-P or HP-05-01-O)
    PATIENT_CODE=$(echo "$SAMPLE" | grep -oE '[A-Z]{2}-[0-9]{2}-[0-9]{2}-[OP]')

    # Find matching Illumina file
    ILLUMINA_VCF=$(ls "$ILLUMINA_BASE"/*${PATIENT_CODE}*.vcf.gz 2>/dev/null | grep -v ".csi" | head -n1)

    if [[ -z "$ILLUMINA_VCF" ]]; then
        echo "❌ No Illumina match found for $SAMPLE ($PATIENT_CODE)"
        continue
    fi

    echo "  Ultima:   $ULTIMA_VCF"
    echo "  Illumina: $ILLUMINA_VCF"

    PREFIX="$OUTDIR/${SAMPLE}"

    # Convert both to BED (CHR, start, end, REF, ALT)
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$ULTIMA_VCF" > "${PREFIX}_ultima.bed"
    bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$ILLUMINA_VCF" > "${PREFIX}_illumina.bed"

    # Intersection
    bedtools intersect -a "${PREFIX}_ultima.bed" -b "${PREFIX}_illumina.bed" > "${PREFIX}_intersection.bed"

    # Counts
    ULTIMA_COUNT=$(wc -l < "${PREFIX}_ultima.bed")
    ILLUMINA_COUNT=$(wc -l < "${PREFIX}_illumina.bed")
    INTERSECT_COUNT=$(wc -l < "${PREFIX}_intersection.bed")

    # Per-sample file
    echo -e "Comparison\tCount" > "${PREFIX}_counts.tsv"
    echo -e "Ultima_only\t$ULTIMA_COUNT" >> "${PREFIX}_counts.tsv"
    echo -e "Illumina_only\t$ILLUMINA_COUNT" >> "${PREFIX}_counts.tsv"
    echo -e "Intersection\t$INTERSECT_COUNT" >> "${PREFIX}_counts.tsv"

    # Append to global summary
    echo -e "${SAMPLE}\t${ULTIMA_COUNT}\t${ILLUMINA_COUNT}\t${INTERSECT_COUNT}" >> "$SUMMARY_FILE"
done
