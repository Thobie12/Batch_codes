#!/bin/bash

OUTFILE="samples_comp.txt"
echo -e "Sample_ID\tUltima_VCF\tCf_Illumina_VCF\tBM_Illumina_VCF" > $OUTFILE

# List of samples (SRSNV folders)
for SAMPLE in OICRM4CA-07-01-P OICRM4CA-08-R-P M4-HP-01-01-P; do
    SRSNV_VCF="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/sample/${SAMPLE}/model/${SAMPLE}.tmp.dedup.vcf.gz"
    CF_ILLUMINA=$(ls /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/Illumina/SNPs/*${SAMPLE}*.vcf.gz | grep -v ".csi" | head -n1)
    BM_ILLUMINA=$(ls /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/BM_Illumina/SNPs/*${SAMPLE}*.vcf.gz | grep -v ".csi" | head -n1)
    
    echo -e "${SAMPLE}\t${SRSNV_VCF}\t${CF_ILLUMINA}\t${BM_ILLUMINA}" >> $OUTFILE
done
