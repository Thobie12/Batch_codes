#!/bin/bash
#Scaling DELLY for all file

# Path to sample list
SAMPLE_LIST="samples.txt"
#contains all the sample list

# Reference genome and exclusion file
REF="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
EXCL="/cluster/home/t922316uhn/delly_excl/human.hg38.excl.tsv"

# Base paths
CRAM_DIR="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams"
OUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/VCF"
LOG_DIR="/cluster/home/t922316uhn/PLO/Delly"

# Loop over each sample
while read SAMPLE; do

  # Submit a separate job per sample
  sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=delly_${SAMPLE}
#SBATCH --output=${LOG_DIR}/delly_${SAMPLE}_%j.out
#SBATCH --error=${LOG_DIR}/delly_${SAMPLE}_%j.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH --partition=pughlab

module load delly
module load samtools

delly call \\
  -g $REF \\
  -o ${OUT_DIR}/${SAMPLE}/${SAMPLE}.delly.bcf \\
  -x $EXCL \\
  ${CRAM_DIR}/${SAMPLE}.cram

# convert BCF to VCF
bcftools view -Ov ${OUT_DIR}/${SAMPLE}/${SAMPLE}.delly.bcf > ${OUT_DIR}/${SAMPLE}/${SAMPLE}.delly.vcf

EOF

done < "$SAMPLE_LIST"
