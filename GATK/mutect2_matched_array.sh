#!/bin/bash
#SBATCH --job-name=mutect2_array
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA-07_chr_%A_%a.err
#SBATCH --time=5-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=pughlab
#SBATCH --array=1-24%6   # chr1..22, X, Y, max 6 running at once

module load gatk
module load samtools

# ------------------------------
# Tumor + Normal definitions
# ------------------------------
# File-based names
TUMOR_FILE="OICRM4CA-07-01-P.cram"
NORMAL_FILE="TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.filter.deduped.recalibrated.bam"

# SM tags from BAM/CRAM headers
SAMPLE="M4-CA-07-01-P-DNA"
NORMAL="TFRIM4_0057_Pb_R_CA-07-03-B-DNA"

# Directories
TUMOR_DIR="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams"
NORMAL_DIR="/cluster/projects/pughlab/myeloma/external_data/Unarchiving_cfWGS/Toby_All_bams_TFRIM4_batch2A"

# Full paths
TUMOR_PATH="${TUMOR_DIR}/${TUMOR_FILE}"
NORMAL_PATH="${NORMAL_DIR}/${NORMAL_FILE}"

# Output directory
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"
mkdir -p "${VCF_DIR}/Merged"

# Reference + intervals
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

# Chromosomes
CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

echo "Running Mutect2 on $CHR for tumor $SAMPLE vs normal $NORMAL"

gatk Mutect2 \
  -R "$REFERENCE" \
  -I "$TUMOR_PATH" \
  -I "$NORMAL_PATH" \
  -tumor "$SAMPLE" \
  -normal "$NORMAL" \
  -L "$CHR" \
  --germline-resource /cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz \
  --exclude-intervals "$REPEAT_MASKER" \
  --exclude-intervals "$ENCODE_BLACKLIST" \
  --native-pair-hmm-threads 8 \
  -O ${VCF_DIR}/Merged/${SAMPLE}_${CHR}.vcf.gz \
  --f1r2-tar-gz ${VCF_DIR}/Merged/${SAMPLE}_${CHR}_f1r2.tar.gz
