We realized that we are missing calls because we used the standard PON for mutect calling.

```bash
conda create -n gsutil gsutil 
conda activate gsutil
```

1. Fetch the WES/WGS panel-of-normals generated using GATK on 1000genomes data:
```bash
gsutil -m cp gs://gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz{,.tbi} .
```

2. Fetch the WES/WGS gnomAD 2 VCF for use as a germline resource with MuTect2:
```bash
gsutil -m cp gs://gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz{,.tbi} .
```

3. Get the IMGAG truth from zenodo
```bash
curl https://zenodo.org/records/15120550/files/NA12878.unique.vcf.gz -o NA12878.unique.vcf.gz
bcftools index --tbi NA12878.unique.vcf.gz 
```

4. Compare / Remove the truth variants from the PON and germline resource
```bash
bcftools isec -C -w 1 -p subset_pon 1000g_pon.hg38.vcf.gz NA12878.unique.vcf.gz
bcftools isec -C -w 1 -p subset_gnomad af-only-gnomad.hg38.vcf.gz NA12878.unique.vcf.gz
```

Then rename the resulting 0000.vcf file and bgzip and index it.

We can use these files with sarek by adding the following to the run command:
````bash
--germline_resource gnomad_hg38.stripped.vcf.gz \
--germline_resource_tbi gnomad_hg38.stripped.vcf.gz.tbi \
--pon pon_hg38.stripped.vcf.gz \
--pon_tbi pon_hg38.stripped.vcf.gz.tbi \
```