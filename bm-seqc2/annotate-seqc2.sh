#!/bin/bash

IN_DIR="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-06/qbic-final-data/bm-seqc2/results/fp-fn/callsets"
OUT_DIR="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-06/qbic-final-data/bm-seqc2/results/fp-fn-cov-ann"
SCRIPT="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/pm4onco-ap4-benchmark/scripts/annotate-coverage.sh"
FORMAT="script"  # or "vembrane" if needed

COV_BED_FFPE="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/seqc2/seqc2-ffpe-truth/seqc2-ffpe.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/seqc2-ffpe-*-skip-bqsr.*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_FFPE" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"

#!/bin/bash

COV_BED_WES="/mnt/lustre/groups/nahnsen/nahbu450/pm4onco/2026-01/truth-evaluation/seqc2/seqc2-wes-truth/seqc2-wes.quantized.sorted.bed"

mkdir -p "$OUT_DIR"

for infile in "$IN_DIR"/seqc2-wes-*-skip-bqsr.*.tsv; do
    basename=$(basename "$infile" .tsv)
    outfile="$OUT_DIR/${basename}.csv"
    
    echo "Processing: $basename"
    "$SCRIPT" --in "$infile" --out "$outfile" --bed "$COV_BED_WES" --format "$FORMAT"
done

echo "Done! Output files in: $OUT_DIR"
