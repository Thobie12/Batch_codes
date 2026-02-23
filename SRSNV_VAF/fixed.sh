#!/bin/bash
#SBATCH --job-name=SRSNV_pipeline
#SBATCH --output=SRSNV_pipeline_%j.log
#SBATCH --partition=superhimem
#SBATCH --cpus-per-task=24
#SBATCH --mem=512G
#SBATCH --time=1-00:00:00

module load singularity
module load samtools


# =========================
# Resources
# =========================
CPUS=$SLURM_CPUS_PER_TASK

# =========================
# Input variables
# =========================
BASE=OICRM4CA-07-01-P
CRAM=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${BASE}.cram
CRAM_INDEX=/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${BASE}.cram.crai
SORTER_STATS=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Stats_Json/${BASE}.json
REF=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
TRAINING_REGIONS=/cluster/projects/pughlab/references/Ultima/SRSNV/ug_rare_variant_hcr.Homo_sapiens_assembly38.interval_list.gz
XGBOOST_PARAMS=/cluster/projects/pughlab/references/Ultima/SRSNV/250628.xgboost_model_params.json
BED=/cluster/projects/pughlab/references/Ultima/SRSNV/wgs_calling_regions.without_encode_blacklist.hg38.bed

TP_TRAIN_SET_SIZE=3000000
FP_TRAIN_SET_SIZE=3000000
TP_OVERHEAD=10.0
MAX_VAF_FOR_FP=0.05
MIN_COV_FILTER=20
MAX_COV_FACTOR=2.0
RANDOM_SEED=0
NUM_FOLDS=5
RANDOM_SAMPLE_SIZE=$(( TP_TRAIN_SET_SIZE * 10 ))

# =========================
# Singularity images
# =========================
FEATUREMAP_DOCKER=/cluster/home/t922316uhn/singularity/featuremap_1.0.0_8797fc3.sif
#/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/docker/featuremap_1.0.0_8797fc3.sif
#UGBIO_FEATUREMAP_DOCKER=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/docker/ugbio_featuremap_1.15.0.sif
UGBIO_FEATUREMAP_DOCKER=/cluster/home/t922316uhn/singularity/ugbio_featuremap_1.15.0.sif
UGBIO_SRSNV_DOCKER=/cluster/home/t922316uhn/singularity/ugbio_srsnv_1.15.0.sif
BIND_PATHS="/cluster/projects/pughlab/myeloma/external_data,/cluster/projects/pughlab/myeloma/projects,/cluster/tools/data/genomes,/cluster/projects/pughlab/references,/cluster"

# =========================
# Output directory
# =========================
OUTPUT_DIR=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/Update/$BASE
mkdir -p $OUTPUT_DIR

# =========================
# Compute downsampling rate
# =========================
TOTAL_ALIGNED_BASES=$(jq -re '.total_aligned_bases // .total_bases // error("missing total_aligned_bases")' "$SORTER_STATS")
DOWNSAMPLING_RATE=$(awk -v num=$RANDOM_SAMPLE_SIZE -v den=$TOTAL_ALIGNED_BASES 'BEGIN{printf "%.12f", num/den}')
echo "Downsampling rate: $DOWNSAMPLING_RATE"

# run inside ugbio_srsnv docker
MEAN_COVERAGE_FILE=${BASE}.mean_coverage.txt
singularity exec --bind $BIND_PATHS $UGBIO_SRSNV_DOCKER sorter_stats_to_mean_coverage \
  --sorter-stats-json "$SORTER_STATS" \
  --output-file "$MEAN_COVERAGE_FILE"

MEAN_COVERAGE=$(cat "$MEAN_COVERAGE_FILE")
echo "Mean coverage: $MEAN_COVERAGE"
COVERAGE_CEIL=$(printf "%.0f" "$(echo "$MEAN_COVERAGE * $MAX_COV_FACTOR" | bc -l)")
echo "Coverage ceiling: $COVERAGE_CEIL"
# =========================
# Step 2: snvfind
# =========================
CRAM_TAGS="tm:Z:A:AQ:AQZ:AZ:Q:QZ:Z,a3:i,rq:f,st:Z:MIXED:MINUS:PLUS:UNDETERMINED,et:Z:MIXED:MINUS:PLUS:UNDETERMINED,MI:Z,DS:i"

#singularity exec --bind $BIND_PATHS $FEATUREMAP_DOCKER snvfind "$CRAM" "$REF" \
#  -o $OUTPUT_DIR/${BASE}.raw.featuremap.vcf.gz \
#  -f $OUTPUT_DIR/${BASE}.random_sample.featuremap.vcf.gz,${DOWNSAMPLING_RATE} \
#  -v -p $CPUS -L 100 -n -d -Q 20 -r 3 -m 60 -c "$CRAM_TAGS" -b "$BED"

#bcftools index -t $OUTPUT_DIR/${BASE}.raw.featuremap.vcf.gz
#bcftools index -t $OUTPUT_DIR/${BASE}.random_sample.featuremap.vcf.gz

