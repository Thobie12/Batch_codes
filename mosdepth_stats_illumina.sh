#!/bin/bash
#SBATCH --job-name=mosdepth_array
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS/mosdepth_%A_%a.out
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS/mosdepth_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem

 # 2 samples

# Paths
MOSDEPTH=/cluster/home/t922316uhn/mosdepth/mosdepth
#BAM_DIR=/cluster/projects/myelomagroup/external_data/TFRIM4_231017/All_bams_batch_1A_TFRIM4
#BAM_DIR=/cluster/projects/pughlab/myeloma/external_data/Unarchiving_cfWGS
BAM_DIR=/cluster/projects/pughlab/Archiving/
REF=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
OUT_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS
SAMPLES_FILE=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/samples_illumina.txt

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Get the sample file for this array task
SAMPLE=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" "$SAMPLES_FILE")
BAM="$BAM_DIR/$SAMPLE"
PREFIX=$(basename "$BAM" .bam)

echo "Processing $BAM ..."

# Run mosdepth
$MOSDEPTH \
    -t 8 \
    -f $REF \
    "$OUT_DIR/$PREFIX" \
    "$BAM"

# Print mean coverage from the summary
SUMMARY_FILE="${OUT_DIR}/${PREFIX}.mosdepth.summary.txt"
if [[ -f "$SUMMARY_FILE" ]]; then
    echo "Mean coverage for $BAM:"
    awk 'NR==2 {print "Mean depth:", $3}' "$SUMMARY_FILE"
else
    echo "Summary file not found for $BAM"
fi
