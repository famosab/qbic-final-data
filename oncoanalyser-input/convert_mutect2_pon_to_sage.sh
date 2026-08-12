#!/usr/bin/env bash
# Convert a Mutect2-style PON VCF (from Sarek) to SAGE PON TSV format (for oncoanalyser).
#
# SAGE PON TSV format (tab-separated, 7 columns):
#   Chromosome  Position  Ref  Alt  SampleCount  MaxReadCount  TotalReadCount
#
# Input VCF: Mutect2 PON sites-only VCF with per-sample FORMAT/INFO fields.
#
# Usage: bash convert_mutect2_pon_to_sage.sh <input.vcf.gz> <output.tsv.gz>
#
# Uses awk (aggregation) + sort (ordering) + gzip (compression).
# No Python needed.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <input.vcf.gz> <output.tsv.gz>" >&2
    exit 1
fi

input_vcf="$1"
output_tsv="$2"

if [[ ! -f "$input_vcf" ]]; then
    echo "Error: $input_vcf not found" >&2
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# Phase 1: awk aggregates allele counts across all samples per variant,
#          outputting one TSV line per variant with sample_count, max_read_count, total_read_count
# Auto-detects format:
#   - New GATK (INFO=TumorAltAlleleCounts,...)
#   - Old Mutect2 (FORMAT with AD field, per-sample columns)
#   - Fallback (sites-only, no count info — counts variant as seen once)
zcat "$input_vcf" | awk -F'\t' '
BEGIN { OFS="\t" }
/^#/ { next }

{
    chrom = $1
    pos   = $2 + 0
    ref   = $4
    alt   = $5
    info  = $8

    # Parse INFO fields
    split("", info_map)
    n = split(info, fields, ";")
    for (i = 1; i <= n; i++) {
        if (index(fields[i], "=") > 0) {
            split(fields[i], kv, "=")
            info_map[kv[1]] = kv[2]
        }
    }

    # --- New GATK CreateSomaticPanelOfNormals (INFO-based) ---
    if ("TumorAltAlleleCounts" in info_map) {
        split("", counts)
        m = split(info_map["TumorAltAlleleCounts"], counts, ",")
        sc = 0; mx = 0; tot = 0
        for (j = 1; j <= m; j++) {
            c = counts[j] + 0
            if (c > 0) sc++
            if (c > mx) mx = c
            tot += c
        }
        key = chrom "\t" pos "\t" ref "\t" alt
        out[key] = sc "\t" mx "\t" tot
        next
    }

    # --- Old Mutect2 PON (FORMAT column per sample) ---
    # Only proceed if we have sample columns and AD in FORMAT
    if (NF < 10) next
    if (index($9, "AD") == 0) next

    # Find AD index in FORMAT string
    split("", fmt_fields)
    nf = split($9, fmt_fields, ":")
    ad_idx = 0
    for (i = 1; i <= nf; i++) {
        if (fmt_fields[i] == "AD") { ad_idx = i; break }
    }
    if (ad_idx == 0) next

    # Iterate over sample columns
    for (s = 10; s <= NF; s++) {
        split("", sfields)
        ns = split($s, sfields, ":")
        if (ad_idx > ns) continue
        split("", ad_values)
        na = split(sfields[ad_idx], ad_values, ",")
        alt_count = (na > 1) ? (ad_values[2] + 0) : 0
        if (alt_count > 0) {
            key = chrom "\t" pos "\t" ref "\t" alt
            if (key in out) {
                split(out[key], old, "\t")
                out[key] = (old[1]+0) + 1 "\t" ( (old[2]+0) > alt_count ? (old[2]+0) : alt_count ) "\t" (old[3]+0) + alt_count
            } else {
                out[key] = "1\t" alt_count "\t" alt_count
            }
        }
    }
    next
}

END {
    for (key in out) {
        print key "\t" out[key]
    }
}
' > "$tmpfile"

# Phase 2: sort by chromosome, position, ref, alt
# chr sort: sort human chromosomes (1-22, X, Y, MT) then chr strings
sort -t$'\t' -k1,1 -k2,2n -k3,3 -k4,4 "$tmpfile" | \
{
    # Write header
    printf 'Chromosome\tPosition\tRef\tAlt\tSampleCount\tMaxReadCount\tTotalReadCount\n'
    # Write sorted data
    cat
} | gzip > "$output_tsv"

variant_count=$(zcat "$output_tsv" | tail -n +2 | wc -l)
echo "Converted $variant_count variants to SAGE PON format: $output_tsv"