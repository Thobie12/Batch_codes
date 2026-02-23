#!/bin/bash
#SBATCH --job-name=mosdepth_array
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS/mosdepth_%A_%a.out
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS/mosdepth_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem
#SBATCH --array=0-8   # 9 samples

# Paths
MOSDEPTH=/cluster/home/t922316uhn/mosdepth/mosdepth
CRAM_DIR=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams
REF=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
OUT_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/STATS

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Get the list of CRAMs
CRAMS=($CRAM_DIR/*.cram)
CRAM=${CRAMS[$SLURM_ARRAY_TASK_ID]}
PREFIX=$(basename "$CRAM" .cram)

echo "Processing $CRAM ..."

# Run mosdepth
$MOSDEPTH \
    -t 8 \
    -f $REF \
    "$OUT_DIR/$PREFIX" \
    "$CRAM"

# Print mean coverage from the summary
SUMMARY_FILE="${OUT_DIR}/${PREFIX}.mosdepth.summary.txt"
if [[ -f "$SUMMARY_FILE" ]]; then
    echo "Mean coverage for $CRAM:"
    awk 'NR==2 {print "Mean depth:", $3}' "$SUMMARY_FILE"
else
    echo "Summary file not found for $CRAM"
fi
