#!/bin/bash
#SBATCH --job-name=draw_agcn
#SBATCH --output=/cluster/home/t922316uhn/PLO/draw_agcn_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/draw_agcn_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

# Load modules if needed
module load R

# Set script and input/output
#SCRIPT=/cluster/home/t922316uhn/parascopy/parascopy/draw/draw_plots.sh
SCRIPT=/cluster/home/t922316uhn/parascopy/parascopy/draw/draw_cn.r
INPUT_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/
MODE=pscn

# Optional: customize subdir filtering, threads, and output dir
REGEX="CA-07"
THREADS=4
OUTPUT_DIR=""  # leave empty to use default inside input/plots/

# Extra arguments to agcn.r or pscn.r (these go after --)
EXTRA_ARGS="--samples CA-07"

# Final run command
bash "$SCRIPT" \
    -i "$INPUT_DIR" \
    -m "$MODE" \
    -r "$REGEX" \
    -@ "$THREADS" \
    ${OUTPUT_DIR:+-o "$OUTPUT_DIR"} \
    -- $EXTRA_ARGS
