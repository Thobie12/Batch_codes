#!/bin/bash
#SBATCH --job-name=vcf_filter_all
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/vcf_filter_%A_%a.log
#SBATCH --time=01:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=16
#SBATCH --partition=superhimem
#SBATCH --array=1%1  # adjust max array tasks to your number of samples

# --- Load modules ---
module load gatk
module load samtools

# --- Variables ---
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
SAMPLE_LIST="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/GATK/samples.txt"
INPUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/all_vcfs/Tobi/Filtered"
OUTPUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/all_vcfs/Tobi/Filtered_Blacklist"
REPEAT_MASKER="/cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/30XWGS_Feb2023/STR_regions/unzipped/hg38_repeatmasker.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/myeloma/projects/M4/Mutect2/Mutect2_Dory/30XWGS_Feb2023/Output_OICR_blood_as_tumor/merged_vcfs/unzipped/vaf_above_0.01/encode_blacklist_removed/hg38-blacklist.v2.bed"
#REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
#ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"

# --- Get sample for this array task ---
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")
echo "Filtering sample: $SAMPLE"

INPUT_VCF="${INPUT_DIR}/${SAMPLE}_filtered_final.sorted_AD1.vcf.gz"
OUTPUT_VCF="${OUTPUT_DIR}/${SAMPLE}_filtered_final.sorted_AD1_repeatmask_encode.vcf.gz"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# --- Run GATK SelectVariants with exclude-intervals ---
gatk SelectVariants \
    -R "$REFERENCE" \
    -V "$INPUT_VCF" \
    --exclude-intervals "$REPEAT_MASKER" \
    --exclude-intervals "$ENCODE_BLACKLIST" \
    -O "$OUTPUT_VCF" \
    --create-output-variant-index true

echo "Filtering complete for $SAMPLE! Output: $OUTPUT_VCF"
