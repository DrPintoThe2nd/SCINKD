# Citation
If using this workflow, or developing code from it's underlying framework, please cite its source:

Pinto BJ, Gable SM, Keating SE, Smith CH, Gamble T, Nielsen SV, Wilson MA. (2026). Sex chromosome identification and genome curation from a single individual with SCINKD. _Molecular Biology and Evolution_. 43(4). https://doi.org/10.1093/molbev/msag067

# Sex Chromosome Identification by Negating Kmer Densities (SCINKD)
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a 'pseudo-statistical' method to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.
SCINKD [v2.1.0 or later] is a Snakemake implementation of the below conceptual framework.

SCINKD is a framework to identify sex chromosomes that operates under a few generalized assumptions of a diploid genome.
  1. Polymorphisms are broadly uniform between haplotypes within a single diploid individual.
  2. The density of genetic differences occur at much higher densities on the sex-limited region of the sex chromosomes
  3. This density is then identifiable by isolating haplotype-specific kmer densities and comparing within and between both haplotypes.

There are limitations to this method including--but not limited to--poor phasing deviating from NULL expectations, low per-base quality obscuring signal (low coverage ONT), and low levels of differentiation within the sex-limited region. See the preprint for more information: https://doi.org/10.1101/2025.07.07.660342 

Here is a graphical represention of these points:
![SCINKD_mock_plot_complex_v2 0](https://github.com/user-attachments/assets/aea48ea0-4136-40b3-9948-1fa8d40f18b8)


This implementation of SCINKD uses meryl to count and negate kmers from two genomic haplotypes.

SCINKD/SCINKD.v2.2.4       = Most up-to-date SCINKD pipeline.

SCINKD/SCINKD.v2.2.4.BIG   = Most up-to-date SCINKD pipeline for analysis of genomes >5Gb.

Running on the test dataset on a cluster with a 24 core/24Gb RAM allocation reported these times upon successful completion:
```
time snakemake --use-conda --rerun-incomplete --nolock --cores 24 -s SCINKD/SCINKD.v2.2.4.snakefile
real    10m34.431s
user    51m11.978s
sys     1m43.553s
```
Replacing the previous "GREEDY" version, or genomes larger than ~5Gb, folks can now run SCINKD using the "BIG" workflow. This workflow has been tested on genomes between 10Gb and 20Gb, but requires >2x more resources depending on the genome size. On the same smaller test dataset, marginally increases compute time, but increases I/O and storage footprint ~10-20%):
```

real    11m1.875s
user    56m16.524s
sys     1m43.132s
```
To install:
```
git clone https://github.com/DrPintoThe2nd/SCINKD.git
mamba create -f SCINKD/SCINKD.v2.2.4.environment.yml
mamba activate scinkd2
```

_**File naming restriction:**_ **Both input haplotype fasta files MUST be bgzipped and MUST end in ".hap1.fasta.gz" and ".hap2.fasta.gz"**

_**Disclaimer**_ This technique reports phasing differences between haplotypes, including contaminants, it's important to look deeper into any regions of interest.

For the test dataset provided ([https://doi.org/10.6084/m9.figshare.27040678](https://doi.org/10.6084/m9.figshare.27040678.v3)), this could be applied simply via:
```
wget --content-disposition https://ndownloader.figshare.com/files/49948980
wget --content-disposition https://ndownloader.figshare.com/files/49948983
ln -s Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.p_ctg.FINAL.Genbank.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
ln -s Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.p_ctg.FINAL.Genbank.fasta.gz Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```

**NOTE** There are ongoing issues with the Figshare downloading interface. However, as of February 2026, these assemblies are also available to be downloaded directly from GenBank: hap1: https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_051312515.2/, hap2: https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_051312545.2/

Then, ensure the SCINKD/config.json file reads, where threads and memory are <=1/2 the total available resources for the job:
```
{
	"per_job_threads": 12,
	"per_job_memory": 12,
	"ChrNum": 10,

	"prefix": "Anniella_stebbinsi_HiFi_2024.asm.hic"
}
```
To run the pipeline on the provided _Anniella_ genome on a machine with 24 available threads and assuming 24Gb of available RAM:
```
time snakemake --use-conda --rerun-incomplete --nolock --cores 24 -s SCINKD/SCINKD.v2.2.4.snakefile -n   #dry-run to test installation, inputs, and file structures
time snakemake --use-conda --rerun-incomplete --nolock --cores 24 -s SCINKD/SCINKD.v2.2.4.snakefile      #run SCINKD
```
**v2.2.3 update: Indicies are now generated automatically within the workflow.**
Chromosome lengths can be calculated using samtools faidx (column two of the fasta index file):
```
samtools faidx Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz
samtools faidx Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz
```

As of v2.2.3, default boxplots and dotplots (examples below) are now automated, and output an additional summary file, "<genome_prefix>.plot_data.tsv". For custom plotting as both a png and pdf, simple input the file prefix used in the config.json file from running SCINKD, the number of chromosomes, and specify a plot label via:
```
#Usage: 
Rscript hapmer_plot.R <prefix> <N> <label> <show_scaffold_ids> <color_scaffolds>

# Examples:
# Basic plot
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes

# Plot with scaffold labels
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes T
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes T F

# Plot with colored scaffold points, but without scaffold labels
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes F T

# Plot with colored scaffold points and scaffold labels
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes T T

# Plot with colored scaffold points and scaffold labels and use whitelist file 
Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic scaffold.whitelist Chromosomes T T
```
Special thanks to Sergei Kliver for helping to overhaul the plotting functionality. Additional template code used in generating these plots is enclosed (plotting_template_code.R) and test files useful for replicating these plots are available alongside the test dataset (https://doi.org/10.6084/m9.figshare.27040678.v2).


This plotting establishes the relationship between chromosome length and number of haplotype-specific kmers, as well as the sex chromosomes that significantly deviate from this expectation:
<img width="2400" height="1800" alt="Anniella_stebbinsi_HiFi_2024 asm hic dotplot" src="https://github.com/user-attachments/assets/cb202654-7cf2-433e-995a-8b1f691916e2" />

Kmer densities on the Z and W are observably higher:
![Rplot06](https://github.com/user-attachments/assets/13b16d8c-748a-4a2b-86dc-ffb29a0bdd00)

Regions of increased kmer dentities converge on a single part of the chromosome, syntenic with chicken chromosome 11.
![Rplot07](https://github.com/user-attachments/assets/1b84e928-7d3d-4186-9f7e-8ff8995496fe)

[additional documentation to be added] 

After implicating a linkage group as a putative sex chromosome, additional anaylses still need to be conducted to validate. I'd recommend starting with a 1:1 haplotype alignment and diving deeper into that using a program like _pafr_ https://github.com/dwinter/pafr or _SVbyEye_ (shown) https://github.com/daewoooo/SVbyEye:
![image](https://github.com/user-attachments/assets/21df933e-c7d8-4a8d-b284-4b85224eec34)

Combining each piece of the SCINKD framework coalesces around a single region in the genome that shows strong evidence of a ZW pattern:
![Anniella_complete](https://github.com/user-attachments/assets/5e56461c-571c-4eb2-ad38-0da43ab2ec1f)


