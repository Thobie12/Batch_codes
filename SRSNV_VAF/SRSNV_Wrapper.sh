#!/bin/bash
#SBATCH --job-name=SRSNV_wrapper
#SBATCH --output=log/SRSNV_wrapper_%j.log
#SBATCH --partition=pughlab
#SBATCH --time=00:05:00

#SAMPLES_FILE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/samples.txt"
#PIPELINE_SCRIPT="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/SRSNV_OICRM4CA_101325.sh"
PIPELINE_SCRIPT="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/SNV_Ultima/SRSNV_VAF/SRSNV_OICRM4CA_101325_report.sh"
SAMPLES_FILE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/SNV_Ultima/SRSNV_VAF/samples.txt"
if [ ! -f "$SAMPLES_FILE" ]; then
  echo "Error: samples.txt not found at $SAMPLES_FILE"
  exit 1
fi

while read -r SAMPLE; do
  # skip empty lines or comments
  [[ -z "$SAMPLE" || "$SAMPLE" == \#* ]] && continue

  echo "Submitting pipeline for sample: $SAMPLE"
  sbatch "$PIPELINE_SCRIPT" "$SAMPLE"
  sleep 1  # optional small delay to avoid overloading scheduler
done < "$SAMPLES_FILE"
