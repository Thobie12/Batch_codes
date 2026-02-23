#!/bin/bash
#SBATCH --job-name=vcf2maf_annotation
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.log
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=6:00:00
#SBATCH --partition=pughlab
#SBATCH --array=0  # 8 samples

module load perl
module load vep
module load vcf2maf
module load samtools

VCF_BASEDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"
REF_FASTA="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VEP_PATH="/cluster/tools/software/centos7/vep/112"
VCF2MAF_PATH="/cluster/home/t922316uhn/vcf2maf/vcf2maf.pl"
COSMIC="/cluster/tools/data/genomes/human/hg38/Cosmic_77.hg38.vcf"
ClinVar="/cluster/home/t922316uhn/ClinVar/clinvar.vcf.gz"
SAMPLES_TXT="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/VCF_tools/samples_forced2.txt"

# ---------------------------
# Read this task's sample info
# ---------------------------
SAMPLE_LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SAMPLES_TXT)
SAMPLE=$(echo "$SAMPLE_LINE" | cut -f1)
TUMOR_ID=$(echo "$SAMPLE_LINE" | cut -f2)
NORMAL_ID=$(echo "$SAMPLE_LINE" | cut -f3)

echo "🔹 Processing SAMPLE=$SAMPLE, TUMOR_ID=$TUMOR_ID, NORMAL_ID=$NORMAL_ID ..."

# ---------------------------
# Forced directory (input and output)
# ---------------------------
FORCED_DIR="${VCF_BASEDIR}/${SAMPLE}/Forced2"
mkdir -p "$FORCED_DIR"

VCF_GZ="${FORCED_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.vcf.gz"
VCF_INPUT="${FORCED_DIR}/${SAMPLE}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.vcf"

# ---------------------------
# Unzip VCF if necessary
# ---------------------------
if [ -f "$VCF_GZ" ]; then
    echo "🔹 Unzipping $VCF_GZ ..."
    gunzip -c "$VCF_GZ" > "$VCF_INPUT"
fi

MAF_OUTPUT="${FORCED_DIR}/${SAMPLE}.maf"

# ---------------------------
# Run vcf2maf
# ---------------------------
perl $VCF2MAF_PATH \
  --input-vcf "$VCF_INPUT" \
  --output-maf "$MAF_OUTPUT" \
  --tumor-id "$TUMOR_ID" \
  --normal-id "$NORMAL_ID" \
  --ref-fasta "$REF_FASTA" \
  --vep-path "$VEP_PATH" \
  --ncbi-build GRCh38 \
  --species homo_sapiens \
  --retain-info DP,AD,AF,SB \
  --retain-fmt GT,AD,AF,DP \
  --vep-data /cluster/projects/pughlab/references/VEP_cache/112 \
  --vep-forks 2 \
  --vep-custom "$COSMIC,COSMIC,vcf,exact,0,COSMIC_ID" \
  --vep-custom "$ClinVar,CLINVAR,vcf,exact,0,CLNSIG"

# ---------------------------
# Clean up uncompressed VCF
# ---------------------------
if [ -f "$VCF_INPUT" ]; then
    rm -f "$VCF_INPUT"
    echo "🔹 Removed uncompressed VCF $VCF_INPUT"
fi

echo "✅ Finished SAMPLE=$SAMPLE → $MAF_OUTPUT"
