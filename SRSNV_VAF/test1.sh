#!/bin/bash
#SBATCH --job-name=srsnv_training
#SBATCH --output=%x_%j.log
#SBATCH --error=%x_%j.err
#SBATCH --partition=superhimem
#SBATCH --cpus-per-task=8
#SBATCH --mem=124G
#SBATCH --time=24:00:00


module load samtools
module load singularity
module load tabix
module load bedtools
set -euo pipefail

# --------------------------
# User-defined variables
# --------------------------
BASE=test
CRAM="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/testdata/Pa_46.333_LuNgs_08.Lb_744.chr20.cram"
CRAM_INDEX="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/testdata/Pa_46.333_LuNgs_08.Lb_744.chr20.cram.crai"
SORTER_STATS="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/testdata/Pa_46.333_LuNgs_08.Lb_744.json"
REF="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
TRAINING_REGIONS="/cluster/projects/pughlab/references/Ultima/SRSNV/ug_rare_variant_hcr.Homo_sapiens_assembly38.interval_list.gz"
XGBOOST_PARAMS="/cluster/projects/pughlab/references/Ultima/SRSNV/250628.xgboost_model_params.json"
BED="/cluster/projects/pughlab/references/Ultima/SRSNV/wgs_calling_regions.without_encode_blacklist.hg38.bed"
OUTPUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/$BASE"
mkdir -p "$OUTPUT_DIR"

FEATUREMAP_DOCKER="/cluster/home/t922316uhn/singularity/featuremap_1.0.0_8797fc3.sif"
UGBIO_SRSNV_DOCKER="/cluster/home/t922316uhn/singularity/ugbio_srsnv_1.15.0.sif"
BIND_PATHS="/cluster/projects/pughlab/myeloma/external_data,/cluster/projects/pughlab/myeloma/projects,/cluster/tools/data/genomes,/cluster/projects/pughlab/references,/cluster"

# --------------------------
# Training parameters
# --------------------------
TP_TRAIN_SET_SIZE=1500000
FP_TRAIN_SET_SIZE=1500000
TP_OVERHEAD=10.0
MAX_VAF_FOR_FP=0.05
MIN_COV_FILTER=20
MAX_COV_FACTOR=2.0
RANDOM_SEED=0
NUM_FOLDS=3
RANDOM_SAMPLE_SIZE=$(( TP_TRAIN_SET_SIZE * 10 ))

# --------------------------
# Compute downsampling rate & coverage ceiling
# --------------------------
TOTAL_ALIGNED_BASES=$(jq -re '.total_aligned_bases // .total_bases // error("missing total_aligned_bases")' "$SORTER_STATS")
DOWNSAMPLING_RATE=$(awk -v num=$RANDOM_SAMPLE_SIZE -v den=$TOTAL_ALIGNED_BASES 'BEGIN{printf "%.12f", num/den}')
echo "Downsampling rate: $DOWNSAMPLING_RATE"

MEAN_COVERAGE=$(jq -re '.mean_coverage // empty' "$SORTER_STATS")
if [ -n "$MEAN_COVERAGE" ]; then
  COVERAGE_CEIL=$(awk -v m=$MEAN_COVERAGE -v f=$MAX_COV_FACTOR 'BEGIN{c=m*f; printf "%d", (c==int(c)?c:int(c)+1)}')
else
  COVERAGE_CEIL=$(( MIN_COV_FILTER * 30 ))
fi
echo "Coverage ceiling: $COVERAGE_CEIL"

# --------------------------
# 1. FeatureMap (raw + random sample) using FEATUREMAP_DOCKER (Singularity)
# --------------------------
#singularity exec --bind "$BIND_PATHS" "$FEATUREMAP_DOCKER" snvfind "$CRAM" "$REF" \
#  -o "${OUTPUT_DIR}/${BASE}.raw.featuremap.vcf.gz" \
#  -f "${OUTPUT_DIR}/${BASE}.random_sample.featuremap.vcf.gz,${DOWNSAMPLING_RATE}" \
#  -v \
#  -p 5 -L 100 -n -d -Q 20 -r 3 -m 60 \
#  -c "tm:Z:A:AQ:AQZ:AZ:Q:QZ:Z,a3:i,rq:f,st:Z:MIXED:MINUS:PLUS:UNDETERMINED,et:Z:MIXED:MINUS:PLUS:UNDETERMINED,MI:Z,DS:i" \
#  -b "$BED"

#bcftools index -t "${OUTPUT_DIR}/${BASE}.raw.featuremap.vcf.gz"
#bcftools index -t "${OUTPUT_DIR}/${BASE}.random_sample.featuremap.vcf.gz"

# --------------------------
# 2. Prepare RAW (negative) using ugbio_env Conda environment
# --------------------------
# Activate Conda env
#source ~/miniconda3/etc/profile.d/conda.sh
#conda activate ugbio_env

