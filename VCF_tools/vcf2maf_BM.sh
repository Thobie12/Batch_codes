#!/bin/bash
#SBATCH --job-name=vcf2maf_annotation
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.log
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=1:00:00
#SBATCH --partition=pughlab
#SBATCH --array=0-8

module load perl
module load vep
module load vcf2maf
module load samtools

VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina"
REF_FASTA="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VEP_PATH="/cluster/tools/software/centos7/vep/112"
VCF2MAF_PATH="/cluster/home/t922316uhn/vcf2maf/vcf2maf.pl"
COSMIC="/cluster/tools/data/genomes/human/hg38/Cosmic_77.hg38.vcf"
ClinVar="/cluster/home/t922316uhn/ClinVar/clinvar.vcf.gz"

# Get the list of VCF files
VCF_FILES=(${VCF_DIR}/*.vcf.gz)
VCF_ZIP="${VCF_FILES[$SLURM_ARRAY_TASK_ID]}"

# Extract sample ID from filename
SAMPLE_ID=$(basename "$VCF_ZIP" .vcf.gz)
TUMOR_ID="$SAMPLE_ID"   # assuming tumor ID = sample name
NORMAL_ID="NORMAL"      # change if you have a different normal sample

echo "🔹 Processing SAMPLE_ID=$SAMPLE_ID, TUMOR_ID=$TUMOR_ID, NORMAL_ID=$NORMAL_ID ..."

VCF_INPUT="${VCF_DIR}/${SAMPLE_ID}.vcf"
gunzip -c "$VCF_ZIP" > "$VCF_INPUT"

MAF_DIR="${VCF_DIR}/maf"
mkdir -p "$MAF_DIR"
MAF_OUTPUT="${MAF_DIR}/${SAMPLE_ID}.maf"

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

rm -f "$VCF_INPUT"

echo "✅ Finished SAMPLE_ID=$SAMPLE_ID → $MAF_OUTPUT"
