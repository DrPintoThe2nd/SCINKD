# Sex Chromosome Identification by Negating Kmer Densities (SCINKD)
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densitities and comparing within and between both haplotypes.

The current implementation of this tool uses meryl to count and negate kmers from two genomic haplotypes.

To run: Ensure there are apporximately enough computational resources for the job and then simply run
```
bash scinkd_v0.2.sh hap1.fasta.gz hap2.fasta.gz 
```
For example, to run the pipeline on a squamate genome on a machine with 12 available threads and 16Gb of available RAM, the command would look like this:
```
bash scinkd_v0.2.sh Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```
