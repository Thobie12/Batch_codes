#!/bin/bash
#SBATCH --job-name=ugvc_train
#SBATCH --output=ugvc_train_%j.log
#SBATCH --error=ugvc_train_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --partition=superhimem

# ============================================================
# PATHS
# ============================================================
SIF=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/docker/ugbio_ugvc.sif

SAMPLE=OICRM4CA-07-01-P

OUTDIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/${SAMPLE}
REFDIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/references

REFERENCE=${REFDIR}/Homo_sapiens_assembly38.fasta

# Outputs from run_comparison_pipeline.py → inputs here
INPUT_H5=${OUTDIR}/${SAMPLE}_all.h5
INPUT_INTERVAL=${OUTDIR}/${SAMPLE}_output_interval.bed

# Sample-specific SNP FP BED used as blacklist
BLACKLIST=${OUTDIR}/${SAMPLE}_all_snp_fp.bed

# Runs intervals
RUNS_INTERVALS=${REFDIR}/hg38_runs.conservative.bed

# Annotation intervals
ANNOTATE_LCR=${REFDIR}/LCR-hs38.bed
ANNOTATE_MAP=${REFDIR}/mappability.0.bed
ANNOTATE_EXOME=${REFDIR}/exome.twist.bed

# Output prefix → produces ${SAMPLE}_model.pkl and ${SAMPLE}_model.h5
OUTPUT_PREFIX=${OUTDIR}/${SAMPLE}_model

FLOW_ORDER=TGCA

# ============================================================
# SETUP
# ============================================================
module load picard
module load samtools
module load singularity

mkdir -p ~/bin

if [ ! -f ~/bin/picard ]; then
    cat > ~/bin/picard << 'EOF'
#!/bin/bash
java -jar $picard_dir/picard.jar "$@"
EOF
    chmod +x ~/bin/picard
fi

if [ ! -f ~/bin/uname ]; then
    ln -sf $(which uname) ~/bin/uname
fi

# ============================================================
# VALIDATE INPUTS
# ============================================================
for f in ${INPUT_H5} ${INPUT_INTERVAL} ${REFERENCE} \
         ${BLACKLIST} ${RUNS_INTERVALS} \
         ${ANNOTATE_LCR} ${ANNOTATE_MAP} ${ANNOTATE_EXOME}; do
    if [ ! -f ${f} ]; then
        echo "ERROR: missing required file: ${f}"
        exit 1
    fi
done
echo "All inputs validated."

# ============================================================
# RUN TRAINING PIPELINE
# ============================================================
echo "Running ugvc train models pipeline..."

singularity exec \
    -B /cluster:/cluster \
    --env PATH=$HOME/bin:/opt/conda/envs/genomics.py3/bin:/usr/bin:/bin:$PATH \
    --env picard_dir=$picard_dir \
    ${SIF} \
    /opt/conda/envs/genomics.py3/bin/train_models_pipeline.py \
        --input_file         ${INPUT_H5} \
        --reference          ${REFERENCE} \
        --input_interval     ${INPUT_INTERVAL} \
        --runs_intervals     ${RUNS_INTERVALS} \
        --blacklist          ${BLACKLIST} \
        --flow_order         ${FLOW_ORDER} \
        --annotate_intervals ${ANNOTATE_LCR} \
        --annotate_intervals ${ANNOTATE_MAP} \
        --annotate_intervals ${ANNOTATE_EXOME} \
        --exome_weight             100 \
        --exome_weight_annotation /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/references/exome.twist.bed \
        --output_file_prefix ${OUTPUT_PREFIX} \
        --mutect \
        --evaluate_concordance \
        --ignore_filter_status

echo "Done!"
