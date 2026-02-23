#!/bin/bash
# Variables
SAMPLE_LIST="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/samples2.txt"
REF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ref/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
OUT_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GRIDSS"
THREADS=8
CRAM_DIR="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams"
LOG_DIR="/cluster/home/t922316uhn/PLO/GRIDSS"

# Loop over each sample
while read SAMPLE; do

  # Submit a separate job per sample
  sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=gridss_${SAMPLE}
#SBATCH --output=${LOG_DIR}/gridss_${SAMPLE}_%j.out
#SBATCH --error=${LOG_DIR}/gridss_${SAMPLE}_%j.err
#SBATCH --time=5-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=pughlab

module load R
module load bwa
module load java
module load samtools

echo "Starting GRIDSS run on \${SAMPLE}"
date

/cluster/home/t922316uhn/gridss/gridss \
  --jar /cluster/home/t922316uhn/gridss/gridss-2.13.2-gridss-jar-with-dependencies.jar \
  --reference "$REF" \
  --output ${OUT_VCF}/${SAMPLE}/${SAMPLE}.sv.vcf \
  --assembly ${OUT_VCF}/${SAMPLE}/${SAMPLE}.gridss.assembly.bam \
  --workingdir ${OUT_VCF}/${SAMPLE} \
  --threads "$THREADS" \
  "${CRAM_DIR}/${SAMPLE}.cram"

echo "GRIDSS finished"
date

EOF
done < "$SAMPLE_LIST"
