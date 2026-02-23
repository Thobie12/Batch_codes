#!/bin/bash
#SBATCH --job-name=vcf_filter
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf/%x_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf/%x_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab
#SBATCH --dependency=afterok:3547301

module load samtools

# =============================
# Path to reference and samples list
# =============================
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
SAMPLES_LIST="samples2.txt"

# Master output table
MERGED_TSV="all_samples_variant_counts.tsv"
echo -e "Sample\tnorm\tnorm.PASS\tnorm.PASS.ADgt1\tnorm.PASS.ADgt1.snp" > $MERGED_TSV

# =============================
# Loop through each sample
# =============================
while read SAMPLE; do
    echo "🔹 Processing $SAMPLE ..."

    VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}/Forced2"
    VCF_IN="${VCF_DIR}/${SAMPLE}_forced_filtered.vcf.gz"

    # Output file names
    VCF_NORM="${VCF_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.vcf.gz"
    VCF_PASS="${VCF_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.vcf.gz"
    VCF_AD="${VCF_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.vcf.gz"
    VCF_SNP="${VCF_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.vcf.gz"

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

done < $SAMPLES_LIST

echo "🎯 All done! Summary table saved as: $MERGED_TSV"
