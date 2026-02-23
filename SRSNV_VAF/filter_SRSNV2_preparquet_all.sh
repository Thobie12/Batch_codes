#!/bin/bash
#SBATCH --job-name=vcf_cleaning
#SBATCH --output=vcf_cleaning_%j.log
#SBATCH --error=vcf_cleaning_%j.err
#SBATCH --time=24:00:00               # 1 hour max runtime
#SBATCH --mem=64G                    # memory allocation
#SBATCH --cpus-per-task=1            # single CPU
#SBATCH --partition=superhimem         # adjust based on your cluster

echo "Job started at: $(date)"

VCF_IN="OICRM4CA-07-01-P.rs.training_regions.vcf.gz"
VCF_OUT="OICRM4CA-07-01-P.rs.training_regions.clean.vcf.gz"
BAD_POSITIONS="bad_positions.txt"

echo "Step 1: Finding bad variants with non-ACGT flanking INFO fields"
bcftools query -f '%CHROM\t%POS\t[%INFO/X_NEXT1]\t[%INFO/X_PREV1]\t[%INFO/X_NEXT2]\t[%INFO/X_PREV2]\t[%INFO/X_NEXT3]\t[%INFO/X_PREV3]\n' "$VCF_IN" \
  | awk '{for (i=3;i<=8;i++) if ($i !~ /^[ACGT]$/) {print $1"\t"$2; break}}' \
  > "$BAD_POSITIONS"
echo "Found $(wc -l < $BAD_POSITIONS) bad positions"

echo "Step 2: Filtering out bad positions from VCF"
bcftools view -T ^"$BAD_POSITIONS" "$VCF_IN" -Oz -o "$VCF_OUT"

echo "Step 3: Indexing clean VCF"
bcftools index -t "$VCF_OUT"

echo "Job finished at: $(date)"
echo "Cleaned VCF written to $VCF_OUT"

