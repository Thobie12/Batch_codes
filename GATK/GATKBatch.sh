#!/bin/bash

# List of cram files
CRAMS=(
"/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-08-R-P.cram"
"/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4FZ-08-01-P.cram"
)
# add this after
# "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4FZ-09-01-P.cram"
# "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4HP-01-01-P.cram"
# "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4HP-05-01-P.cram"
# "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4RE-01-01-P.cram"
# "/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4VA-09-01-P.cram"

# Reference fasta
REF="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"

# Panel of normals and germline resource
PON="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/1000g_pon.hg38.vcf.gz"
GERMLINE="/cluster/tools/data/genomes/human/GRCh38/iGenomes/Annotation/GATKBundle/af-only-gnomad.hg38.vcf.gz"

# Output base directory (adjust if needed)
OUT_BASE="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK"

for cram in "${CRAMS[@]}"; do
  # Extract sample name from cram filename
  fname=$(basename "$cram")
  sample="${fname%.cram}"  # remove extension

  # Create output dir for this sample
  outdir="${OUT_BASE}/${sample}"
  mkdir -p "$outdir"

  # Create a temporary sbatch script
  script="${outdir}/mutect2_${sample}.sbatch"

  cat > "$script" << EOF
#!/bin/bash
#SBATCH --job-name=mutect2_${sample}
#SBATCH --output=${outdir}/mutect2_chr_%A_%a.out
#SBATCH --error=${outdir}/mutect2_chr_%A_%a.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=all
#SBATCH --array=1-24%4   # 22 autosomes + X + Y

module load gatk
module load samtools

CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)
CHR=\${CHRS[\$SLURM_ARRAY_TASK_ID-1]}

gatk Mutect2 \\
  -R $REF \\
  -I $cram \\
  -tumor $sample \\
  -L \$CHR \\
  --panel-of-normals $PON \\
  --germline-resource $GERMLINE \\
  --f1r2-tar-gz ${outdir}/${sample}_\${CHR}.f1r2.tar.gz \\
  --native-pair-hmm-threads 8 \\
  -O ${outdir}/${sample}_\${CHR}.vcf.gz
EOF

  # Submit the job
  sbatch "$script"

done
