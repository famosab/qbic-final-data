# Running nf-core/oncoanalyser with a Custom PON

> **Key difference from Sarek:** `oncoanalyser` does **not** have a `--pon` CLI parameter like Sarek does. The PON (Panel of Normals) is baked into the WiGiTS/HMF reference data and must be overridden via configuration.

## How oncoanalyser Uses PON

Oncoanalyser uses the Hartwig WiGiTS toolkit, which manages PON internally through two separate mechanisms:

| Tool | PON Artifacts | Source |
|------|--------------|--------|
| **SAGE** (SNV/indel calling) | `sage_pon` — germline PON for filtering common variants | `hmf_data_paths[genome].sage_pon` |
| **ESVEE** (SV calling) | `esvee_pon_breakends` + `esvee_pon_breakpoints` — SV PON | `hmf_data_paths[genome].esvee_pon_breakends` + `esvee_pon_breakpoints` |
| **PAVE** (somatic annotation) | `sage_pon` — passed from SAGE output; also uses `pon_artefacts` from panel data (targeted mode) | Reference data |

The matched normal sample in the samplesheet (`sample_type=normal`) is passed **directly** to all calling tools — it is **not** a PON.

## Default PON Files

| Genome | SAGE PON | ESVEE PON Breakends | ESVEE PON Breakpoints |
|--------|----------|--------------------|----------------------|
| GRCh37 | `dna/variants/SageGermlinePon.1000x.37.tsv.gz` | `dna/sv/sgl_pon.37.bed.gz` | `dna/sv/sv_pon.37.bedpe.gz` |
| GRCh38 | `dna/variants/hmf_wgs_sage_pon_1000.38.tsv.gz` | `dna/sv/sgl_pon.38.bed.gz` | `dna/sv/sv_pon.38.bedpe.gz` |

These files are shipped in the HMF pipeline resources tarballs (e.g. `hmf_pipeline_resources.38_v2.3.0--2.tar.gz`).

---

## Option 1: Override via Custom Config (Recommended)

If you have a custom PON file (e.g. your own `pon_hg38.stripped.vcf.gz` from Sarek), you can override the reference data paths in a config file.

### Step 1: Place your custom PON file

```bash
# Example: put your custom PON in your reference data directory
mkdir -p /path/to/custom_hmf_data/dna/variants
cp pon_hg38.stripped.vcf.gz /path/to/custom_hmf_data/dna/variants/
gzip /path/to/custom_hmf_data/dna/variants/pon_hg38.stripped.vcf.gz
```

### Step 2: Create a config file to override the HMF data paths

```groovy title="custom_hmf_data.config"
params {
    // Point to a directory (or tar.gz) containing your custom HMF reference data
    ref_data_hmf_data_path = "/path/to/custom_hmf_data/"

    // Override just the PON files you need
    hmf_data_paths {
        '38' {
            // Override SAGE PON — must be a TSV.gz file in the WiGiTS PON format
            sage_pon = 'dna/variants/pon_hg38.stripped.vcf.gz'
        }
    }
}
```

