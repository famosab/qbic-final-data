# QBiC final data

This repository holds 
- instructions how to run nf-core/sarek on the PM4Onco benchmarks (see [sarek-input](./sarek-input/))
- the cluster specific configuration for the benchmarking workflow (see [m3c/config.yaml](./m3c/config.yaml))
- benchmark folders with the final VCFs ([bm-imgag/imgag/](./bm-imgag/imgag/) and [bm-seqc2/seqc2/](./bm-seqc2/seqc2/))
- the final csv files which are annotated with continuous coverage information (see f.ex. [bm-imgag/annotate-imgag.sh](./bm-imgag/annotate-imgag.sh))

The files were created by running nf-core/sarek (see [README](./sarek-input/README.md)), then the [dna-seq-benchmark](github.com/snakemake-workflows/dna-seq-benchmark) workflow with the following command:
```
snakemake --cache --profile ../m3c
```
and afterwars the respective annotation script.