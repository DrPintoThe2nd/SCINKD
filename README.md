# Sex Chromosome Identification by Negating Kmer Densities (SCINKD)
Sex Chromosome Identification by Negating Kmer Densities (SCINKD) is a wrapper to implicate the sex chromosome linkage group of a haplotype-resolved genome of the heterogametic sex with an unknown sex chromosome system.

The current implementation of this tool uses jellyfish and bbmap to count and negate kmers from two genomic haplotypes. Currently, this is computationally prohibitive (specifically the bbmap portion) requiring excessive amounts of RAM, approximately 100Gb or RAM per Gb of haploid genome size.
