#!/bin/bash
#SBATCH --job-name=SRSNV_pipeline
#SBATCH --output=log/SRSNV_pipeline_%j.log
#SBATCH --partition=superhimem
#SBATCH --cpus-per-task=20
#SBATCH --mem=512G
#SBATCH --time=1-00:00:00

module load singularity
module load samtools
module load bedtools

# Set base name & inputs
BASE=$1
CRAM=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${BASE}.cram
CRAM_INDEX=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${BASE}.cram.crai
SORTER_STATS=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Stats_Json/${BASE}.json
REF=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
TRAINING_REGIONS=/cluster/projects/pughlab/references/Ultima/SRSNV/ug_rare_variant_hcr.Homo_sapiens_assembly38.interval_list.gz
TRAINING_REGIONS_INDEX=${TRAINING_REGIONS}.tbi
XGBOOST_PARAMS=/cluster/projects/pughlab/references/Ultima/SRSNV/250628.xgboost_model_params.json
BED=/cluster/projects/pughlab/references/Ultima/SRSNV/wgs_calling_regions.without_encode_blacklist.hg38.bed

# Output directory (all generated files go here)
OUTPUT_ROOT=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/New_Ultima
OUTPUT_DIR=${OUTPUT_ROOT}/${BASE}
mkdir -p "$OUTPUT_DIR"

TP_TRAIN_SET_SIZE=1500000
FP_TRAIN_SET_SIZE=1500000
TP_OVERHEAD=10.0
MAX_VAF_FOR_FP=0.05
MIN_COV_FILTER=20
MAX_COV_FACTOR=2.0
RANDOM_SEED=0
NUM_FOLDS=3
RANDOM_SAMPLE_SIZE=$(( TP_TRAIN_SET_SIZE * 10 ))

# =========================
# Singularity images
# =========================
FEATUREMAP_DOCKER=/cluster/home/t922316uhn/singularity/featuremap_1.0.0_8797fc3.sif
UGBIO_FEATUREMAP_DOCKER=/cluster/home/t922316uhn/singularity/ugbio_featuremap_1.15.0.sif
UGBIO_SRSNV_DOCKER=/cluster/home/t922316uhn/singularity/ugbio_srsnv_1.15.0.sif

# ensure output dir is bind-mounted
BIND_PATHS="/cluster/projects/pughlab/myeloma/external_data,/cluster/projects/pughlab/myeloma/projects,/cluster/tools/data/genomes,/cluster/projects/pughlab/references,/cluster,${OUTPUT_DIR}"

# 1. Compute downsampling rate from sorter stats
TOTAL_ALIGNED_BASES=$(jq -re '.total_aligned_bases // .total_bases // error("missing total_aligned_bases")' "$SORTER_STATS")
DOWNSAMPLING_RATE=$(awk -v num=$RANDOM_SAMPLE_SIZE -v den=$TOTAL_ALIGNED_BASES 'BEGIN{printf "%.12f", num/den}')
echo "Downsampling rate: $DOWNSAMPLING_RATE"

# Mean coverage extraction
MEAN_COVERAGE_FILE=${OUTPUT_DIR}/${BASE}.mean_coverage.txt
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_SRSNV_DOCKER sorter_stats_to_mean_coverage \
  --sorter-stats-json "$SORTER_STATS" \
  --output-file "$MEAN_COVERAGE_FILE"

MEAN_COVERAGE=$(cat "$MEAN_COVERAGE_FILE")
echo "Mean coverage: $MEAN_COVERAGE"
COVERAGE_CEIL=$(printf "%.0f" "$(echo "$MEAN_COVERAGE * $MAX_COV_FACTOR" | bc -l)")
echo "Coverage ceiling: $COVERAGE_CEIL"

# 2. snvfind (raw + random sample)
CRAM_TAGS="tm:Z:A:AQ:AQZ:AZ:Q:QZ:Z,a3:i,rq:f,st:Z:MIXED:MINUS:PLUS:UNDETERMINED,et:Z:MIXED:MINUS:PLUS:UNDETERMINED,MI:Z,DS:i"

