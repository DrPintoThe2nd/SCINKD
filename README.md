# Sex Chromosome Identification by Negating Kmer Densities (SCINKD), version 2
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.
SCINKD [v2.0] is a Snakemake implementation (and additional outputting) of scinkd (v0.2).

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes.

The current implementation of this tool uses meryl to count and negate kmers from two genomic haplotypes.
Previous implementations relied on multiple piecemeal programs that tooks upwards of 5 hours to complete, the current version (0.2) should take ~30 minutes from takeoff to touchdown.

Running on the a test dataset on a cluster with a 24 core/36Gb RAM allocation reported these times upon successful completion:
```
time snakemake --use-conda -c 24 -s SCINKD.v2.0.beta.snakefile
real    35m2.348s
user    111m28.608s
sys     14m56.227s
```

To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -n scinkd meryl=1.4.1 snakemake pigz r r-dplyr r-ggplot2 mashmap samtools --yes
mamba activate scinkd 
```

_**File naming restriction:**_ Both input haplotype fasta files MUST be gzipped (or bgzipped) and MUST end in ".hap1.fasta.gz" and ".hap2.fasta.gz"

For the test dataset provided (https://doi.org/10.6084/m9.figshare.27040678.v1), this could be applied simply via:
```
mv Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.p_ctg.FINAL.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
mv Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.p_ctg.FINAL.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```
Then, ensure the config.json file reads:
```
{
	"prefix": "Anniella_stebbinsi_HiFi_2024.asm.hic"
}
```
To run the pipeline on the provided _Anniella_ genome on a machine with 16 available threads (and the default setting of 16Gb of available RAM):
```
snakemake --use-conda   -np -s SCINKD.v2.0.beta.snakefile          #dry-run to test inputs
snakemake --use-conda -c 16 -s SCINKD.v2.0.beta.snakefile          #run SCINKD
```
Chromosome lengths can be calculated using samtools faidx (column two of the fasta index file):
```
samtools faidx <haplotype_1>.fasta
samtools faidx <haplotype_2>.fasta
```

Downstream plotting establishes the linear relationship between chromosome length and number of haplotype-specific kmers, as well as the sex chromosomes that significantly deviate from this expectation:
![Picture1](https://github.com/user-attachments/assets/0ea3de57-055d-46b3-8a85-a8ec2e7da77e)


[additional documentation to be added] 
