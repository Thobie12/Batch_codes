#!/bin/bash
#SBATCH --job-name=ugvc_comparison
#SBATCH --output=ugvc_comparison_%j.log
#SBATCH --error=ugvc_comparison_%j.err
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
TRUTH_SAMPLE=TFRIM4_0057_Bm_P_CA-07-01-O-DNA

OUTDIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/${SAMPLE}
REFDIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/references

#INPUT_PREFIX=${OUTDIR}/${SAMPLE}_all
INPUT_PREFIX=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/UGVC/OICRM4CA-07-01-P_diploidOnly
#INPUT_PREFIX=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/OICRM4CA-07-01-P/OICRM4CA-07-01-P_diploidOnly
OUTPUT_FILE=${OUTDIR}/${SAMPLE}_all.h5
OUTPUT_INTERVAL=${OUTDIR}/${SAMPLE}_output_interval.bed

HIGHCONF_INTERVALS=/cluster/projects/pughlab/references/Ultima/SRSNV/ug_hcr.bed
REFERENCE=${REFDIR}/Homo_sapiens_assembly38.fasta
REFERENCE_DICT=${REFDIR}/Homo_sapiens_assembly38.dict

# Pre-fixed truth VCF (diploid GTs, bgzipped, tabix-indexed)
GTR_VCF=${OUTDIR}/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.truth.diploid.vcf.gz
#GTR_VCF=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK_Tumour/OICRM4CA-07-01-P/TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.truth.diploid.nochrM.vcf.gz

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
for f in ${GTR_VCF} ${GTR_VCF}.tbi ${REFDIR}/Homo_sapiens_assembly38.fasta.sdf/mainIndex; do
    if [ ! -f ${f} ]; then
        echo "ERROR: missing required file: ${f}"
        exit 1
    fi
done
echo "All inputs validated."

# ============================================================
# CLEAN STALE INTERMEDIATE FILES
# ============================================================
rm -f ${OUTDIR}/*.intsct*
rm -rf ${OUTDIR}/*.vcfeval_output

# ============================================================
# RUN COMPARISON PIPELINE
# ============================================================
echo "Running ugvc comparison pipeline..."
singularity exec \
    -B /cluster:/cluster \
    --env PATH=$HOME/bin:/opt/conda/envs/genomics.py3/bin:/usr/bin:/bin:$PATH \
    --env picard_dir=$picard_dir \
    ${SIF} \
    /opt/conda/envs/genomics.py3/bin/run_comparison_pipeline.py \
        --n_parts            0 \
        --input_prefix       ${INPUT_PREFIX} \
        --output_file        ${OUTPUT_FILE} \
        --output_interval    ${OUTPUT_INTERVAL} \
        --highconf_intervals ${HIGHCONF_INTERVALS} \
        --reference          ${REFERENCE} \
        --reference_dict     ${REFERENCE_DICT} \
        --gtr_vcf            ${GTR_VCF} \
        --call_sample_name   M4-CA-07-01-P-DNA \
        --truth_sample_name  ${TRUTH_SAMPLE} \
        --is_mutect \
        --ignore_filter_status \
        --scoring_field       TLOD \
        --n_jobs             8

echo "Done!"
