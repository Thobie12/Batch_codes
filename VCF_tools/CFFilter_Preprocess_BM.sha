#!/bin/bash
#SBATCH --job-name=vcf_filter_bm
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf/%x_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf/%x_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab

module load samtools
module load bcftools

# =============================
# Path to reference and BM_Illumina directory
# =============================
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina"

# Master output table
MERGED_TSV="all_samples_variant_counts_BM_Illumina.tsv"
echo -e "Sample\tnorm\tnorm.PASS\tnorm.PASS.ADgt1\tnorm.PASS.ADgt1.snp" > $MERGED_TSV

# =============================
# Loop through each .vcf file
# =============================
for VCF_IN in $VCF_DIR/*.vcf; do
    SAMPLE=$(basename "$VCF_IN" .vcf)
    echo "🔹 Processing $SAMPLE ..."

    # Output file names
    VCF_NORM="${VCF_DIR}/${SAMPLE}.norm.vcf.gz"
    VCF_PASS="${VCF_DIR}/${SAMPLE}.norm.PASS.vcf.gz"
    VCF_AD="${VCF_DIR}/${SAMPLE}.norm.PASS.ADgt1.vcf.gz"
    VCF_SNP="${VCF_DIR}/${SAMPLE}.norm.PASS.ADgt1.snp.vcf.gz"

    # Step 1: Normalize
    bcftools norm -f $REF -Oz -o $VCF_NORM $VCF_IN
    bcftools index -f $VCF_NORM

    # Step 2: Filter PASS
    bcftools view -f PASS -Oz -o $VCF_PASS $VCF_NORM
    bcftools index -f $VCF_PASS

    # Step 3: Filter AD>1 (any sample ALT depth >1)
    bcftools view -i 'FMT/AD[*:1]>1' -Oz -o $VCF_AD $VCF_PASS
    bcftools index -f $VCF_AD

    # Step 4: Keep only SNPs
    bcftools view -v snps -Oz -o $VCF_SNP $VCF_AD
    bcftools index -f $VCF_SNP

    # Step 5: Count variants and add to merged table
    NORM_COUNT=$(bcftools view -H $VCF_NORM | wc -l)
    PASS_COUNT=$(bcftools view -H $VCF_PASS | wc -l)
    AD_COUNT=$(bcftools view -H $VCF_AD | wc -l)
    SNP_COUNT=$(bcftools view -H $VCF_SNP | wc -l)

    echo -e "${SAMPLE}\t${NORM_COUNT}\t${PASS_COUNT}\t${AD_COUNT}\t${SNP_COUNT}" >> $MERGED_TSV

    echo "✅ Finished $SAMPLE (norm=$NORM_COUNT, PASS=$PASS_COUNT, ADgt1=$AD_COUNT, SNP=$SNP_COUNT)"
    echo "--------------------------------------------"
done

echo "🎯 All done! Summary table saved as: $MERGED_TSV"
