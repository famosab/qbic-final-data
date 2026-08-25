#!/bin/bash
set -euo pipefail

# Default values
FORMAT="script"
IN=""
OUT_CSV=""
COVBED=""

usage() {
    echo "Usage: $0 --in <input.tsv> --out <output.csv> --bed <coverage.bed> --format <script|vembrane>"
    echo "Options:"
    echo "  --format: 'script' (chromosome/position) or 'vembrane' (CHROM/POS)"
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --in) IN="$2"; shift 2 ;;
        --out) OUT_CSV="$2"; shift 2 ;;
        --bed) COVBED="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        *) usage ;;
    esac
done

[[ -z "$IN" || -z "$OUT_CSV" || -z "$COVBED" ]] && usage
mkdir -p "$(dirname "$OUT_CSV")"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
GENOME="$tmp/generated.genome"

# Decompress BED once, then sanitize
COVBED_PLAIN="$tmp/covbed.plain.bed"
if [[ "$COVBED" == *.gz ]]; then
    gzip -dc -- "$COVBED" > "$COVBED_PLAIN"
else
    cat -- "$COVBED" > "$COVBED_PLAIN"
fi

COVBED_CLEAN="$tmp/covbed.clean.bed"
awk 'BEGIN{FS=OFS="\t"}
     {sub(/\r$/, "", $0)}
     NF>=4 && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $3>$2 {print}' \
    "$COVBED_PLAIN" > "$COVBED_CLEAN"

[[ ! -s "$COVBED_CLEAN" ]] && { echo "ERROR: no valid rows in BED: $COVBED" >&2; exit 1; }

awk 'BEGIN{OFS="\t"}
     !seen[$1]++{order[++n]=$1}
     {if($3 > max[$1]) max[$1]=$3}
     END{for(i=1;i<=n;i++){c=order[i]; print c, max[c]}}' \
     "$COVBED_CLEAN" > "$GENOME"

BED_HAS_CHR=$(awk 'NR==1{print ($1 ~ /^chr/ ? 1 : 0); exit}' "$COVBED_CLEAN")

# 2. Setup Format Mapping
if [[ "$FORMAT" == "vembrane" ]]; then
    CHRM_COL="CHROM"; POS_COL="POS"
else
    CHRM_COL="chromosome"; POS_COL="position"
fi

# 2. Convert TSV to BED (0-indexed)
awk -v c_name="$CHRM_COL" -v p_name="$POS_COL" -v add_chr="$BED_HAS_CHR" '
    BEGIN {FS=OFS="\t"}
    NR==1 {
        for(i=1; i<=NF; i++) {
            if($i == c_name) c=i
            if($i == p_name) p=i
        }
        if(!c || !p){
            print "ERROR: missing columns " c_name "/" p_name " in " FILENAME > "/dev/stderr"
            exit 2
        }
        next
    }
    {
        chrom = $c
        if (add_chr == 1 && chrom !~ /^chr/) chrom = "chr" chrom
        if (add_chr == 0 && chrom ~ /^chr/) sub(/^chr/, "", chrom)
        print chrom, $p-1, $p, FNR-1
    }
' "$IN" > "$tmp/vars.bed"

[[ ! -s "$tmp/vars.bed" ]] && { echo "ERROR: no variant rows parsed from $IN" >&2; exit 1; }

# 4. Sort and Intersect
bedtools sort -g "$GENOME" -i "$tmp/vars.bed" > "$tmp/vars.sorted.bed"

bedtools intersect -sorted -g "$GENOME" -loj \
    -a "$tmp/vars.sorted.bed" \
    -b "$COVBED_CLEAN" > "$tmp/with_cov.bed"

# 5. Join back and Output formatted Semicolon CSV
awk '
    BEGIN { FS="\t"; OFS=";" }
     NR==FNR {
         c=$NF
         if(c ~ /^[0-9]+:[0-9]+$/){split(c,a,":"); c=a[1]}
         if(c!=".") cov[$4]=c
         next
     }
     {
         sub(/\r$/, "", $0)
         if (FNR == 1) val = "Coverage"
         else {
             idx = FNR-1
             val = (idx in cov) ? cov[idx] : "."
         }
         $(NF+1) = val
         for(i=1; i<=NF; i++) {
             gsub(/"/, "\"\"", $i)
             if($i ~ /[";]/) $i = "\"" $i "\""
         }
         print
     }
' "$tmp/with_cov.bed" "$IN" > "$OUT_CSV"

# --- Cleanup ---
rm -rf "$tmp"
echo "Success: $OUT_CSV generated using $(basename "$COVBED")"