#!/bin/bash
#SBATCH --job-name=bedtools_map_freec
#SBATCH --output=bedtools_map_freec_%j.log
#SBATCH --error=bedtools_map_freec_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

# Load Singularity if needed
 module load singularity

# Paths
SIF_PATH=/cluster/home/t922316uhn/UGBIO/ugbio_freec_1.5.5.sif
FAI_PATH=/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta.fai
BINS_BED=/cluster/home/t922316uhn/bed/Homo_sapiens_assembly38.w1000.bed
BEDGRAPH_GZ=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/FREEC/OICRM4CA-07-01-P/OICRM4CA-07-01-P.bedgraph.gz
BEDGRAPH=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/FREEC/OICRM4CA-07-01-P/OICRM4CA-07-01-P.bedgraph
OUTPUT_CPN=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/FREEC/OICRM4CA-07-01-P/OICRM4CA-07-01-P.cpn

# Decompress if .gz exists
if [[ $BEDGRAPH_GZ =~ \.gz$ && -f "$BEDGRAPH_GZ" ]]; then
    gzip -d -c "$BEDGRAPH_GZ" > "$BEDGRAPH"
fi

# Run bedtools map inside Singularity
singularity exec -B /cluster:/cluster $SIF_PATH \
  bedtools map -g "$FAI_PATH" \
    -a "$BINS_BED" \
    -b "$BEDGRAPH" \
    -c 4 -o mean | \
  awk '{if($4=="."){print $1"\t"$2"\t"0}else{print $1"\t"$2"\t"$4}}' | \
  grep -v "chrY" | \
  sed 's/^chr//' > "$OUTPUT_CPN"
