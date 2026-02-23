#!/bin/bash
#SBATCH --job-name=mutect2_and_merge_stats
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2CA_Test_chr_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA_Test_chr_%A_%a.err
#SBATCH --time=5-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=pughlab
#SBATCH --array=1-20%5    # chr1..22, X, Y, max 4 running at once

module load gatk
module load samtools

SAMPLE="OICRM4CA-07-01-P"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
#CHRS=(chr21 chr22 chrX chrY)

CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

# --- Step 1: Run Mutect2 per chromosome ---
#if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
#    echo "Running Mutect2 on $CHR for sample $SAMPLE"
#    gatk Mutect2 \
#      -R /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta \
#      -I /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram \
#      -tumor $SAMPLE \
#      -L $CHR \
#      --panel-of-normals /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/1000g_pon.hg38.vcf.gz \
#      --germline-resource /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/af-only-gnomad.hg38.vcf.gz \
#      --native-pair-hmm-threads 8 \
#      -O ${VCF_DIR}/${SAMPLE}_${CHR}.vcf.gz \
#      --f1r2-tar-gz ${VCF_DIR}/${SAMPLE}_${CHR}_f1r2.tar.gz
#    exit 0
#fi

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Running Mutect2 on $CHR for sample $SAMPLE"

    gatk Mutect2 \
      -R /cluster/projects/pughlab/references/TGL/hg38/hg38_random.fa \
      -I /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram \
      -tumor $SAMPLE \
      -L $CHR \
      --exclude-intervals /cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/30XWGS_Feb2023/STR_regions/unzipped/hg38_repeatmasker.bed \
      --exclude-intervals /cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/30XWGS_Feb2023/Output_OICR_blood_as_tumor/merged_vcfs/unzipped/vaf_above_0.01/encode_blacklist_removed/hg38-blacklist.v2.bed \
      --panel-of-normals /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/1000g_pon.hg38.vcf.gz \
      --germline-resource /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/af-only-gnomad.hg38.vcf.gz \
      --native-pair-hmm-threads 8 \
      -O ${VCF_DIR}/${SAMPLE}_${CHR}.vcf.gz \
      --f1r2-tar-gz ${VCF_DIR}/${SAMPLE}_${CHR}_f1r2.tar.gz

    exit 0
fi

# --- Step 2: Merge VCFs and stats after array jobs ---
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Starting merge for sample $SAMPLE"
    cd "$VCF_DIR" || { echo "Failed to cd to $VCF_DIR"; exit 1; }

    # Merge VCFs
    VCF_LIST=""
    for chr in "${CHRS[@]}"; do
        VCF_LIST+=" -I ${SAMPLE}_${chr}.vcf.gz"
    done

    echo "Merging VCFs..."
    gatk MergeVcfs $VCF_LIST -O ${VCF_DIR}/${SAMPLE}_all.vcf.gz

    # Merge stats files using GATK
    COMBINED_STATS="${VCF_DIR}/${SAMPLE}_all.vcf.gz.stats"
    echo "Merging Mutect2 stats for sample $SAMPLE..."
    gatk MergeMutectStats \
        $(ls ${SAMPLE}_*.vcf.gz.stats | sed "s/^/-stats /") \
        -O "$COMBINED_STATS"

    echo "VCF and stats merge complete for $SAMPLE"
    exit 0
fi
