#!/bin/bash
#SBATCH --job-name=FragmentBed
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Fragmentbed_%j.log
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Fragmentbed_%j.log
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --partition=superhimem

# Load modules
module load samtools

# Input and output
CRAM="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram"
OUTBED="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Fragmentomics/OICRM4CA-07-01-P_fragment.bed"

# Stream CRAM, filter reads, compute BED columns
samtools view -h "$CRAM" \
| awk -v OFS="\t" '
BEGIN {
    print "Tag","Chrom","Start","End","MAPQ","Strand","FragmentLength","5primeSeq","3primeSeq"
}
{
    # Skip header lines
    if($0 ~ /^@/) next

    # Only include reads with tm:Z:A|AQ|AQZ|AZ
    tm_found=0
    for(i=12;i<=NF;i++) if($i ~ /^tm:Z:(A|AQ|AQZ|AZ)$/) tm_found=1
    if(!tm_found) next

    # Extract main fields
    tag=$1
    chr=$3
    start=$4
    mapq=$5
    seq=$10

    # Compute end and fragment length
    end=start+length(seq)-1
    tlen=length(seq)

    # Extract 5' and 3' sequences
    seq5=substr(seq,1,10)
    seq3=substr(seq,length(seq)-9,10)

    # Determine strand from st:Z and et:Z
    st=""; et=""; strand=""
    for(i=12;i<=NF;i++){
        if($i~/^st:Z:/){split($i,a,":"); st=a[3]}
        if($i~/^et:Z:/){split($i,a,":"); et=a[3]}
    }
    if(st=="PLUS" && et=="PLUS") strand="+"
    else if(st=="MINUS" && et=="MINUS") strand="-"
    else strand=""

    # Print tab-delimited BED line
    print tag, chr, start, end, mapq, strand, tlen, seq5, seq3
}
' > "$OUTBED"
