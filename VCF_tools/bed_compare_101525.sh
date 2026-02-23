#!/bin/bash
#SBATCH --job-name=srsnv_illumina_bed_intersect
#SBATCH --output=srsnv_illumina_bed_%j.out
#SBATCH --error=srsnv_illumina_bed_%j.err
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

# --- Load modules ---
module load bcftools
module load bedtools
module load samtools

# --- Input VCFs ---
SRSNV="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap.vcf.gz"
ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.norm.PASS.vcf.gz"

# --- Output directory ---
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"
mkdir -p "$OUTDIR"

echo "=== Converting VCFs to BED format (SNPs only) ==="

# --- Filter SRSNV to true SNPs (exclude non-variant / non-SNP lines) ---
echo "Filtering SRSNV VCF to SNPs only..."
bcftools view -v snps -f PASS "$SRSNV" | \
  bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' > "$OUTDIR/srsnv_snps.bed"

# --- Convert Illumina VCF to BED format (SNPs only, same way) ---
echo "Filtering Illumina VCF to SNPs only..."
bcftools view -v snps -f PASS "$ILLUMINA" | \
  bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' > "$OUTDIR/illumina_snps.bed"

# --- Find intersection ---
echo "Finding intersection..."
bedtools intersect -a "$OUTDIR/srsnv_snps.bed" -b "$OUTDIR/illumina_snps.bed" > "$OUTDIR/intersection.bed"

# --- Count variants ---
SRSNV_COUNT=$(wc -l < "$OUTDIR/srsnv_snps.bed")
ILLUMINA_COUNT=$(wc -l < "$OUTDIR/illumina_snps.bed")
INTERSECT_COUNT=$(wc -l < "$OUTDIR/intersection.bed")

# --- Write counts to TSV ---
OUT_TSV="$OUTDIR/intersection_counts_passSNP.tsv"
{
  echo -e "Comparison\tCount"
  echo -e "SRSNV_only\t$SRSNV_COUNT"
  echo -e "Illumina_only\t$ILLUMINA_COUNT"
  echo -e "Intersection\t$INTERSECT_COUNT"
} > "$OUT_TSV"

echo "=== Done ==="
echo "Intersection BED: $OUTDIR/intersection.bed"
echo "Counts TSV: $OUT_TSV"