> **Important:** The `sage_pon` file must be in the WiGiTS SAGE PON format (TSV.gz), **not** a VCF. If your PON is in VCF format (like from Sarek's Mutect2), you must convert it to the SAGE PON format first. See the conversion section below.

### Step 3: Run oncoanalyser with your custom config

```bash
nextflow run nf-core/oncoanalyser \
  -revision 2.3.0 \
  -config custom_hmf_data.config \
  -profile m3c \
  --mode wgts \
  --genome GRCh38_hmf \
  --input samplesheet.csv \
  --outdir output/
```

---

## Option 2: Full Custom HMF Data Directory

If you want to replace **all** HMF reference data (not just the PON), point `ref_data_hmf_data_path` to a full directory with the expected file structure:

```groovy title="full_custom_hmf_data.config"
params {
    ref_data_hmf_data_path = "/path/to/full/custom/hmf_data/"
}
```

The directory must contain all files referenced in `hmf_data_paths['38']` from `conf/hmf_data.config`. You can start from the official tarball and modify:

```bash
# Download and extract the official data
wget https://pub-cf6ba01919994c3cbd354659947f8.r2.dev/hmf_reference_data/hmftools/hmf_pipeline_resources.38_v2.3.0--2.tar.gz
tar -xzf hmf_pipeline_resources.38_v2.3.0--2.tar.gz
cp -r hmf_pipeline_resources.38_v2.3.0--2 /path/to/custom/hmf_data/

# Now replace the PON file(s) in-place
cp pon_hg38.stripped.vcf.gz /path/to/custom/hmf_data/dna/variants/
```

---

## Converting a Sarek PON to SAGE PON Format

The oncoanalyser SAGE PON is a TSV (tab-separated) file with **7 columns**:
```
Chromosome  Position  Ref  Alt  SampleCount  MaxReadCount  TotalReadCount
```

Your Sarek Mutect2 PON VCF has per-sample FORMAT columns with allele depth (AD) info. You need to aggregate those across all normal samples.

### Conversion on the cluster

The bash script is in this repo. No Python needed — uses awk + sort + gzip.

**Step 1: Locate your Sarek PON VCF**

```bash
# Find your stripped PON VCF (adjust path as needed)
find /path/to/sarek-output -name "pon_hg38*" -o -name "*pon*.vcf.gz" | head -5
```

**Step 2: Inspect the VCF header to confirm FORMAT fields**

```bash
# Show the header to check FORMAT structure
zcat pon_hg38.stripped.vcf.gz | head -20

# Show a data line to see FORMAT/AD values
grep -v '^#' pon_hg38.stripped.vcf.gz | head -3
```

If you see `TumorAltAlleleCounts` in INFO fields → use the new format parser (auto-detected).
If you see FORMAT with `AD` (allele depths) → use the old format parser (auto-detected).

**Step 3: Run the conversion**

```bash
# Convert your Sarek PON VCF to SAGE TSV format
bash /path/to/qbic-final-data/convert_mutect2_pon_to_sage.sh \
    pon_hg38.stripped.vcf.gz \
    sage_pon_hg38.tsv.gz

# Verify the output
zcat sage_pon_hg38.tsv.gz | head -5
# Should show: Chromosome  Position  Ref  Alt  SampleCount  MaxReadCount  TotalReadCount
```

**Step 4: Set up the directory structure**

```bash
# Create the directory structure expected by hmf_data_paths
mkdir -p /path/to/custom_hmf_data/dna/variants

# Move the converted PON into place
mv sage_pon_hg38.tsv.gz /path/to/custom_hmf_data/dna/variants/
```

**Step 5: Create the config override**

> **GRCh37 users:** Change `'38'` to `'37'` and `sage_pon` value to `sage_pon_hg37.tsv.gz`

```groovy title="custom_hmf_data.config"
params {
    ref_data_hmf_data_path = "/path/to/custom_hmf_data/"
    hmf_data_paths {
        '38' {
            sage_pon = 'dna/variants/sage_pon_hg38.tsv.gz'
        }
    }
}
```

**Step 6: Run oncoanalyser**

```bash
nextflow run nf-core/oncoanalyser \
  -revision 2.3.0 \
  -config custom_hmf_data.config \
  -profile m3c \
  --mode wgts \
  --genome GRCh38_hmf \
  --input samplesheet.csv \
  --outdir output/
```

### Alternative: Build PON from normal BAMs (no VCF conversion needed)

If you have the original normal BAMs, skip the VCF conversion entirely and let oncoanalyser build the PON:

```bash
# Create samplesheet with ONLY normal samples
cat > normals.csv <<EOF
group_id,subject_id,sample_id,sample_type,sequence_type,filetype,filepath
NORM1,NORM1,NORM1-N,normal,dna,bam,/path/to/NORM1-N.dna.bam
NORM2,NORM2,NORM2-N,normal,dna,bam,/path/to/NORM2-N.dna.bam
# ... add all your normal samples
EOF

# Build PON reference data from your normals
nextflow run nf-core/oncoanalyser \
  -revision 2.3.0 \
  -profile m3c \
  --mode panel_resource_creation \
  --genome GRCh38_hmf \
  --input normals.csv \
  --outdir pon_build_output/

# The PON artefacts are at: pon_build_output/reference_data/*/pave.somatic_artefacts.38.tsv
```

Then point `ref_data_panel_data_path` to a directory containing `pave.somatic_artefacts.38.tsv` and set `pon_artefacts` in `panel_data_paths`.

---

## Using a Matched Normal Sample (the standard approach)

For most use cases, the standard approach is simply to provide the matched normal in the samplesheet — no custom PON needed:

```csv title="samplesheet.csv"
group_id,subject_id,sample_id,sample_type,sequence_type,filetype,filepath
PATIENT1,PATIENT1,PATIENT1-N,normal,dna,bam,/path/to/PATIENT1-N.dna.bam
PATIENT1,PATIENT1,PATIENT1-T,tumor,dna,bam,/path/to/PATIENT1-T.dna.bam
```

The normal BAM is used directly by SAGE (somatic calling), PAVE, PURPLE, ESVEE, etc. The PON from the HMF reference data is used for germline filtering within those tools.

---

## Comparison: Sarek vs oncoanalyser PON Setup

| Feature | Sarek | oncoanalyser |
|---------|-------|-------------|
| PON CLI parameter | `--pon pon.vcf.gz` | **None** |
| PON source | CLI parameter or config | HMF reference data tarball |
| PON format (Mutect2) | VCF | Not applicable (uses SAGE, not Mutect2) |
| PON format (SAGE) | Via `--sage_pon` | Via `hmf_data_paths[genome].sage_pon` |
| Override method | CLI args or `-c custom.config` | Config override of `hmf_data_paths` or `ref_data_hmf_data_path` |

---

## Quick Reference: Key Config Parameters

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `ref_data_hmf_data_path` | Path to HMF reference data directory or tar.gz | Auto-downloaded from Hartwig CDN |
| `hmf_data_paths['38'].sage_pon` | SAGE germline PON file | `dna/variants/hmf_wgs_sage_pon_1000.38.tsv.gz` |
| `hmf_data_paths['38'].esvee_pon_breakends` | ESVEE SV PON breakends | `dna/sv/sgl_pon.38.bed.gz` |
| `hmf_data_paths['38'].esvee_pon_breakpoints` | ESVEE SV PON breakpoints | `dna/sv/sv_pon.38.bedpe.gz` |

---

## Troubleshooting

**Error: "got bad genome version"** — Make sure `hmf_data_paths` uses the correct version key (`'37'` or `'38'`), not the genome name.

**Error: file not found** — When using `ref_data_hmf_data_path`, the paths in `hmf_data_paths` are **relative** to that base directory.

**Oncoanalyser ignores my custom PON** — Ensure you're not also setting `--mode prepare_reference` with `--ref_data_types wgs`, as this will download fresh reference data and override your config. Use `-config` instead.

---

## See Also

- [nf-core/oncoanalyser usage docs](https://nf-co.re/oncoanalyser/usage)
- [WiGiTS resource file documentation](https://github.com/hartwigmedical/hmftools/blob/master/pipeline/README_RESOURCES.md)
- [Your Sarek custom PON setup](./sarek-input/README.md)