bcftools view "${OUTPUT_DIR}/${BASE}.raw.featuremap.vcf.gz" -T "$TRAINING_REGIONS" -Oz -o "${OUTPUT_DIR}/${BASE}.raw.training_regions.vcf.gz"
bcftools index -t "${OUTPUT_DIR}/${BASE}.raw.training_regions.vcf.gz"

# Convert VCF -> DataFrame
featuremap_to_dataframe \
  --input "${OUTPUT_DIR}/${BASE}.raw.training_regions.vcf.gz" \
  --output "${OUTPUT_DIR}/${BASE}.raw.training_regions.parquet" \
  --drop-format GT AD

# Filter featuremap
filter_featuremap \
  --in  "${OUTPUT_DIR}/${BASE}.raw.training_regions.parquet" \
  --out "${OUTPUT_DIR}/${BASE}.raw.filtered.parquet" \
  --stats "${OUTPUT_DIR}/${BASE}.raw.stats.json" \
  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
  --filter name=vaf_le_threshold:field=RAW_VAF:op=le:value=${MAX_VAF_FOR_FP}:type=label \
  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
  --downsample random:${FP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# --------------------------
# 3. Prepare RANDOM SAMPLE (positive) using ugbio_env Conda environment
# --------------------------
bcftools view "${OUTPUT_DIR}/${BASE}.random_sample.featuremap.vcf.gz" -T "$TRAINING_REGIONS" -Oz -o "${OUTPUT_DIR}/${BASE}.rs.training_regions.vcf.gz"
bcftools index -t "${OUTPUT_DIR}/${BASE}.rs.training_regions.vcf.gz"

featuremap_to_dataframe \
  --input "${OUTPUT_DIR}/${BASE}.rs.training_regions.vcf.gz" \
  --output "${OUTPUT_DIR}/${BASE}.rs.training_regions.parquet" \
  --drop-format GT AD

filter_featuremap \
  --in  "${OUTPUT_DIR}/${BASE}.rs.training_regions.parquet" \
  --out "${OUTPUT_DIR}/${BASE}.rs.filtered.parquet" \
  --stats "${OUTPUT_DIR}/${BASE}.rs.stats.json" \
  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
  --filter name=ref_eq_alt:field=REF:op=eq:value_field=ALT:type=label \
  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
  --downsample random:${TP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# Deactivate Conda env
conda deactivate

# --------------------------
# 4. Train SRSNV using UGBIO_SRSNV_DOCKER (Singularity)
# --------------------------
FEATURES="REF:ALT:X_PREV1:X_NEXT1:X_PREV2:X_NEXT2:X_PREV3:X_NEXT3:X_HMER_REF:X_HMER_ALT:BCSQ:BCSQCSS:RL:INDEX:REV:SCST:SCED:SMQ_BEFORE:SMQ_AFTER:tm:rq:st:et:EDIST:HAMDIST:HAMDIST_FILT"

singularity exec --bind "$BIND_PATHS" "$UGBIO_SRSNV_DOCKER" srsnv_training \
  --positive "${OUTPUT_DIR}/${BASE}.rs.filtered.parquet" \
  --negative "${OUTPUT_DIR}/${BASE}.raw.filtered.parquet" \
  --stats-positive "${OUTPUT_DIR}/${BASE}.rs.stats.json" \
  --stats-negative "${OUTPUT_DIR}/${BASE}.raw.stats.json" \
  --training-regions "$TRAINING_REGIONS" \
  --k-folds ${NUM_FOLDS} \
  --model-params "$XGBOOST_PARAMS" \
  --features "$FEATURES" \
  --basename "$BASE" \
  --output "$OUTPUT_DIR" \
  --random-seed ${RANDOM_SEED} \
  --verbose

# --------------------------
# 5. Inference & Report using UGBIO_SRSNV_DOCKER (Singularity)
# --------------------------
mkdir -p "${OUTPUT_DIR}/model_files"
cp "${OUTPUT_DIR}/${BASE}.model_fold_*.json" "${OUTPUT_DIR}/model_files/"
cp "${OUTPUT_DIR}/${BASE}.srsnv_metadata.json" "${OUTPUT_DIR}/model_files/srsnv_metadata.json"

singularity exec --bind "$BIND_PATHS" "$UGBIO_SRSNV_DOCKER" snvqual \
  "${OUTPUT_DIR}/${BASE}.raw.featuremap.vcf.gz" \
  "${OUTPUT_DIR}/${BASE}.featuremap.vcf.gz" \
  "${OUTPUT_DIR}/model_files/srsnv_metadata.json" -v

bcftools index -t "${OUTPUT_DIR}/${BASE}.featuremap.vcf.gz"

singularity exec --bind "$BIND_PATHS" "$UGBIO_SRSNV_DOCKER" srsnv_report \
  --featuremap-df "${OUTPUT_DIR}/${BASE}.featuremap_df.parquet" \
  --srsnv-metadata "${OUTPUT_DIR}/model_files/srsnv_metadata.json" \
  --report-path "$OUTPUT_DIR" \
  --basename "$BASE" \
  --verbose
