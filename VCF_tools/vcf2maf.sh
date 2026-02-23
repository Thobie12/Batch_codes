#!/bin/bash
#SBATCH --job-name=vcf2maf_annotation
#SBATCH --output=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%j.log
#SBATCH --error=/cluster/home/t922316uhn/PLO/vcf2maf/vcf2maf_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=9
#SBATCH --mem=16G
#SBATCH --time=6:00:00
#SBATCH --partition=all
#SBATCH --dependency=afterok:3504924

module load perl
module load vep
module load vcf2maf
module load samtools

SAMPLE_ID="OICRM4VA-09-01-P"
VCF_ZIP="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE_ID}/Merged/vcf/${SAMPLE_ID}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.vcf.gz"
VCF_INPUT="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE_ID}/Merged/vcf/${SAMPLE_ID}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.vcf"
MAF_OUTPUT="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/${SAMPLE_ID}/Merged/vcf/${SAMPLE_ID}_GATKFiltered_ENCODE_RepeatMask_Filtered.norm.PASS.ADgt1.snp.maf"
TUMOR_ID="M4-VA-09-01-P-DNA"
NORMAL_ID="TFRIM4_0183_Pb_R_VA-09-01-B-DNA.filter.deduped.recalibrated"

gunzip -c $VCF_ZIP > $VCF_INPUT

REF_FASTA="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
VEP_PATH="/cluster/tools/software/centos7/vep/112"
VCF2MAF_PATH="/cluster/home/t922316uhn/vcf2maf/vcf2maf.pl"

COSMIC="/cluster/tools/data/genomes/human/hg38/Cosmic_77.hg38.vcf"
ClinVar="/cluster/home/t922316uhn/ClinVar/clinvar.vcf.gz"

perl $VCF2MAF_PATH \
  --input-vcf $VCF_INPUT \
  --output-maf $MAF_OUTPUT \
  --tumor-id $TUMOR_ID \
  --normal-id $NORMAL_ID \
  --ref-fasta $REF_FASTA \
  --vep-path $VEP_PATH \
  --ncbi-build GRCh38 \
  --species homo_sapiens \
  --retain-info DP,AD,AF,SB \
  --retain-fmt GT,AD,AF,DP \
  --vep-data /cluster/projects/pughlab/references/VEP_cache/112 \
  --vep-forks 8 \
  --vep-custom "$COSMIC,COSMIC,vcf,exact,0,COSMIC_ID" \
  --vep-custom "$ClinVar,CLINVAR,vcf,exact,0,CLNSIG"
