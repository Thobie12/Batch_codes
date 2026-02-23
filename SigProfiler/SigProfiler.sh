#!/bin/bash
#SBATCH --job-name=LearnReadOrientationModel
#SBATCH --output=/cluster/home/t922316uhn/PLO/GATK/sigprof_CA-07_%j.out
#SBATCH --error=/cluster/home/t922316uhn/PLO/GATK/sigprof_CA-07_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=256G
#SBATCH --partition=superhimem

module load python3

python << EOF
import SigProfilerAssignment as spa
from SigProfilerAssignment import Analyzer as Analyze

samples = "/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/OICRM4CA-07-01-P/vcf/"
output = "/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/OICRM4CA-07-01-P"

Analyze.cosmic_fit(
    samples=samples,
    output=output,
    input_type="vcf",
    context_type="96",
    collapse_to_SBS96=True,
    cosmic_version="3.4",
    exome=False,
    genome_build="GRCh38",
    signature_database=None,
    exclude_signature_subgroups=None,
    export_probabilities=True,
    export_probabilities_per_mutation=True,
    make_plots=True,
    sample_reconstruction_plots="pdf",
    verbose=True
)
EOF
