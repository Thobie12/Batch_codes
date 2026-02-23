#!/bin/bash
#SBATCH --job-name=srsnv_illumina_bed_intersect
#SBATCH --output=srsnv_illumina_bed_%j.out
#SBATCH --error=srsnv_illumina_bed_%j.err
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

#module load bedtools
module load samtools

# --- Input VCFs ---
#SRSNV="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/OICRM4CA-07-01-P/model/srsnv_inference_out/OICRM4CA-07-01-P.srsnv_inference.normalized.PASS.dedup.SNV.filtered.vcf.gz"
#ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/Illumina/SNPs/TFRIM4_0057_Cf_P_PG_CA-07-01-P-DNA.filter.deduped.recalibrat_merged.PASS_supported_by_2_or_more_reads_encode_STR_filtered.norm.PASS.ADgt1.snp.vcf.gz"
#SRSNV="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.norm.PASS.ADgt1.snp.vcf.gz"
#SRSNV=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/OICRM4CA-07-01-P/OICRM4CA-07-01-P.pass.vcf.gz
#ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
SRSNV="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima/OICRM4CA-07-01-P/OICRM4CA-07-01-P.featuremap.vcf.gz"
#ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.norm.PASS.ADgt1.snp.vcf.gz"
#ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/VCF_tools/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.norm.PASS.ADgt1.snp.vcf.gz"
ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.norm.PASS.ADgt1.snp.vcf.gz"
#ILLUMINA=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/Illumina_cfDNA/OICRM4CA-07-01-P.vcf.gz
#SRSNV=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/Illumina_BM/OICRM4CA-07-01-P.vcf.gz


#OICRM4CA-07-01-P.featuremap.vcf.gz 
#OICRM4CA-07-01-P.featuremap.pass.vcf.gz 
# --- Output directory ---
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"
mkdir -p "$OUTDIR"

# --- Convert VCFs to BED format (CHROM, POS, REF, ALT) ---
echo "Converting SRSNV VCF to BED..."
bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$SRSNV" > "$OUTDIR/srsnv.bed"

echo "Converting Illumina VCF to BED..."
bcftools query -f '%CHROM\t%POS\t%POS\t%REF\t%ALT\n' "$ILLUMINA" > "$OUTDIR/illumina.bed"

# --- Find intersection ---
echo "Finding intersection..."
bedtools intersect -a "$OUTDIR/srsnv.bed" -b "$OUTDIR/illumina.bed" > "$OUTDIR/intersection.bed"

# --- Count variants ---
SRSNV_COUNT=$(wc -l < "$OUTDIR/srsnv.bed")
ILLUMINA_COUNT=$(wc -l < "$OUTDIR/illumina.bed")
INTERSECT_COUNT=$(wc -l < "$OUTDIR/intersection.bed")

# --- Write counts to TSV ---
echo -e "Comparison\tCount" > "$OUTDIR/intersection_countspassSNP.tsv"
echo -e "SRSNV_only\t$SRSNV_COUNT" >> "$OUTDIR/intersection_countspassSNP.tsv"
echo -e "Illumina_only\t$ILLUMINA_COUNT" >> "$OUTDIR/intersection_countspassSNP.tsv"
echo -e "Intersection\t$INTERSECT_COUNT" >> "$OUTDIR/intersection_countspassSNP.tsv"

echo "Done."
echo "Intersection BED: $OUTDIR/intersection.bed"
echo "Counts TSV: $OUTDIR/intersection_countspassSNP.tsv"
