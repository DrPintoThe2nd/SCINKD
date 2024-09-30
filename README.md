# Sex Chromosome Identification by Negating Kmer Densities (SCINKD)
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes.

The current implementation of this tool uses meryl to count and negate kmers from two genomic haplotypes.

To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -n scinkd meryl=1.4.1 snakemake pigz r r-dplyr r-ggplot2 mashmap --yes
mamba activate scinkd 
```
To run: Ensure there are apporximately enough computational resources for the job and then simply run
```
bash scinkd_v0.2.sh hap1.fasta.gz hap2.fasta.gz 
```
For example, to run the pipeline on a squamate genome on a machine with 12 available threads and 16Gb of available RAM, the command would look like this for these test data (https://doi.org/10.6084/m9.figshare.27040678.v1):
```
bash scinkd_v0.2.sh Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.p_ctg.FINAL.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.p_ctg.FINAL.fasta.gz
```
Version 0.2 prints final outputs to stdout. These outputs can be recovered to a file simply by:
```
paste hap1-minus-hap2.txt hap1-minus-hap2.out > hap1-minus-hap2.results
paste hap2-minus-hap1.txt hap2-minus-hap1.out > hap2-minus-hap1.results
```
