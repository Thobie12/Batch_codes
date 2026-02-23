#!/bin/bash
#SBATCH --job-name=VCF_2way_common_UltimaMatched
#SBATCH --output=VCF_2way_common_UltimaMatched_%j.out
#SBATCH --error=VCF_2way_common_UltimaMatched_%j.err
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --partition=pughlab

module load samtools

# Input VCFs
ULTIMAMATCHED="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/OICRM4CA-07-01-P/Merged/vcf/OICRM4CA-07-01-P_GATKFiltered_ENCODE_RepeatMask_Filtered.PASS.norm.SNP.vcf.gz"
ILLUMINA="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/Illumina/Normalized/TFRIM4_0057_Cf_P_PG_CA-07-01-P-DNA_encode_STR_filtered.norm.PASS.SNP.vcf.gz"

# Output directory
OUTDIR="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/GATK/intersections/CA-07-01-P_2way_UltimaMatched"
mkdir -p $OUTDIR

echo "Running 2-way intersection..."
bcftools isec -p $OUTDIR $ULTIMAMATCHED $ILLUMINA

# Count variants in each category
echo "Counting..."
{
    echo -e "Comparison\tCount"
    echo -e "UltimaMatched_only\t$(zgrep -vc '^#' $OUTDIR/0000.vcf)"
    echo -e "Illumina_only\t$(zgrep -vc '^#' $OUTDIR/0001.vcf)"
    echo -e "Common\t$(zgrep -vc '^#' $OUTDIR/0002.vcf)"
} > $OUTDIR/intersection_counts.tsv

# Create a VCF with only the intersection (shared by both)
echo "Writing intersected VCF..."
bcftools view $OUTDIR/0002.vcf -Oz -o $OUTDIR/UltimaMatched_Illumina_intersection.vcf.gz
tabix -p vcf $OUTDIR/UltimaMatched_Illumina_intersection.vcf.gz

echo "Done."
echo "Counts table: $OUTDIR/intersection_counts.tsv"
echo "Intersect VCF: $OUTDIR/UltimaMatched_Illumina_intersection.vcf.gz"
