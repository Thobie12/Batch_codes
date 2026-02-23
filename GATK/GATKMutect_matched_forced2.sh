#!/bin/bash
#SBATCH --job-name=mutect2_forced
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_%A_%a.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/mutect2_forced_%A_%a.err
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=superhimem
#SBATCH --array=0-8   # 9 samples, indices 0-8

module load gatk
module load samtools

# ---------------------------
# Arrays of tumor samples, normal BAMs, normal names, and known-site VCFs
# ---------------------------
TUMOR_SAMPLES=(
"OICRM4CA-07-01-P"
"OICRM4CA-08-01-P"
"OICRM4CA-08-R-P"
"OICRM4FZ-08-01-P"
"OICRM4FZ-09-01-P"
"OICRM4HP-01-01-P"
"OICRM4HP-05-01-P"
"OICRM4RE-01-01-P"
"OICRM4VA-09-01-P"
)

NORMAL_BAMS=(
"TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.realigned.merged.bam"
"TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.realigned.merged.bam"
"TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.realigned.merged.bam"
"TFRIM4_0059_Pb_R_WG_FZ-08-01-B-DNA.realigned.merged.bam"
"TFRIM4_0060_Pb_R_WG_FZ-09-03-B-DNA.realigned.merged.bam"
"TFRIM4_0032_Pb_R_PG.realigned.merged.bam"
"TFRIM4_0179_Pb_R_HP-05-01-B-DNA.realigned.merged.bam"
"TFRIM4_0062_Pb_R_WG_RE-01-03-B-DNA.realigned.merged.bam"
"TFRIM4_0183_Pb_R_VA-09-01-B-DNA.realigned.merged.bam"
)

NORMAL_NAMES=(
"TFRIM4_0057_Pb_R_WG_CA-07-03-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0058_Pb_R_WG_CA-08-01-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0059_Pb_R_WG_FZ-08-01-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0060_Pb_R_WG_FZ-09-03-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0032_Pb_R_PG.filter.deduped.recalibrated"
"TFRIM4_0179_Pb_R_HP-05-01-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0062_Pb_R_WG_RE-01-03-B-DNA.filter.deduped.recalibrated"
"TFRIM4_0183_Pb_R_VA-09-01-B-DNA.filter.deduped.recalibrated"
)

KNOWN_VCFS=(
"TFRIM4_0057_Bm_P_WG_CA-07-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0058_Bm_P_WG_CA-08-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0058_Bm_P_WG_CA-08.filter.deduped.recalibrated.bam_merged.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0059_Bm_P_WG_FZ-08-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0060_Bm_P_WG_FZ-09-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0032_Bm_P_WG_M4-HP-01-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0179_Bm_P_WG_HP-05-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0062_Bm_P_WG_RE-01-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
"TFRIM4_0183_Bm_P_WG_VA-09-01-O-DNA.mutect2.filtered.vep.PASS_VAF_above_0.1_encode_filtered_STR_filtered.vcf.gz"
)

NORMAL_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Realigned_Bam"
REFERENCE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
GRESOURCE="/cluster/projects/pughlab/references/Mutect2/af-only-gnomad.hg38.vcf.gz"
VCF_BASEDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"

# ---------------------------
# Pick the sample for this array task
# ---------------------------
i=$SLURM_ARRAY_TASK_ID
SAMPLE="${TUMOR_SAMPLES[$i]}"
NORMAL_BAM="${NORMAL_DIR}/${NORMAL_BAMS[$i]}"
NORMAL_NAME="${NORMAL_NAMES[$i]}"
KNOWN_VCF="${VCF_BASEDIR}/BM_Illumina/${KNOWN_VCFS[$i]}"
OUT_DIR="${VCF_BASEDIR}/${SAMPLE}/Forced2"
mkdir -p "$OUT_DIR"

echo "Running forced Mutect2 for $SAMPLE"

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

gatk FilterMutectCalls \
  -V "${OUT_DIR}/${SAMPLE}_forced.vcf.gz" \
  -R "$REFERENCE" \
  -O "${OUT_DIR}/${SAMPLE}_forced_filtered.vcf.gz"

echo "Completed forced calling for $SAMPLE"
