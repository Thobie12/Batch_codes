#!/bin/bash
#SBATCH --job-name=realign_normal
#SBATCH --output=/cluster/home/t922316uhn/PLO/Bazam/logs/realign_normal_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Bazam/logs/realign_normal_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G                     # safer headroom vs 64G
#SBATCH --array=1-20                  # 20 shards
#SBATCH --partition=superhimem

# --- Modules ---
module load samtools
module load bwa
module load java

# --- Input / Reference ---
#SAMPLE="TFRIM4_0062_Pb_R_WG_RE-01-03-B-DNA.filter.deduped.recalibrated"
SAMPLE="TFRIM4_0032_Pb_R_PG.filter.deduped.recalibrated"
BAM="/cluster/projects/pughlab/myeloma/external_data/For_Tobi/${SAMPLE}.bam"
#BAM="/cluster/projects/myelomagroup/external_data/TFRIM4_231017/All_bams_batch_1A_TFRIM4/${SAMPLE}.bam"

#SAMPLE="TFRIM4_0183_Pb_R_VA-09-01-B-DNA.filter.deduped.recalibrated"
#BAM="/cluster/projects/pughlab/myeloma/external_data/Unarchiving_cfWGS/Toby_All_bams_TFRIM4_batch2A/${SAMPLE}.bam"
REF="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/BWAIndex/Homo_sapiens_assembly38.fasta.64"

SM="$SAMPLE"
ID="REALN_${SM}"
PL="ILLUMINA"
LB="${SM}"
THREADS=4
MEM_PER_THREAD="2G"                  # reduced to avoid OOM

BAZAM_JAR="/cluster/home/t922316uhn/Bazam/bazam.jar"
OUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/REALIGNED_Parallel"
mkdir -p "$OUT_DIR"

# --- Ensure BAM index exists and is fresh ---
if [ ! -f "${BAM}.bai" ] || [ "$BAM" -nt "${BAM}.bai" ]; then
    echo "Creating/updating BAM index..."
    samtools index $BAM
fi

# --- Determine shard for this array task ---
SHARDS=20
SHARD=$SLURM_ARRAY_TASK_ID
SHARD_BAM="${OUT_DIR}/${SM}.realigned.shard${SHARD}.bam"

echo "Processing shard $SHARD of $SHARDS for sample $SM ..."

# --- Realignment for this shard ---
java -Xmx8G -jar $BAZAM_JAR \
    -bam $BAM -s $SHARD,$SHARDS | \
bwa mem -t $THREADS -R "@RG\tID:$ID\tSM:$SM\tPL:$PL\tLB:$LB" $REF - | \
samtools view -@ $THREADS -bSu - | \
samtools sort -@ $THREADS -m $MEM_PER_THREAD -T ${OUT_DIR}/tmp_shard${SHARD} -o $SHARD_BAM

samtools index -@ $THREADS $SHARD_BAM

echo "Shard $SHARD complete: $SHARD_BAM"
