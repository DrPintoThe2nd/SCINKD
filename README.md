# Sex Chromosome Identification by Negating Kmer Densities (SCINKD), version 2
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.
SCINKD [v2.0] is a Snakemake implementation (and additional outputting) of scinkd (v0.2).

At its core, SCINKD is a theoretical framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes (smallest SDR identified to-date has been ~5Mb).

The current implementation of this tool uses meryl to count and negate kmers from two genomic haplotypes.
Previous implementations relied on multiple piecemeal programs that tooks upwards of 5 hours to complete, the current version (0.2) should take ~30 minutes from takeoff to touchdown.

Running on the a test dataset on a cluster with a 24 core/36Gb RAM allocation reported these times upon successful completion:
```
time snakemake --use-conda -c 24 -s SCINKD/SCINKD.v2.0.beta.snakefile
real    35m2.348s
user    111m28.608s
sys     14m56.227s
```

To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -n scinkd meryl=1.4.1 snakemake=7.32.4 pigz r r-dplyr r-ggplot2 samtools --yes
mamba activate scinkd 
```

_**File naming restriction:**_ Both input haplotype fasta files MUST be gzipped (or bgzipped) and MUST end in ".hap1.fasta.gz" and ".hap2.fasta.gz" (or their symbolic link does).

_**WARNING**_ Due to current limitations in the final step of the workflow, runtime scales _linearly_ with the total number of sequences in each haplotype.

_**Disclaimer**_ This technique reports phasing differences between haplotypes, including contaminants, it's important to look deeper into any regions of interest.

For the test dataset provided (https://doi.org/10.6084/m9.figshare.27040678.v2), this could be applied simply via:
```
ln -s Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.p_ctg.FINAL.Genbank.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
ln -s Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.p_ctg.FINAL.Genbank.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```
Then, ensure the config.json file reads:
```
{
	"prefix": "Anniella_stebbinsi_HiFi_2024.asm.hic"
}
```
To run the pipeline on the provided _Anniella_ genome on a machine with 16 available threads (and the default setting of 16Gb of available RAM):
```
snakemake --use-conda   -np -s SCINKD/SCINKD.v2.0.1.beta.snakefile          #dry-run to test inputs
snakemake --use-conda -c 16 -s SCINKD/SCINKD.v2.0.1.beta.snakefile          #run SCINKD
```
Chromosome lengths can be calculated using samtools faidx (column two of the fasta index file):
```
samtools faidx Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
samtools faidx Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```

Template code used in generating these plots is enclosed (Anniella_template.R) and test files useful for replicating these plots are available alongside the test dataset (https://doi.org/10.6084/m9.figshare.27040678.v2).

Downstream plotting establishes the linear relationship between chromosome length and number of haplotype-specific kmers, as well as the sex chromosomes that significantly deviate from this expectation:
![Rplot05](https://github.com/user-attachments/assets/8511ec53-9ccb-4aa6-ac45-bc5e9e945484)

Kmer densities on the Z and W are observably higher:
![Rplot06](https://github.com/user-attachments/assets/13b16d8c-748a-4a2b-86dc-ffb29a0bdd00)

Regions of increased kmer dentities converge on a single part of the chromosome, syntenic with chicken chromosome 11.
![Rplot07](https://github.com/user-attachments/assets/1b84e928-7d3d-4186-9f7e-8ff8995496fe)

[last two steps in the pipeline need to be replaced with a faster python script]

[additional plotting functions to be added]

[additional documentation to be added] 

After implicating a linkage group as a putative sex chromosome, additional anaylses still need to be conducted to validate. I'd recommend starting with a 1:1 haplotype alignment and diving deeper into that using a program like _pafr_ https://github.com/dwinter/pafr or _SVbyEye_ (shown) https://github.com/daewoooo/SVbyEye:
![image](https://github.com/user-attachments/assets/21df933e-c7d8-4a8d-b284-4b85224eec34)
