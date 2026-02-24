#!/bin/bash
#SBATCH --job-name=mutect2_CA08_long_matched
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2CA08_long_matched_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2CA08_long_matched_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem
#SBATCH --array=1-24

module load gatk
module load samtools

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR=/cluster/projects/pughlab/myeloma/projects/M4/TFRIM4_260202

TUMOR_BAM=${BASE_DIR}/Split_Bam/TFRIM4_0058_Cf_P_PG_CA-08-01-P-DNA.filter.deduped.recalibrated.long_gt150.bam
NORMAL_BAM=${BASE_DIR}/TFRIM4_0058_Bm_P_WG_CA-08-01-O-DNA.filter.deduped.recalibrated.bam

VCF_DIR=${BASE_DIR}/GATK_Matched/TFRIM4_0058_CA-08-01_long_gt150

REF=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta
GNOMAD=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/af-only-gnomad.hg38.vcf.gz
REPEAT_MASKER=/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed
ENCODE_BLACKLIST=/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed

mkdir -p ${VCF_DIR}

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
CHR=${CHRS[$SLURM_ARRAY_TASK_ID-1]}

# ── Extract SM tags dynamically from read groups ───────────────────────────────
TUMOR_SM=$(samtools view -H ${TUMOR_BAM} | grep "^@RG" | sed 's/.*SM:\([^\t]*\).*/\1/' | sort -u | head -1)
NORMAL_SM=$(samtools view -H ${NORMAL_BAM} | grep "^@RG" | sed 's/.*SM:\([^\t]*\).*/\1/' | sort -u | head -1)

echo "[$(date)] CHR: ${CHR} | TUMOR SM: ${TUMOR_SM} | NORMAL SM: ${NORMAL_SM}"

# ── Index tumor BAM if needed (lockfile guard) ─────────────────────────────────
if [ ! -f ${TUMOR_BAM}.bai ]; then
    LOCK=${TUMOR_BAM}.index.lock
    if mkdir ${LOCK} 2>/dev/null; then
        echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Indexing tumor BAM..."
        samtools index -@ 8 ${TUMOR_BAM}
        rmdir ${LOCK}
    else
        echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Waiting for tumor BAM index..."
        while [ -d ${LOCK} ]; do sleep 10; done
    fi
fi

# ── Index normal BAM if needed (lockfile guard) ────────────────────────────────
if [ ! -f ${NORMAL_BAM}.bai ]; then
    LOCK=${NORMAL_BAM}.index.lock
    if mkdir ${LOCK} 2>/dev/null; then
        echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Indexing normal BAM..."
        samtools index -@ 8 ${NORMAL_BAM}
        rmdir ${LOCK}
    else
        echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Waiting for normal BAM index..."
        while [ -d ${LOCK} ]; do sleep 10; done
    fi
fi

# ── Mutect2 Matched Normal ─────────────────────────────────────────────────────
echo "[$(date)] Running Mutect2 (Matched Normal) on ${CHR}..."

gatk Mutect2 \
    -R ${REF} \
    -I ${TUMOR_BAM} \
    -I ${NORMAL_BAM} \
    -tumor ${TUMOR_SM} \
    -normal ${NORMAL_SM} \
    -L ${CHR} \
    --exclude-intervals ${REPEAT_MASKER} \
    --exclude-intervals ${ENCODE_BLACKLIST} \
    --germline-resource ${GNOMAD} \
    --panel-of-normals /cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/1000g_pon.hg38.vcf.gz \
    --native-pair-hmm-threads 8 \
    -O ${VCF_DIR}/TFRIM4_0058_CA-08-01_long_gt150_${CHR}.vcf.gz \
    --f1r2-tar-gz ${VCF_DIR}/TFRIM4_0058_CA-08-01_long_gt150_${CHR}_f1r2.tar.gz

echo "[$(date)] Done → ${VCF_DIR}/TFRIM4_0058_CA-08-01_long_gt150_${CHR}.vcf.gz"
