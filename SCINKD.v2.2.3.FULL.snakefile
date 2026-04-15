import os

#To run this pipeline on any machine running linux, run
#git clone https://github.com/DrPintoThe2nd/SCINKD.git
#mamba create -f SCINKD.v2.2_environment.yml
#mamba activate scinkd2
#snakemake --use-conda --rerun-incomplete --nolock --cores 24 -s SCINKD/SCINKD.v2.2.2.FULL.snakefile

configfile: "SCINKD/config.json"
genome = config["prefix"]
threads = config["per_job_threads"]
memory = config["per_job_memory"]
ChrNum = config["ChrNum"]

rule all:
	input:
#index 
		expand("{genome}.hap1.fasta.gz.fai", genome=genome),
		expand("{genome}.hap2.fasta.gz.fai", genome=genome),
#meryl_count rule(s)
		expand("{genome}.hap1.meryl/", genome=genome),
		expand("{genome}.hap2.meryl/", genome=genome),
#meryl_diff rule(s)
		expand("{genome}.hap1-minus-hap2.meryl/", genome=genome),
		expand("{genome}.hap2-minus-hap1.meryl/", genome=genome),
#meryl-lookup rule(s)
		expand("{genome}.hap1-minus-hap2.bed", genome=genome),
		expand("{genome}.hap2-minus-hap1.bed", genome=genome),
#results rule(s)
		expand("{genome}.hap1-minus-hap2.results", genome=genome),
		expand("{genome}.hap2-minus-hap1.results", genome=genome),
#plot
		expand("{genome}.dotplot.png", genome=genome),
		expand("{genome}.dotplot.pdf", genome=genome),

rule index_hap1:
	input:
		"{genome}.hap1.fasta.gz",
	output:
		out = "{genome}.hap1.fasta.gz.fai",
		tmp = temp({genome}.hap1.fasta.gz.gzi),
	shell:
		"""
		samtools faidx {input}
		"""

rule index_hap2:
	input:
		"{genome}.hap2.fasta.gz",
	output:
		out = "{genome}.hap2.fasta.gz.fai",
		tmp = temp({genome}.hap2.fasta.gz.gzi),
	shell:
		"""
		samtools faidx {input}
		"""

rule meryl_hap1_count:	
	input:
		"{genome}.hap1.fasta.gz",
	output:
		directory("{genome}.hap1.meryl/"),
	threads: threads,
	resources:
		mem_gb = memory,
	shell:
		"""
		meryl count k=28 memory={resources.mem_gb} threads={threads} output {output} {input}
		"""

rule meryl_hap2_count:	
	input:
		"{genome}.hap2.fasta.gz",
	output:
		directory("{genome}.hap2.meryl/"),
	threads: threads,
	resources:
		mem_gb = memory,
	shell:
		"""
		meryl count k=28 memory={resources.mem_gb} threads={threads} output {output} {input}
		"""

rule meryl_hap1_diff:	
	input:
		hap1 = "{genome}.hap1.meryl",
		hap2 = "{genome}.hap2.meryl",
	output:
		directory("{genome}.hap1-minus-hap2.meryl/"),
	shell:
		"""
		meryl difference {input.hap1} {input.hap2} output {output}
		"""

rule meryl_hap2_diff:	
	input:
		hap1 = "{genome}.hap1.meryl/",
		hap2 = "{genome}.hap2.meryl/",
	output:
		directory("{genome}.hap2-minus-hap1.meryl/"),
	shell:
		"""
		meryl difference {input.hap2} {input.hap1} output {output}
		"""

rule meryl_lookup_hap1:	
	input:
		fa = "{genome}.hap1.fasta.gz",
		hap1 = "{genome}.hap1-minus-hap2.meryl/",
	output:
		"{genome}.hap1-minus-hap2.bed",
	shell:
		"""
		meryl-lookup -sequence {input.fa} -mers {input.hap1} -bed -output {output}
		"""

rule meryl_lookup_hap2:	
	input:
		fa = "{genome}.hap2.fasta.gz",
		hap2 = "{genome}.hap2-minus-hap1.meryl/",
	output:
		"{genome}.hap2-minus-hap1.bed",
	shell:
		"""
		meryl-lookup -sequence {input.fa} -mers {input.hap2} -bed -output {output}
		"""

##calculate number of kmers occuring in each haplotype
rule results_hap1:	
	input:
		"{genome}.hap1-minus-hap2.bed",
	output:
		final = "{genome}.hap1-minus-hap2.results",
		tmp   = temp("{genome}.hap1-minus-hap2.txt"),
	shell:
		"""
		
		cut -f1 {input} | uniq -c > {output.tmp}
		
		wait
		
		awk '{{print $2,$1}}' OFS='\t' {output.tmp} > {output.final}
		
		"""


rule results_hap2:	
	input:
		expand("{genome}.hap2-minus-hap1.bed", genome=genome),
	output:
		final = "{genome}.hap2-minus-hap1.results",
		tmp   = temp("{genome}.hap2-minus-hap1.txt"),
	shell:
		"""
		
		cut -f1 {input} | uniq -c > {output.tmp}
		
		wait
		
		awk '{{print $2,$1}}' OFS='\t' {output.tmp} > {output.final}
		
		"""

rule plot_scinkd:
	input:
		hap1 = "{genome}.hap1-minus-hap2.results",
		hap2 = "{genome}.hap2-minus-hap1.results",
		faidx1 = "{genome}.hap1.fasta.gz.fai",
		faidx2 = "{genome}.hap2.fasta.gz.fai",
	output:
		png = "{genome}.dotplot.png",
		pdf = "{genome}.dotplot.pdf",
	params:
		ChrNum = ChrNum,
		genome = genome,
	shell:
		"""
		Rscript SCINKD/hapmer_plot.R {params.genome} {params.ChrNum} Chromosomes T F
		"""