#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
#  --input $OUTPUT_DIR/${BASE}.raw.featuremap.vcf.gz \
#  --output $OUTPUT_DIR/${BASE}.raw.featuremap.parquet \
#  --drop-format GT AD

#this was done to create the stat file to be used for the featuremap stats

#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
#  --in  $OUTPUT_DIR/${BASE}.raw.featuremap.parquet \
#  --out $OUTPUT_DIR/${BASE}.rawFM.filtered.parquet \
#  --stats $OUTPUT_DIR/${BASE}.raw.featuremap.stats.json \
#  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
#  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
#  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
#  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
#  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
#  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
#  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
#  --downsample random:${FP_TRAIN_SET_SIZE}:${RANDOM_SEED}



# =========================
# Step 3: Prepare RAW (FP)
# =========================
#bcftools view $OUTPUT_DIR/${BASE}.raw.featuremap.vcf.gz -T "$TRAINING_REGIONS" -Oz -o $OUTPUT_DIR/${BASE}.raw.training_regions.vcf.gz
#bcftools index -t $OUTPUT_DIR/${BASE}.raw.training_regions.vcf.gz
#Did some cleaning here to remove the non contiguous alleles in the next/prev cycle entry
#this created the .clean file used for the parquet generation - code is added below
#echo "Job started at: $(date)"

##VCF_IN="OICRM4CA-07-01-P.raw.training_regions.vcf.gz"
#VCF_OUT="OICRM4CA-07-01-P.raw.training_regions.clean.vcf.gz"
#BAD_POSITIONS="bad_position1.txt"

#echo "Step 1: Finding bad variants with non-ACGT flanking INFO fields"
#bcftools query -f '%CHROM\t%POS\t[%INFO/X_NEXT1]\t[%INFO/X_PREV1]\t[%INFO/X_NEXT2]\t[%INFO/X_PREV2]\t[%INFO/X_NEXT3]\t[%INFO/X_PREV3]\n' "$VCF_IN" \
#  | awk '{for (i=3;i<=8;i++) if ($i !~ /^[ACGT]$/) {print $1"\t"$2; break}}' \
#  > "$BAD_POSITIONS"
#echo "Found $(wc -l < $BAD_POSITIONS) bad positions"

#echo "Step 2: Filtering out bad positions from VCF"
#bcftools view -T ^"$BAD_POSITIONS" "$VCF_IN" -Oz -o "$VCF_OUT"

#echo "Step 3: Indexing clean VCF"
#bcftools index -t "$VCF_OUT"

#echo "Job finished at: $(date)"
#echo "Cleaned VCF written to $VCF_OUT"



#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
#  --input $OUTPUT_DIR/${BASE}.raw.training_regions.clean.vcf.gz \
#  --output $OUTPUT_DIR/${BASE}.raw.training_regions.parquet \
#  --drop-format GT AD

#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
#  --in  $OUTPUT_DIR/${BASE}.raw.training_regions.parquet \
#  --out $OUTPUT_DIR/${BASE}.raw.filtered.parquet \
#  --stats $OUTPUT_DIR/${BASE}.raw.stats.json \
#  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
#  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
#  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
#  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
#  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
#  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
#  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
#  --filter name=vaf_le_threshold:field=RAW_VAF:op=le:value=${MAX_VAF_FOR_FP}:type=label \
#  --downsample random:${FP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# =========================
# Step 4: Prepare RANDOM SAMPLE (TP)
# =========================
#bcftools view $OUTPUT_DIR/${BASE}.random_sample.featuremap.vcf.gz -T "$TRAINING_REGIONS" -Oz -o $OUTPUT_DIR/${BASE}.rs.training_regions.vcf.gz
#bcftools index -t $OUTPUT_DIR/${BASE}.rs.training_regions.vcf.gz

#also did exact cleaning as in step 3 here to ensure the files are similarly processed - code is added below
#echo "Job started at: $(date)"

#VCF_IN="OICRM4CA-07-01-P.rs.training_regions.vcf.gz"
#VCF_OUT="OICRM4CA-07-01-P.rs.training_regions.clean.vcf.gz"
#BAD_POSITIONS="bad_positions.txt"

#echo "Step 1: Finding bad variants with non-ACGT flanking INFO fields"
#bcftools query -f '%CHROM\t%POS\t[%INFO/X_NEXT1]\t[%INFO/X_PREV1]\t[%INFO/X_NEXT2]\t[%INFO/X_PREV2]\t[%INFO/X_NEXT3]\t[%INFO/X_PREV3]\n' "$VCF_IN" \
#  | awk '{for (i=3;i<=8;i++) if ($i !~ /^[ACGT]$/) {print $1"\t"$2; break}}' \
#  > "$BAD_POSITIONS"
#echo "Found $(wc -l < $BAD_POSITIONS) bad positions"

#echo "Step 2: Filtering out bad positions from VCF"
#bcftools view -T ^"$BAD_POSITIONS" "$VCF_IN" -Oz -o "$VCF_OUT"