RAW_FM_VCF=${OUTPUT_DIR}/${BASE}.raw.featuremap.vcf.gz
RS_FM_VCF=${OUTPUT_DIR}/${BASE}.random_sample.featuremap.vcf.gz

#singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $FEATUREMAP_DOCKER snvfind "$CRAM" "$REF" \
#  -o "$RAW_FM_VCF" \
#  -f "${RS_FM_VCF},${DOWNSAMPLING_RATE}" \
#  -v \
#  -p 5 -L 100 -n -d -Q 20 -r 3 -m 60 -c "$CRAM_TAGS" -b "$BED"

#bcftools index -t "$RAW_FM_VCF"
#bcftools index -t "$RS_FM_VCF"

# 3. Prepare RAW (negative / FP labeling set)
#   a) Restrict to training regions
RAW_TR_VCF=${OUTPUT_DIR}/${BASE}.raw.training_regions.vcf.gz
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $FEATUREMAP_DOCKER true >/dev/null 2>&1
bcftools view "$RAW_FM_VCF" -T "$TRAINING_REGIONS" -Oz -o "$RAW_TR_VCF"
bcftools index -t "$RAW_TR_VCF"

#   b) Filter for non-ATCG nucleotide and Convert to parquet
VCF_IN="$RAW_TR_VCF"
VCF_TMP="${OUTPUT_DIR}/${BASE}.raw.training_regions.clean.vcf.gz"
BAD_POSITIONS="${OUTPUT_DIR}/${BASE}.bad_positions.txt"

echo "Step 1: Finding bad variants with non-ACGT flanking INFO fields"
bcftools query -f '%CHROM\t%POS\t[%INFO/X_NEXT1]\t[%INFO/X_PREV1]\t[%INFO/X_NEXT2]\t[%INFO/X_PREV2]\t[%INFO/X_NEXT3]\t[%INFO/X_PREV3]\n' "$VCF_IN" \
  | awk '{for (i=3;i<=8;i++) if ($i !~ /^[ACGT]$/) {print $1"\t"$2; break}}' \
  > "$BAD_POSITIONS" || true
NUM_BAD=$(wc -l < "$BAD_POSITIONS" || echo 0)
echo "Found $NUM_BAD bad positions"

if [ "$NUM_BAD" -eq 0 ]; then
  echo "No bad positions found; leaving $VCF_IN unchanged"
  # ensure clean file path exists for downstream steps (copy)
  cp -f "$VCF_IN" "$VCF_TMP"
  if [ -f "${VCF_IN}.tbi" ]; then cp -f "${VCF_IN}.tbi" "${VCF_TMP}.tbi"; fi
else
  echo "Step 2: Filtering out bad positions from VCF -> $VCF_TMP"
  bcftools view -T ^"$BAD_POSITIONS" "$VCF_IN" -Oz -o "$VCF_TMP"
  echo "Step 3: Indexing clean VCF"
  bcftools index -t "$VCF_TMP"
fi

# remove temporary file(s)
#rm -f "$BAD_POSITIONS"

#   b) Convert to parquet
RAW_PARQUET=${OUTPUT_DIR}/${BASE}.raw.training_regions.parquet
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
  --input "$VCF_TMP" \
  --output "$RAW_PARQUET" \
  --drop-format GT AD X_TCM

#   c) Filter + label (RAW_VAF <= MAX_VAF_FOR_FP) + downsample to FP_TRAIN_SET_SIZE
RAW_FILTERED=${OUTPUT_DIR}/${BASE}.raw.filtered.parquet
RAW_STATS=${OUTPUT_DIR}/${BASE}.raw.stats.json

singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
  --in  "$RAW_PARQUET" \
  --out "$RAW_FILTERED" \
  --stats "$RAW_STATS" \
  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
  --filter name=low_vaf:field=RAW_VAF:op=le:value=${MAX_VAF_FOR_FP}:type=label \
  --downsample random:${FP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# 4. Prepare RANDOM SAMPLE (positive / TP labeling set)
#   a) Restrict to training regions
RS_TR_VCF=${OUTPUT_DIR}/${BASE}.rs.training_regions.vcf.gz
bcftools view "$RS_FM_VCF" -T "$TRAINING_REGIONS" -Oz -o "$RS_TR_VCF"
bcftools index -t "$RS_TR_VCF"

#   b) Filter for non ATCG nucleotide and Convert to parquet
VCF_IN_TP="$RS_TR_VCF"
VCF_OUT_TP="${OUTPUT_DIR}/${BASE}.rs.training_regions.clean.vcf.gz"
BAD_POSITIONS_TP="${OUTPUT_DIR}/${BASE}.bad_positions_TP.txt"

echo "Step 1: Finding bad variants with non-ACGT flanking INFO fields"
bcftools query -f '%CHROM\t%POS\t[%INFO/X_NEXT1]\t[%INFO/X_PREV1]\t[%INFO/X_NEXT2]\t[%INFO/X_PREV2]\t[%INFO/X_NEXT3]\t[%INFO/X_PREV3]\n' "$VCF_IN_TP" \
  | awk '{for (i=3;i<=8;i++) if ($i !~ /^[ACGT]$/) {print $1"\t"$2; break}}' \
  > "$BAD_POSITIONS_TP" || true
NUM_BAD=$(wc -l < "$BAD_POSITIONS_TP" || echo 0)
echo "Found $NUM_BAD bad positions"

if [ "$NUM_BAD" -eq 0 ]; then
  echo "No bad positions found; copying input VCF to $VCF_OUT_TP"
  cp -f "$VCF_IN_TP" "$VCF_OUT_TP"
  if [ -f "${VCF_IN_TP}.tbi" ]; then cp -f "${VCF_IN_TP}.tbi" "${VCF_OUT_TP}.tbi"; fi
  if [ -f "${VCF_IN_TP}.csi" ]; then cp -f "${VCF_IN_TP}.csi" "${VCF_OUT_TP}.csi"; fi
else
  echo "Step 2: Filtering out bad positions from VCF"
  bcftools view -T ^"$BAD_POSITIONS_TP" "$VCF_IN_TP" -Oz -o "$VCF_OUT_TP"
  echo "Step 3: Indexing clean VCF"
  bcftools index -t "$VCF_OUT_TP"
fi

# remove original VCF and temporary files
rm -f "$VCF_IN_TP" "${VCF_IN_TP}.tbi" "${VCF_IN_TP}.csi" "$BAD_POSITIONS_TP"

RS_PARQUET=${OUTPUT_DIR}/${BASE}.rs.training_regions.parquet
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
  --input "$VCF_OUT_TP" \
  --output "$RS_PARQUET" \
  --drop-format GT AD X_TCM

#   c) Filter + label (REF == ALT) + downsample to TP_TRAIN_SET_SIZE - TP
RS_FILTERED=${OUTPUT_DIR}/${BASE}.rs.filtered.parquet
RS_STATS=${OUTPUT_DIR}/${BASE}.rs.stats.json

singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
  --in  "$RS_PARQUET" \
  --out "$RS_FILTERED" \
  --stats "$RS_STATS" \
  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
  --filter name=ref_eq_alt:field=REF:op=eq:value_field=ALT:type=label \
  --downsample random:${TP_TRAIN_SET_SIZE}:${RANDOM_SEED}

#   d) Filter + negative label (RAW_VAF <= MAX_VAF_FOR_FP) + downsample to TP_TRAIN_SET_SIZE - FP
RS_NEG_FILTERED=${OUTPUT_DIR}/${BASE}.rs_neg.filtered.parquet
RS_NEG_STATS=${OUTPUT_DIR}/${BASE}.rs_neg.stats.json

singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
  --in  "$RS_PARQUET" \
  --out "$RS_NEG_FILTERED" \
  --stats "$RS_NEG_STATS" \
  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
  --filter name=ref_ne_alt:field=REF:op=ne:value_field=ALT:type=label \
  --filter name=low_vaf:field=RAW_VAF:op=le:value=${MAX_VAF_FOR_FP}:type=label \
  --downsample random:${TP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# 5. Train (NUM_FOLDS=3 per ppmSeq template)
FEATURES="REF:ALT:X_PREV1:X_NEXT1:X_PREV2:X_NEXT2:X_PREV3:X_NEXT3:X_HMER_REF:X_HMER_ALT:BCSQ:BCSQCSS:RL:INDEX:REV:SCST:SCED:SMQ_BEFORE:SMQ_AFTER:tm:rq:st:et:EDIST:HAMDIST:HAMDIST_FILT"

# run training, outputs will be placed in OUTPUT_DIR
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $UGBIO_SRSNV_DOCKER srsnv_training \
  --positive "$RS_FILTERED" \
  --negative "$RAW_FILTERED" \
  --stats-positive "$RS_STATS" \
  --stats-negative "$RS_NEG_STATS" \
  --stats-featuremap "$RAW_STATS" \
  --training-regions $TRAINING_REGIONS \
  --k-folds ${NUM_FOLDS} \
  --model-params $XGBOOST_PARAMS \
  --mean-coverage $MEAN_COVERAGE \
  --features $FEATURES \
  --basename "$BASE" \
  --output "$OUTPUT_DIR" \
  --random-seed ${RANDOM_SEED} \
  --verbose

# 6. Inference
mkdir -p "${OUTPUT_DIR}/model_files"
# model files are created in OUTPUT_DIR by srsnv_training; ensure they are present
# Copy (or move) model files into model_files folder in OUTPUT_DIR
cp -f "${OUTPUT_DIR}/${BASE}.model_fold_"* "${OUTPUT_DIR}/model_files/" 2>/dev/null || true
if [ -f "${OUTPUT_DIR}/${BASE}.srsnv_metadata.json" ]; then
  cp -f "${OUTPUT_DIR}/${BASE}.srsnv_metadata.json" "${OUTPUT_DIR}/model_files/srsnv_metadata.json"
fi

# Run snvqual: input RAW featuremap vcf, output into OUTPUT_DIR
QUAL_VCF=${OUTPUT_DIR}/${BASE}.featuremap.vcf.gz
singularity exec --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS $FEATUREMAP_DOCKER snvqual "$RAW_FM_VCF" "$QUAL_VCF" "${OUTPUT_DIR}/model_files/srsnv_metadata.json" -v
bcftools index -t "$QUAL_VCF"

#singularity exec --cleanenv --home /tmp --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
#singularity exec  --home /cluster/home/t922316uhn:/home/ugbio --bind $BIND_PATHS /cluster/home/t922316uhn/singularity/ugbio_featuremap_1.15.0.sif  featuremap_to_dataframe \
#  --input $OUTPUT_DIR/${BASE}.featuremap.vcf.gz \
#  --output $OUTPUT_DIR/${BASE}.featuremap_df.parquet

# 7. Report
FEATUREMAP_DF=${OUTPUT_DIR}/${BASE}.featuremap_df.parquet
# srsnv_report expects featuremap_df and srsnv metadata in model_files
singularity exec --cleanenv --home /tmp --bind $BIND_PATHS $UGBIO_SRSNV_DOCKER srsnv_report \
  --featuremap-df "$FEATUREMAP_DF" \
  --srsnv-metadata "${OUTPUT_DIR}/model_files/srsnv_metadata.json" \
  --report-path "$OUTPUT_DIR" \
  --basename "${BASE}" \
  --verbose

echo "All outputs are in: $OUTPUT_DIR"
