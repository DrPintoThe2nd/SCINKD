# Sex Chromosome Identification by Negating Kmer Densities (SCINKD), version 0.1
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes

The current implementation of this tool uses jellyfish and bbmap to count and negate kmers from two genomic haplotypes. Currently, this is computationally prohibitive (specifically the bbmap portion) requiring excessive amounts of RAM, approximately 100Gb or RAM per 1Gb of haploid genome size.

To run: Ensure there are apporximately enough computational resources for the job and then simply run
```
bash scinkd_v0.1.sh hap1.fasta hap2.fasta <threads> <genome size [must be an interger, rounded up to the nearest Gb]>
```
For example, to run the pipeline on a larger squamate genome (2.5Gb) on a machine with 24 available threads, the command would look like this:
```
bash scinkd_v0.1.sh hap1.fasta hap2.fasta 24 3
```
