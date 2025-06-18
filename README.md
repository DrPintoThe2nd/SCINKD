# Sex Chromosome Identification by Negating Kmer Densities (SCINKD)
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.
SCINKD [v2.1.0] is a Snakemake implementation of the below conceptual framework.

SCINKD is a framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes (smallest SDR identified to-date has been ~1Mb).

Here is a graphical represention of these points:
![SCINKD_mock_plot_complex_v2 0](https://github.com/user-attachments/assets/aea48ea0-4136-40b3-9948-1fa8d40f18b8)


This implementation of SCINKD uses meryl to count and negate kmers from two genomic haplotypes.

SCINKD/SCINKD.v2.1.0.FULL   = Most up-to-date SCINKD pipeline (without kmer compression).
SCINKD/SCINKD.v2.1.0.GREEDY = Most up-to-date SCINKD pipeline with added homopolymer compression reduces runtime many-fold, but reduces sensitivity enormously (and file sizes), This may be optimal for known systems with strong signals (e.g. mammals and birds) or in taxa with large genomes ~10Gb+.

Running on the test dataset on a cluster with a 24 core/24Gb RAM allocation reported these times upon successful completion:
```
time snakemake --use-conda -c 24 -s SCINKD/SCINKD.v2.1.0.FULL.snakefile
real    19m49.171s
user    37m25.996s
sys     1m2.541s

time snakemake --use-conda -c 24 -s SCINKD/SCINKD.v2.1.0.GREEDY.snakefile
real    6m22.552s
user    13m42.636s
sys     0m37.158s
```

To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -n scinkd meryl=1.4.1 snakemake=7.32.4 pigz r r-dplyr r-ggplot2 samtools --yes
mamba activate scinkd 
```

_**File naming restriction:**_ Both input haplotype fasta files MUST be gzipped (or bgzipped) and MUST end in ".hap1.fasta.gz" and ".hap2.fasta.gz" (or their symbolic link does).

_**Disclaimer**_ This technique reports phasing differences between haplotypes, including contaminants, it's important to look deeper into any regions of interest.

For the test dataset provided (https://doi.org/10.6084/m9.figshare.27040678.v2), this could be applied simply via:
```
wget https://figshare.com/ndownloader/files/49948980
wget https://figshare.com/ndownloader/files/49948983
ln -s 49948980 Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
ln -s 49948983 Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```
Then, ensure the SCINKD/config.json file reads:
```
{
	"prefix": "Anniella_stebbinsi_HiFi_2024.asm.hic"
}
```
To run the pipeline on the provided _Anniella_ genome on a machine with 24 available threads (and the default setting of 16Gb of available RAM):
```
snakemake --use-conda   -np -s SCINKD/SCINKD.v2.1.0.FULL.snakefile         #dry-run to test inputs
snakemake --use-conda -c 24 -s SCINKD/SCINKD.v2.1.0.GREEDY.snakefile       #run SCINKD in greedy mode for quick testing
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

[additional documentation to be added] 

After implicating a linkage group as a putative sex chromosome, additional anaylses still need to be conducted to validate. I'd recommend starting with a 1:1 haplotype alignment and diving deeper into that using a program like _pafr_ https://github.com/dwinter/pafr or _SVbyEye_ (shown) https://github.com/daewoooo/SVbyEye:
![image](https://github.com/user-attachments/assets/21df933e-c7d8-4a8d-b284-4b85224eec34)

Combining each piece of the SCINKD framework coalesces around a single region in the genome that shows strong evidence of a ZW pattern:
![Anniella_complete](https://github.com/user-attachments/assets/5e56461c-571c-4eb2-ad38-0da43ab2ec1f)


