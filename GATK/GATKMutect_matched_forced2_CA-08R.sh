#!/bin/bash
#SBATCH --job-name=mutect2_forced_CA-08-R-P
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_CA-08-R-P.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_CA-08-R-P.err
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem

module load gatk
module load samtools

# ---------------------------
# Sample-specific paths
# ---------------------------
SAMPLE="OICRM4CA-08-R-P"
NORMAL_BAM="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam/TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.realigned.merged.bam"
NORMAL_NAME="TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.filter.deduped.recalibrated"
KNOWN_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/TFRIM4_0058_Bm_P_WG_CA-08.filter.deduped.recalibrated.bam_merged.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"

REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
GRESOURCE="/cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz"
VCF_BASEDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"
OUT_DIR="${VCF_BASEDIR}/${SAMPLE}/Forced2"
mkdir -p "$OUT_DIR"

echo "Running forced Mutect2 for $SAMPLE"

# ---------------------------
# Mutect2 forced calling
# ---------------------------
gatk Mutect2 \
  -R "$REFERENCE" \
  -I "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram" \
  -I "$NORMAL_BAM" \
  -tumor "$SAMPLE" \
  -normal "$NORMAL_NAME" \
  --alleles "$KNOWN_VCF" \
  --L "$KNOWN_VCF" \
  --germline-resource "$GRESOURCE" \
  --native-pair-hmm-threads 8 \
  -O "${OUT_DIR}/${SAMPLE}_forced.vcf.gz" \
  --f1r2-tar-gz "${OUT_DIR}/${SAMPLE}_forced_f1r2.tar.gz"

# ---------------------------
# Filter Mutect2 calls
# ---------------------------
gatk FilterMutectCalls \
  -V "${OUT_DIR}/${SAMPLE}_forced.vcf.gz" \
  -R "$REFERENCE" \
  -O "${OUT_DIR}/${SAMPLE}_forced_filtered.vcf.gz"

echo "Completed forced calling for $SAMPLE"
