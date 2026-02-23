#!/bin/bash
#SBATCH --job-name=FragmentBed
#SBATCH --output=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Fragmentbed_%j.log
#SBATCH --error=/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Batch/Fragments/logs/Fragmentbed_%j.log
#SBATCH --time=6-24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=pughlab

# Load modules
module load samtools
module load pigz

# Input and output
CRAM="/cluster/projects/pughlab/myeloma/external_data/ultimagen-oicr/Crams/OICRM4CA-07-01-P.cram"
OUTBED="/cluster/projects/pughlab/myeloma/projects/MM_cell_drugs/WGS_Pipeline/Fragmentomics/OICRM4CA-07-01-P_fragment_trimmed.bed.gz"

# Adapter / artifact sequences to trim
ADAPTERS=("CATCACCGACTGCCCATAGAGAGCTGAGACTGCCAAGGCACACAGGGGATAGG" \
          "ACATATGTGCGCG" \
          "CATGAGCAGCAT" \
          "CATCACCGACTGCCCATAGAGAGCT")

# Process CRAM → filter → trim → compress
samtools view -h -q 20 "$CRAM" \
| grep -E 'tm:Z:(A|AQ|AQZ|AZ)' \
| awk -v OFS="\t" -v adapters="${ADAPTERS[*]}" '
BEGIN {
    split(adapters, trim_seqs)
    print "Tag","Chrom","Start","End","MAPQ","Strand","FragmentLength","5primeSeq","3primeSeq"
}

function trim_seq(seq, seq_trim, s_len, t_len, i, match_count, j) {
    s_len = length(seq)
    seq_trim = seq
    for(i in trim_seqs) {
        t_len = length(trim_seqs[i])
        # Trim 5
        match_count = 0
        for(j=1; j<=t_len && j<=s_len; j++)
            if(substr(seq,j,1)==substr(trim_seqs[i],j,1)) match_count++
        if(match_count/t_len >= 0.8) seq_trim = substr(seq,t_len+1)

        # Trim 3
        match_count = 0
        for(j=0; j<t_len && j<s_len; j++)
            if(substr(seq,s_len-j,1)==substr(trim_seqs[i],t_len-j,1)) match_count++
        if(match_count/t_len >= 0.8) seq_trim = substr(seq_trim,1,length(seq_trim)-t_len)
    }
    return seq_trim
}

$0 !~ /^@/ {
    tag=$1
    chr=$3
    start=$4
    mapq=$5
    seq=$10

    seq = trim_seq(seq)
    end = start + length(seq) - 1
    tlen = length(seq)
    seq5 = substr(seq,1,10)
    seq3 = substr(seq,length(seq)-9,10)

    strand = ($0 ~ /st:Z:PLUS/ && $0 ~ /et:Z:PLUS/) ? "+" : \
              ($0 ~ /st:Z:MINUS/ && $0 ~ /et:Z:MINUS/) ? "-" : ""

    print tag, chr, start, end, mapq, strand, tlen, seq5, seq3
}' | pigz -p 8 > "$OUTBED"
