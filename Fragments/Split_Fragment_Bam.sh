#!/bin/bash
#SBATCH --job-name=split_bam_frag
#SBATCH --partition=superhimem
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

set -euo pipefail

# ============================
# USER INPUT
# ============================
sample=TFRIM4_0058_Cf_P_PG_CA-08-01-P-DNA.filter.deduped.recalibrated
#sample=TFRIM4_0058_Cf_P_PG_CA-08-R-P-DNA.filter.deduped.recalibrated
#sample=TFRIM4_0179_Cf_P_HP-05-01-P-DNA.filter.deduped.recalibrated
#sample=TFRIM4_0059_Cf_P_PG_FZ-08-01-P-DNA.filter.deduped.recalibrated

indir=/cluster/projects/pughlab/myeloma/projects/M4/TFRIM4_260202
outdir=/cluster/projects/pughlab/myeloma/projects/M4/TFRIM4_260202/Split_Bam
THREADS=${SLURM_CPUS_PER_TASK:-8}   # fallback if run outside SLURM

mkdir -p "${outdir}" logs

inbam="${indir}/${sample}.bam"
short_bam="${outdir}/${sample}.short_90_150.bam"
long_bam="${outdir}/${sample}.long_gt150.bam"
tmp_short="${outdir}/${sample}.short_unsorted.bam"
tmp_long="${outdir}/${sample}.long_unsorted.bam"

# Auto-cleanup temp files on exit or error
trap 'rm -f "${tmp_short}" "${tmp_long}"' EXIT

# ============================
# LOAD SAMTOOLS
# ============================
module load samtools

# ============================
# CHECK + INDEX INPUT
# ============================
[[ -f "${inbam}" ]] || { echo "ERROR: BAM not found: ${inbam}"; exit 1; }

if [[ ! -f "${inbam}.bai" && ! -f "${inbam%.bam}.bai" ]]; then
  echo "Indexing input BAM..."
  samtools index -@ "${THREADS}" "${inbam}"
fi

# ============================
# SPLIT BAM BY FRAGMENT LENGTH (ONE PASS)
# ============================
echo "Splitting BAM by fragment length..."

samtools view -h "${inbam}" \
| awk -v short="${tmp_short}" -v long="${tmp_long}" '
BEGIN {
  short_cmd = "samtools view -b -o " short
  long_cmd  = "samtools view -b -o " long
}
/^@/ {
  print | short_cmd
  print | long_cmd
  next
}
{
  tlen = ($9 < 0) ? -$9 : $9
  if      (tlen >= 90 && tlen <= 150) print | short_cmd
  else if (tlen > 150)                print | long_cmd
}
END {
  close(short_cmd)
  close(long_cmd)
}'

# ============================
# SORT + INDEX OUTPUTS
# ============================
echo "Sorting short BAM..."
samtools sort -@ "${THREADS}" -o "${short_bam}" "${tmp_short}"
samtools index -@ "${THREADS}" "${short_bam}"

echo "Sorting long BAM..."
samtools sort -@ "${THREADS}" -o "${long_bam}" "${tmp_long}"
samtools index -@ "${THREADS}" "${long_bam}"

echo "DONE"
echo "Short BAM: ${short_bam}"
echo "Long  BAM: ${long_bam}"
