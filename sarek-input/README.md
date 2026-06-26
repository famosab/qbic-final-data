This folder holds input files for running sarek on the benchmarking data.

IMGAG dataset:
```bash
nextflow run nf-core/sarek -r 3.6.1 -profile m3c \
-work-dir work-imgag \
-c custom.config \
--input imgag.csv \
--outdir imgag \
--tools freebayes,strelka,muse,mutect2,varlociraptor \
--intervals Twist_Custom_Exome_IMGAG_v2.bed
--wes \
-resume
```

SEQC2 dataset (WES samples):
```bash
nextflow run nf-core/sarek -r 3.6.1 -profile m3c \
-work-dir work-seqc2 \
-c custom.config \
--input seqc2-wes.csv \
--outdir seqc2 \
--tools freebayes,strelka,muse,mutect2,varlociraptor \
--intervals seqc2_hg38.exome_regions.bed
--wes \
-resume
```

For skipping BQSR we add
```bash
--skip_tools baserecalibrator \
```
to the run command.

For using a custom PON when running the IMGAG benchmark with mutect2 we add
```bash
--germline_resource gnomad_hg38.stripped.vcf.gz \
--germline_resource_tbi gnomad_hg38.stripped.vcf.gz.tbi \
--pon pon_hg38.stripped.vcf.gz \
--pon_tbi pon_hg38.stripped.vcf.gz.tbi \
```
to the run command.