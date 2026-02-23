#!/bin/bash

SAMPLE_LIST="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/samples2.txt"
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
OUT_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GRIDSS"
THREADS=8
CRAM_DIR="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams"
LOG_DIR="/cluster/home/t922316uhn/PLO/GRIDSS"
BLACKLIST="/cluster/home/t922316uhn/black/ENCFF356LFX.bed"
GRIDSS_JAR="/cluster/home/t922316uhn/gridss/gridss-2.13.2-gridss-jar-with-dependencies.jar"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Loop over each sample (skip blank lines & comments)
while read -r SAMPLE; do
  # Skip if line is empty or starts with "#"
  [[ -z "$SAMPLE" || "$SAMPLE" =~ ^# ]] && continue

  echo "Submitting GRIDSS annotation job for SAMPLE=${SAMPLE}"

  sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=gridss_annotate_${SAMPLE}
#SBATCH --output=${LOG_DIR}/gridss_annotate_${SAMPLE}_%j.out
#SBATCH --error=${LOG_DIR}/gridss_annotate_${SAMPLE}_%j.err
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=${THREADS}
#SBATCH --mem=64G
#SBATCH --partition=pughlab

module load R
module load java
module load samtools

echo "Starting GRIDSS annotation for ${SAMPLE}"
date

java -Xmx10g -cp ${GRIDSS_JAR} gridss.AnnotateVariants \
    INPUT_VCF=${OUT_VCF}/${SAMPLE}/${SAMPLE}.sv.vcf \
    R=${REF} \
    I=${CRAM_DIR}/${SAMPLE}.cram \
    BLACKLIST=${BLACKLIST} \
    ASSEMBLY=${OUT_VCF}/${SAMPLE}/${SAMPLE}.gridss.assembly.bam \
    OUTPUT_VCF=${OUT_VCF}/${SAMPLE}/${SAMPLE}_annotated.vcf \
    WORKING_DIR=${OUT_VCF}/${SAMPLE}

echo "Finished GRIDSS annotation for ${SAMPLE}"
date
EOF

done < "${SAMPLE_LIST}"
