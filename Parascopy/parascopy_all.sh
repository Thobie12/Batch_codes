#!/bin/bash
Parascopy_BatchSubmission
OUT_DIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy"
SAMPLE_LIST="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Parascopy/samples.txt"
GENOME_FA="/cluster/tools/data/genomes/human/hg38/iGenomes/Sequence/WholeGenomeFasta/genome.fa"
HOMOL_TABLE="/cluster/home/t922316uhn/parascopy/homology/homology_table/hg38.bed.gz"


while read SAMPLE; do
    # 1. Submit Bgread job
    BGREAD_JOBID=$(sbatch --parsable <<EOF
#!/bin/bash
#SBATCH --job-name=Bgread_depth_${SAMPLE}
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=pughlab
#SBATCH --output=/cluster/home/t922316uhn/PLO/Parascopy/Bgread/bgread_${SAMPLE}_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Parascopy/Bgread/bgread_${SAMPLE}_%j.err

module load python3
source \$(conda info --base)/etc/profile.d/conda.sh
conda activate paras_env
parascopy depth -I ${OUT_DIR}/${SAMPLE}.txt -g hg38 -f ${GENOME_FA} -o ${OUT_DIR}/${SAMPLE}/depth
EOF
)

    # 2. Submit cnvref job, dependent on Bgread
    CNVREF_JOBID=$(sbatch --parsable --dependency=afterok:${BGREAD_JOBID} <<EOF
#!/bin/bash
#SBATCH --job-name=cnv_ref_${SAMPLE}
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=pughlab
#SBATCH --output=/cluster/home/t922316uhn/PLO/Parascopy/cnvref_${SAMPLE}_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Parascopy/cnvref_${SAMPLE}_%j.err

module load python3
source \$(conda info --base)/etc/profile.d/conda.sh
conda activate paras_env
parascopy cn -I ${OUT_DIR}/${SAMPLE}.txt -t ${HOMOL_TABLE} -R ${OUT_DIR}/mm_targets2.bed -f ${GENOME_FA} -d ${OUT_DIR}/${SAMPLE}/depth -o ${OUT_DIR}/${SAMPLE}/cnv_analysis
EOF
)

    # 3. Submit call job, dependent on cnvref
    sbatch --dependency=afterok:${CNVREF_JOBID} <<EOF
#!/bin/bash
#SBATCH --job-name=call_${SAMPLE}
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=pughlab
#SBATCH --output=/cluster/home/t922316uhn/PLO/Parascopy/call/call_${SAMPLE}_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/Parascopy/call/call_${SAMPLE}_%j.err

module load python3
source \$(conda info --base)/etc/profile.d/conda.sh
conda activate paras_env
parascopy call -p ${OUT_DIR}/${SAMPLE}/cnv_analysis -f ${GENOME_FA} -t ${HOMOL_TABLE} -@ 8
EOF

done < ${SAMPLE_LIST}



