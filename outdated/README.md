# Sex Chromosome Identification by Negating Kmer Densities (SCINKD), version 0.2
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes.

The current implementation of this tool uses meryl to count and negate kmers from two genomic haplotypes.
Previous implementations relied on multiple piecemeal programs that tooks upwards of 5 hours to complete, the current version (0.2) should take ~30 minutes from takeoff to touchdown.

Running on the provided test data on a local machine reported these times upon successful completion:
```
real    18m44.287s
user    31m44.943s
sys     0m38.454s
```

To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -n scinkd meryl=1.4.1 snakemake=6.12.3 pigz r r-dplyr r-ggplot2 mashmap --yes
mamba activate scinkd 
```
To run: Ensure there are approximately enough computational resources for the job and then simply run
```
bash SCINKD/scinkd_v0.2.sh hap1.fasta.gz hap2.fasta.gz <RAM (in Gb)> <number of threads> 
```
For example, to run the pipeline on a squamate genome on a machine with 12 available threads and 16Gb of available RAM, the command would look like this for these test data (https://doi.org/10.6084/m9.figshare.27040678.v1):
```
bash SCINKD/scinkd_v0.2.sh Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.p_ctg.FINAL.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.p_ctg.FINAL.fasta.gz 16 12
```
Version 0.2 prints final outputs (total number of kmers per haplotype) to stdout. These outputs can be recovered to a file simply by:
```
paste hap1-minus-hap2.txt hap1-minus-hap2.out > hap1-minus-hap2.results
paste hap2-minus-hap1.txt hap2-minus-hap1.out > hap2-minus-hap1.results
```

Downstream plotting establishes the linear relationship between chromosome length and number of haplotype-specific kmers, as well as the sex chromosomes that significantly deviate from this expectation, e.g. where the two outlier dots located around 1e+08 on the x-axis are the putative sex chromosomes in this species (this plot is produced from v0.2 output).
![Picture1](https://github.com/user-attachments/assets/bb625f46-04f0-456f-afff-ca7974313d86)




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
Downstream plotting establishes the linear relationship between chromosome length and number of haplotype-specific kmers, as well as the sex chromosomes that significantly deviate from this expectation, e.g. where the two outlier dots located around 1e+08 on the x-axis are the putative sex chromosomes in this species (this plot is produced from v0.1 output).
![image](https://github.com/user-attachments/assets/b346e962-48df-40dc-bcf7-950d33cbdb9c)
