#!/bin/bash
#SBATCH --job-name=ichorCNA_pipeline
#SBATCH --output=logs/snakemake_%j.out
#SBATCH --error=logs/snakemake_%j.err
#SBATCH --time=1-00:00:00         # max runtime (adjust as needed)
#SBATCH --cpus-per-task=1       # number of CPU cores
#SBATCH --mem=4G               # memory per node
#SBATCH --partition=pughlab    # adjust to your cluster's partition/queue

# Load modules
module load snakemake    # or the correct module name for Snakemake

# Run snakemake with cluster submission
#snakemake -s /cluster/home/t922316uhn/ichorCNA/scripts/snakemake/ichorCNA.snakefilemod -p \
#    --cluster "sbatch --mem={cluster.mem} --cpus-per-task={cluster.ncpus} --partition={cluster.partition} --time={cluster.time} --output={cluster.output}" \
#    --jobs 100

#snakemake -s /cluster/home/t922316uhn/ichorCNA/scripts/snakemake/ichorCNA.snakefilemod -p \
#    --cluster "sbatch --mem={cluster.mem} --cpus-per-task={cluster.ncpus} --partition={cluster.partition} --time={cluster.time}" \
#    --cluster-config /cluster/home/t922316uhn/ichorCNA/scripts/snakemake/config/cluster_slurm.yaml \
#    --jobs 100

snakemake -s /cluster/home/t922316uhn/ichorCNA/scripts/snakemake/ichorCNA.test -p \
    --cluster "sbatch --mem=16G --cpus-per-task=1 --partition=pughlab --time=12:0:0" \
    --jobs 100
    --latency-wait 500
