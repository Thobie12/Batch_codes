#!/bin/bash
#SBATCH --job-name=mutect2_tumor_only
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2CA_TumorOnly_chr_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA_TumorOnly_chr_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem
#SBATCH --array=1-24    # chr1..22, X, Y, max 4 running at once

module load gatk
module load samtools

#SAMPLE="423901-CFTMT_0001_3_B1-ppm0089-CATGCAGATGGCGAGAT"
#SAMPLE="423901-CFTMT_0003_1_E1-ppm0090-CTTCATGCATCTCAGAT"
#SAMPLE="423901-CFTMT_0004_3_H1-ppm0091-CATGCAAGTGTGATGAT"
SAMPLE="OICRM4CA-07-01-P"

# UPDATED: Output directory now GATK_Tumour
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/${SAMPLE}"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)

CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

# --- Run Mutect2 Tumor-Only per chromosome ---
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Running Mutect2 (Tumor Only) on $CHR for sample $SAMPLE"
    mkdir -p "$VCF_DIR"
    
    gatk Mutect2 \
      -R /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta \
      -I /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram \
      -tumor $SAMPLE \
      -L $CHR \
      --exclude-intervals $REPEAT_MASKER \
      --exclude-intervals $ENCODE_BLACKLIST \
      --germline-resource /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/af-only-gnomad.hg38.vcf.gz \
      --native-pair-hmm-threads 8 \
      -O ${VCF_DIR}/${SAMPLE}_${CHR}.vcf.gz \
      --f1r2-tar-gz ${VCF_DIR}/${SAMPLE}_${CHR}_f1r2.tar.gz

    exit 0
fi
