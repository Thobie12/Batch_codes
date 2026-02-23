#!/bin/bash
#SBATCH --job-name=mutect2_and_merge_stats
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=pughlab
#SBATCH --array=1-24%24  # chr1..22, X, Y

module load gatk
module load samtools

# --- User-configurable variables ---
SAMPLE="OICRM4FZ-08-01-P"  # tumor sample
NORMAL_BAM="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam/TFRIM4_0059_Pb_R_WG_FZ-08-01-B-DNA.realigned.merged.bam"

# Automatically extract normal sample name from BAM header
NORMAL=$(samtools view -H "$NORMAL_BAM" | grep '@RG' | head -n1 | sed 's/.*SM:\([^[:space:]]*\).*/\1/')

# Tumor BAM path
SAMPLE_BAM="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram"

# Output directory (create /Merged if it doesn't exist)
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}/Merged"
if [ ! -d "$VCF_DIR" ]; then
    echo "Creating output directory: $VCF_DIR"
    mkdir -p "$VCF_DIR"
fi

# Reference + intervals
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

# --- Safety checks ---
if [ ! -f "$SAMPLE_BAM" ]; then
    echo "Error: Tumor BAM/CRAM not found: $SAMPLE_BAM"
    exit 1
fi

if [ ! -f "$NORMAL_BAM" ]; then
    echo "Error: Normal BAM not found: $NORMAL_BAM"
    exit 1
fi

if [ -z "$NORMAL" ]; then
    echo "Error: Could not detect normal sample name from BAM header"
    exit 1
fi

echo "Running Mutect2 on $CHR for tumor=$SAMPLE, normal=$NORMAL"
echo "Output directory: $VCF_DIR"

# --- Run Mutect2 ---
gatk Mutect2 \
  -R "$REFERENCE" \
  -I "$SAMPLE_BAM" \
  -I "$NORMAL_BAM" \
  -tumor "$SAMPLE" \
  -normal "$NORMAL" \
  -L "$CHR" \
  --germline-resource /cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz \
  --exclude-intervals "$REPEAT_MASKER" \
  --exclude-intervals "$ENCODE_BLACKLIST" \
  --native-pair-hmm-threads 8 \
  -O "${VCF_DIR}/${SAMPLE}_${CHR}.vcf.gz" \
  --f1r2-tar-gz "${VCF_DIR}/${SAMPLE}_${CHR}_f1r2.tar.gz"

echo "Mutect2 done for $CHR"
