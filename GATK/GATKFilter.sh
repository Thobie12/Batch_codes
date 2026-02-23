#!/bin/bash
#SBATCH --job-name=mutect2_filter
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_filter_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_filter_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem

module load gatk
module load samtools

# ----------------------------
# Sample-specific variables
# ----------------------------

#SAMPLE="ALQ_0004_02_LB01-ppm0033-CAACATCAGCATGAGAT_merged"
#SAMPLE="ALQ_0005_03_LB01-ppm0039-CATAGAGCCTCAGAT_merged"
#SAMPLE="ALQ_0010_01_LB01-ppm0035-CAGCACCTGCATCAGAT_merged"
#SAMPLE="ALQ_0011_01_LB01-ppm0036-CTTATGCTATCAGAT_merged"
#SAMPLE="ALQ_0012_01_LB01-ppm0037-CATCTCAGTGCAATGAT_merged"
#SAMPLE="ALQ_0013_01_LB01-ppm0038-CACAGTCAATGTGAT_merged"
#SAMPLE="ALQ_0014_01_LB01-ppm0034-CTGCAGTGATTCATGAT_merged"

SAMPLE="OICRM4CA-07-01-P"
REF="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/${SAMPLE}"

#VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/ALQ_OICR/GATK/${SAMPLE}"
MERGED_VCF="${VCF_DIR}/${SAMPLE}_all.vcf.gz"
MERGED_STATS="${VCF_DIR}/${SAMPLE}_all.vcf.gz.stats"
FILTERED_VCF="${VCF_DIR}/${SAMPLE}_filtered.vcf.gz"

# ==============================
# Filter Mutect Calls
# ==============================
echo "[$(date)] Step : Running FilterMutectCalls for $SAMPLE"

gatk --java-options "-Xmx16g" FilterMutectCalls \
    -R "$REF" \
    -V "$MERGED_VCF" \
    --stats "$MERGED_STATS" \
    -O "$FILTERED_VCF"
