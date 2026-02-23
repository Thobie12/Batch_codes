#!/bin/bash
#SBATCH --job-name=esvee_depth_annotator
#SBATCH --output=/cluster/home/t922316uhn/PLO/esvee__%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/esveer_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=pughlab

module load java    # load Java module if needed

java -cp /cluster/home/t922316uhn/ESVEE/sv-prep_v1.1.jar com.hartwig.hmftools.svprep.depth.DepthAnnotator \
  -input_vcf /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GRIDSS/OICRM4CA-07-01-P/OICRM4CA-07-01-P.sv.vcf \
  -output_vcf /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/ESVEE/OICRM4CA-07-01-P/OICRM4CA-07-01-P.sv.vcf \
  -samples M4-CA-07-01-P-DNA \
  -bam_files /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Bam/OICRM4CA-07-01-P.bam \
  -ref_genome /cluster/tools/data/genomes/human/hg38/iGenomes/Sequence/WholeGenomeFasta/genome.fa \
  -ref_genome_version 38 \
  -threads 8
