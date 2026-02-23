#!/bin/bash
#SBATCH --job-name=mutect2_forced
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_%j.err
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem

module load gatk
module load samtools

# ---------------------------
# Sample info
# ---------------------------
SAMPLE="OICRM4VA-09-01-P"
NORMAL_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam/TFRIM4_0183_Pb_R_VA-09-01-B-DNA.realigned.merged.bam"
NORMAL="TFRIM4_0183_Pb_R_VA-09-01-B-DNA.filter.deduped.recalibrated"
VCF_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE}"
mkdir -p "${VCF_DIR}/Forced"

REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
REPEAT_MASKER="/cluster/projects/pughlab/references/RepeatMasker/hg38.fa.bed"
ENCODE_BLACKLIST="/cluster/projects/pughlab/references/ENCODE/lists/hg38-blacklist.v2.bed"
#KNOWN_SITES="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/known_sites_3000.vcf"
#KNOWN_SITES="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/TFRIM4_0032_Bm_P_WG_M4-HP-01-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
#KNOWN_SITES="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/TFRIM4_0179_Bm_P_WG_HP-05-01-O-DNA.filter.deduped.recalibrated.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
KNOWN_SITES="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/TFRIM4_0183_Bm_P_WG_VA-09-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"

# ---------------------------
# Run Mutect2 forced calling
# ---------------------------
gatk Mutect2 \
  -R "$REFERENCE" \
  -I /cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/${SAMPLE}.cram \
  -I $NORMAL_DIR \
  -tumor $SAMPLE \
  -normal $NORMAL \
  --alleles $KNOWN_SITES \
  --germline-resource /cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz \
  --native-pair-hmm-threads 8 \
  -O ${VCF_DIR}/Forced/${SAMPLE}_forced.vcf.gz \
  --f1r2-tar-gz ${VCF_DIR}/Forced/${SAMPLE}_forced_f1r2.tar.gz

# ---------------------------
# Filter Mutect2 calls
# ---------------------------
gatk FilterMutectCalls \
  -V ${VCF_DIR}/Forced/${SAMPLE}_forced.vcf.gz \
  -R $REFERENCE \
  -O ${VCF_DIR}/Forced/${SAMPLE}_forced_filtered.vcf.gz

echo "Forced calling completed for $SAMPLE"
