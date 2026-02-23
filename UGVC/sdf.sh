# Delete the incomplete SDF first
rm -rf /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/references/Homo_sapiens_assembly38.fasta.sdf

# Submit as SLURM job
sbatch \
  --job-name=rtg_format \
  --output=rtg_format_%j.log \
  --cpus-per-task=4 \
  --mem=64G \
  --time=2:00:00 \
  --partition=superhimem \
  --wrap="singularity exec \
    -B /cluster:/cluster \
    --env PATH=$HOME/bin:/opt/conda/envs/genomics.py3/bin:/usr/bin:/bin:$PATH \
    /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/UGBIODocker/docker/ugbio_ugvc.sif \
    rtg format \
    -o /cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/references/Homo_sapiens_assembly38.fasta.sdf \
    /cluster/tools/data/genomes/human/GRCh38/iGenomes/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta"