#echo "Step 3: Indexing clean VCF"
#bcftools index -t "$VCF_OUT"

#echo "Job finished at: $(date)"
#echo "Cleaned VCF written to $VCF_OUT"



#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
#  --input $OUTPUT_DIR/${BASE}.rs.training_regions.clean.vcf.gz \
#  --output $OUTPUT_DIR/${BASE}.rs.training_regions.clean.parquet \
#  --drop-format GT AD

#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER filter_featuremap \
#  --in  $OUTPUT_DIR/${BASE}.rs.training_regions.clean.parquet \
#  --out $OUTPUT_DIR/${BASE}.rs.filtered.parquet \
#  --stats $OUTPUT_DIR/${BASE}.rs.stats.json \
#  --filter name=coverage_ge_min:field=DP:op=ge:value=${MIN_COV_FILTER}:type=region \
#  --filter name=coverage_le_max:field=DP:op=le:value=${COVERAGE_CEIL}:type=region \
#  --filter name=mapq_ge_60:field=MAPQ:op=ge:value=60:type=quality \
#  --filter name=no_adj_ref_diff:field=ADJ_REF_DIFF:op=eq:value=0:type=quality \
#  --filter name=bcsq_gt_40:field=BCSQ:op=gt:value=40:type=quality \
#  --filter name=edist_le_10:field=EDIST:op=lt:value=10:type=quality \
#  --filter name=alt_hmer_lt_7:field=X_HMER_ALT:op=lt:value=7:type=quality \
#  --filter name=ref_eq_alt:field=REF:op=eq:value_field=ALT:type=label \
#  --downsample random:${TP_TRAIN_SET_SIZE}:${RANDOM_SEED}

# =========================
# Step 5: Train
# =========================
#FEATURES="REF:ALT:X_PREV1:X_NEXT1:X_PREV2:X_NEXT2:X_PREV3:X_NEXT3:X_HMER_REF:X_HMER_ALT:BCSQ:BCSQCSS:RL:INDEX:REV:SCST:SCED:SMQ_BEFORE:SMQ_AFTER:tm:rq:st:et:EDIST:HAMDIST:HAMDIST_FILT"

#singularity exec \
#  --bind /cluster/home/t922316uhn/singularity/srsnv_training.py:/opt/ugbio/srsnv_training.py \
#  --bind "$BIND_PATHS" \
#  "$UGBIO_SRSNV_DOCKER" \
#  python /opt/ugbio/srsnv_training.py \
#  --positive $OUTPUT_DIR/${BASE}.rs.filtered.parquet \
#  --negative $OUTPUT_DIR/${BASE}.raw.filtered.parquet \
#  --stats-positive $OUTPUT_DIR/${BASE}.rs.stats.json \
#  --stats-negative $OUTPUT_DIR/${BASE}.raw.stats.json \
#  --training-regions $TRAINING_REGIONS \
#  --k-folds ${NUM_FOLDS} \
#  --model-params $XGBOOST_PARAMS \
#  --stats-featuremap $OUTPUT_DIR/${BASE}.raw.featuremap.stats.json \
#  --mean-coverage $MEAN_COVERAGE \
#  --features $FEATURES \
#  --basename $BASE \
#  --output $OUTPUT_DIR \
#  --random-seed ${RANDOM_SEED} \
#  --verbose

# =========================
# Step 6: Inference (snvqual)
# =========================
#mkdir -p $OUTPUT_DIR/model_files
#cp $OUTPUT_DIR/${BASE}.model_fold_*.json $OUTPUT_DIR/model_files/
#cp $OUTPUT_DIR/${BASE}.srsnv_metadata.json $OUTPUT_DIR/model_files/srsnv_metadata.json

#singularity exec --bind $BIND_PATHS $FEATUREMAP_DOCKER snvqual \
#  $OUTPUT_DIR/${BASE}.raw.featuremap.vcf.gz \
#  $OUTPUT_DIR/${BASE}.featuremap.vcf.gz \
#  $OUTPUT_DIR/model_files/srsnv_metadata.json \
#  -v

#bcftools index -t $OUTPUT_DIR/${BASE}.featuremap.vcf.gz

#singularity exec --bind $BIND_PATHS $UGBIO_FEATUREMAP_DOCKER featuremap_to_dataframe \
#  --input $OUTPUT_DIR/${BASE}.featuremap.vcf.gz \
#  --output $OUTPUT_DIR/${BASE}.featuremap_df.parquet \
#  --drop-format GT AD

# =========================
# Step 7: Report (srsnv_report)
# =========================
singularity exec --bind $BIND_PATHS $UGBIO_SRSNV_DOCKER srsnv_report \
  --featuremap-df $OUTPUT_DIR/${BASE}.featuremap_df.parquet \
  --srsnv-metadata $OUTPUT_DIR/model_files/srsnv_metadata.json \
  --report-path $OUTPUT_DIR \
  --basename $BASE \
  --verbose
