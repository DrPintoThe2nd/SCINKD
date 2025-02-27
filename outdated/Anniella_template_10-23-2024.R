setwd("~/Downloads")

library(dplyr)
library(ggplot2)

hap1_kmer <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap1-minus-hap2.results", header = F)
hap2_kmer <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap2-minus-hap1.results", header = F)

hap1_idx <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap1.fasta.gz.fai", header = F)
hap2_idx <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap2.fasta.gz.fai", header = F)

hap1_bed <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap1-minus-hap2.chrW.bed", header = F)
hap2_bed <- read.delim("Anniella_stebbinsi_HiFi_2024.asm.hic.hap2-minus-hap1.chrZ.bed", header = F)
colnames(hap1_bed)<-c("scaffold","start","end")
colnames(hap2_bed)<-c("scaffold","start","end")

hap1_tmp <- subset(hap1_idx, V1 %in% hap1_kmer$V1)
hap2_tmp <- subset(hap2_idx, V1 %in% hap2_kmer$V1)

hap1_merge <- merge(hap1_tmp, hap1_kmer, by = "V1", sort = F)
hap2_merge <- merge(hap2_tmp, hap2_kmer, by = "V1", sort = F)

#plot(hap1_merge$V2.x, hap1_merge$V2.y, pch = 19)
#points(hap2_merge$V2.x, hap2_merge$V2.y, pch = 19, col = 'grey')

hap1_merge$density <- with(hap1_merge, V2.y/V2.x)
hap2_merge$density <- with(hap2_merge, V2.y/V2.x)

#subsample only chromosomes (if applicable, change the "10" to total number of chromosomes)
hap1_final <- hap1_merge[1:10,c(1,2,6,7)]
hap2_final <- hap2_merge[1:10,c(1,2,6,7)]

boxplot(hap1_final$density, hap2_final$density, pch = 19)

hap1_final$Dataset <- "hap1"  # Add a column to distinguish the dataset
hap2_final$Dataset <- "hap2"  # Add a column to distinguish the dataset

#colnames(hap1_final) <- c("hap1", "Sequence.Length", "Kmers", "h1_density")
#colnames(hap2_final) <- c("hap2", "Sequence.Length", "Kmers", "h2_density")

combined_data <- rbind(hap1_final, hap2_final)

#####
ggplot(combined_data, aes(x = V2.x, y = V2.y, color = Dataset)) +
  geom_point() +
  geom_smooth(method = "lm", level = 0.95) +  # Add confidence intervals at 95%
  labs(title = "Dot Plot of Sequence Length vs # Kmers",
       x = "Sequence Length",
       y = "# Kmers") +
  theme_minimal()
####


###################

#ggplot(hap1_bed) + geom_histogram(fill = "black", aes(x=start),binwidth=1e6)
#ggplot(hap2_bed) + geom_histogram(fill = "black", aes(x=start),binwidth=1e6)

#mirror plot
ggplot(hap1_bed, aes(x=start)) +
  geom_histogram(data = hap1_bed,  aes(x = start, y =  after_stat(density)), color = "#5F00F6", fill = "black", alpha = 0.8, binwidth=1e6) +
  geom_histogram(data = hap2_bed, aes(x = start, y = -after_stat(density)), color = "#62CD32", fill = "grey", alpha = 0.8, binwidth=1e6) +
  ggtitle("Kmer Density: putative ZW") +
  xlab("Position on chromosome") + 
  ylab("Kmer density") + 
  theme_bw()








