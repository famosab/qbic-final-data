#!/bin/bash

IN_DIR="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-06/qbic-final-data/bm-imgag/results/fp-fn/callsets"
OUT_DIR="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-06/qbic-final-data/bm-imgag/results/fp-fn-cov-ann"
SCRIPT="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/pm4onco-ap4-benchmark/scripts/annotate-coverage.sh"
FORMAT="script"  # or "vembrane" if needed

# imgag-5
COV_BED_5="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/imgag/imgag-5-truth/imgag-5.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/imgag-5-ukes*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_5" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"

# imgag-10
COV_BED_10="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/imgag/imgag-10-truth/imgag-10.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/imgag-10-ukes*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_10" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"

# imgag-20
COV_BED_20="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/imgag/imgag-20-truth/imgag-20.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/imgag-20-ukes*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_20" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"

# imgag-40
COV_BED_40="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/imgag/imgag-40-truth/imgag-40.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/imgag-40-ukes*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_40" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"