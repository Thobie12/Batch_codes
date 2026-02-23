#!/bin/bash
#SBATCH --job-name=mutect2_and_merge_stats
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2CA-07_chr_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA-07_chr_%A_%a.err
#SBATCH --time=5-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=pughlab
#SBATCH --array=1-24%6  # chr1..22, X, Y, max 6 running at once

module load gatk
module load samtools

SAMPLE="OICRM4CA-08-01-P"
#NORMAL_DIR="/cluster/projects/pughlab/myeloma/projects/MyC/All_TFRIM4_bamlinks/TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.filter.deduped.recalibrated.bam"
#NORMAL_DIR="/cluster/projects/pughlab/myeloma/external_data/Unarchiving_cfWGS/Toby_All_bams_TFRIM4_batch2A/TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.filter.deduped.recalibrated.bam"
NORMAL_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam/TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.realigned.merged.bam"
NORMAL="TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.filter.deduped.recalibrated"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"
mkdir -p "${VCF_DIR}/Merged"
# Reference + interval lists
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

# --- Step 1: Run Mutect2 per chromosome ---
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Running Mutect2 on $CHR for sample $SAMPLE"

    gatk Mutect2 \
      -R "$REFERENCE" \
      -I /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram \
      -I $NORMAL_DIR \
      -tumor $SAMPLE \
      -normal $NORMAL \
      -L $CHR \
      --germline-resource /cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz \
      --exclude-intervals "$REPEAT_MASKER" \
      --exclude-intervals "$ENCODE_BLACKLIST" \
      --native-pair-hmm-threads 8 \
      -O ${VCF_DIR}/Merged/${SAMPLE}_${CHR}.vcf.gz \
      --f1r2-tar-gz ${VCF_DIR}/Merged/${SAMPLE}_${CHR}_f1r2.tar.gz

    exit 0
fi
