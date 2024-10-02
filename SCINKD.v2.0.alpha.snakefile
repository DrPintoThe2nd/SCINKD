import os

#To run this pipeline on any machine running linux, run
#git clone https://github.com/DrPintoThe2nd/SCINKD.git
#mamba create -n scinkd meryl=1.4.1 snakemake pigz r r-dplyr r-ggplot2 mashmap --yes
#mamba activate scinkd 
#mamba env export > SCINKD.v2.0.alpha_environment.yml
#snakemake --use-conda -np -s SCINKD.v2.0.alpha.snakefile

configfile: "config.json"

genome = config["species"]
#hap1 = config["hap1"]
#hap2 = config["hap2"]
#hap = config["hap"]

rule all:
	input:
#meryl_count rule(s)
		directory(expand("{genome}.hap1.meryl/", genome=genome)),
		directory(expand("{genome}.hap2.meryl/", genome=genome)),
#meryl_diff rule(s)
		directory("hap1-minus-hap2.meryl/"),
		directory("hap2-minus-hap1.meryl/"),
#meryl-lookup rule(s)
		"hap1-minus-hap2.bed",
#		"hap2-minus-hap1.bed",
#results rule(s)
#		expand("{genome}_hap1-minus-hap2.results", genome=genome),
#		expand("{genome}_hap2-minus-hap1.results", genome=genome),


rule meryl_hap1_count:	
	input:
		"{genome}.hap1.fasta.gz",
	output:
		directory("{genome}.hap1.meryl/"),
	shell:
		"""
		meryl count k=28 memory=15 threads=8 output {output} {input}
		"""

rule meryl_hap2_count:	
	input:
		"{genome}.hap2.fasta.gz",
	output:
		directory("{genome}.hap2.meryl/"),
	shell:
		"""
		meryl count k=28 memory=15 threads=8 output {output} {input}
		"""

rule meryl_hap1_diff:	
	input:
		hap1 = directory(expand("{genome}.hap1.meryl/", genome=genome)),
		hap2 = directory(expand("{genome}.hap2.meryl/", genome=genome)),
	output:
		directory("hap1-minus-hap2.meryl"),
	shell:
		"""
		meryl difference {input.hap1} {input.hap2} output {output}
		"""

rule meryl_hap2_diff:	
	input:
		hap1 = directory(expand("{genome}.hap1.meryl/", genome=genome)),
		hap2 = directory(expand("{genome}.hap2.meryl/", genome=genome)),
	output:
		directory("hap2-minus-hap1.meryl"),
	shell:
		"""
		meryl difference {input.hap2} {input.hap1} output {output}
		"""

rule meryl_lookup_hap1:	
	input:
		fa = expand("{genome}.hap1.fasta.gz", genome=genome),
		hap1 = directory(expand("{genome}.hap1.meryl/", genome=genome)),
	output:
		"hap1-minus-hap2.bed",
	shell:
		"""
		meryl-lookup -sequence {input.fa} -mers {input.hap1} -bed -output hap1-minus-hap2.bed
		"""

#rule meryl_lookup_hap2:	
#	input:
#		fa = expand("{genome}.hap2.fasta.gz", genome=genome),
#		hap2 = directory(expand("{genome}.hap2.meryl/", genome=genome)),
#	output:
#		"hap2-minus-hap1.bed",
#	shell:
#		"""
#		meryl-lookup -sequence {input.fa} -mers {input.hap2} -bed -output hap2-minus-hap1.bed
#		"""
#
###calculate number of kmers occuring in each haplotype (this is rather crude at this point)
#rule results_hap1:	
#	input:
#		"hap1-minus-hap2.bed",
#	output:
#		final = expand("{genome}_hap1-minus-hap2.results", genome=genome),
#		tmp1 = "hap1-minus-hap2.txt",
#		tmp2 = "hap1-minus-hap2.out"
#	shell:
#		"""
#		cut -f1 {input} | uniq > {output.tmp1}
#		
#		wait
#		
#		cat {output.tmp1} | while read line
#		do
#		grep "$line" {input} | wc -l >> {output.tmp2}
#		done
#		
#		wait
#		
#		paste {output.tmp1} {output.tmp2} > {output.final}
#
#		"""
#
#rule results_hap2:	
#	input:
#		"hap2-minus-hap1.bed",
#	output:
#		final = expand("{genome}_hap2-minus-hap1.results", genome=genome),
#		tmp1 = "hap2-minus-hap1.txt",
#		tmp2 = "hap2-minus-hap1.out"
#	shell:
#		"""
#		cut -f1 {input} | uniq > {output.tmp1}
#		
#		wait
#		
#		cat {output.tmp1} | while read line
#		do
#		grep "$line" {input} | wc -l >> {output.tmp2}
#		done
#		
#		wait
#		
#		paste {output.tmp1} {output.tmp2} > {output.final}
#
#		"""
#