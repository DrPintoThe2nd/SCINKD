#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

### -----------------------------
### 1. Read command-line arguments
### -----------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  stop("Usage: Rscript hapmer_plot.R <prefix> <N> <label>\n",
       "Example: Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes\n")
}

prefix <- args[1]
N <- as.integer(args[2])
label <- args[3]

if (is.na(N) || N <= 0) {
  stop("Second argument <N> must be a positive integer.")
}

cat("Running analysis on prefix:", prefix, "\n")
cat("Using first", N, "records.\n")
cat("Label for plots:", label, "\n")

### -----------------------------
### 2. Build filenames
### -----------------------------
file_hap1_kmer <- paste0(prefix, ".hap1-minus-hap2.results")
file_hap2_kmer <- paste0(prefix, ".hap2-minus-hap1.results")
file_hap1_idx  <- paste0(prefix, ".hap1.fasta.gz.fai")
file_hap2_idx  <- paste0(prefix, ".hap2.fasta.gz.fai")

### -----------------------------
### 3. Read files
### -----------------------------
hap1_kmer <- read.delim(file_hap1_kmer, header = FALSE)
hap2_kmer <- read.delim(file_hap2_kmer, header = FALSE)

hap1_idx  <- read.delim(file_hap1_idx, header = FALSE)
hap2_idx  <- read.delim(file_hap2_idx, header = FALSE)

hap1_tmp <- subset(hap1_idx, V1 %in% hap1_kmer$V1)
hap2_tmp <- subset(hap2_idx, V1 %in% hap2_kmer$V1)

hap1_merge <- merge(hap1_tmp, hap1_kmer, by = "V1", sort = FALSE)
hap2_merge <- merge(hap2_tmp, hap2_kmer, by = "V1", sort = FALSE)

hap1_merge$density <- with(hap1_merge, V2.y / V2.x)
hap2_merge$density <- with(hap2_merge, V2.y / V2.x)

### -----------------------------
### 4. Subsample first N entries
### -----------------------------
hap1_final <- hap1_merge[1:N, c(1,2,6,7)]
hap2_final <- hap2_merge[1:N, c(1,2,6,7)]

### -----------------------------
### 5. Combine & label
### -----------------------------
hap1_final$Dataset <- "hap1"
hap2_final$Dataset <- "hap2"

combined_data <- rbind(hap1_final, hap2_final)

### -----------------------------
### 6. Output filenames
### -----------------------------
boxplot_pdf <- paste0(prefix, ".boxplot.pdf")
boxplot_png <- paste0(prefix, ".boxplot.png")
dotplot_pdf <- paste0(prefix, ".dotplot.pdf")
dotplot_png <- paste0(prefix, ".dotplot.png")

### -----------------------------
### 7. Boxplot (PDF & PNG)
### -----------------------------
pdf(boxplot_pdf, width = 7, height = 5)
boxplot(hap1_final$density, hap2_final$density,
        pch = 19,
        names = c("hap1", "hap2"),
        main = paste("Density Comparison (", label, ")", sep = ""),
        ylab = "Density")
dev.off()

png(boxplot_png, width = 1600, height = 1200, res = 200)
boxplot(hap1_final$density, hap2_final$density,
        pch = 19,
        names = c("hap1", "hap2"),
        main = paste("Density Comparison (", label, ")", sep = ""),
        ylab = "Density")
dev.off()

### -----------------------------
### 8. Dotplot (PDF & PNG)
### -----------------------------
dotplot <- ggplot(combined_data, aes(x = V2.x, y = V2.y, color = Dataset)) +
  geom_point() +
  geom_smooth(method = "lm", level = 0.95) +
  labs(title = paste("Sequence Length vs # Hap-mers — ", label, sep = ""),
       x = "Sequence Length",
       y = "# Hap-mers") +
  theme_minimal()

pdf(dotplot_pdf, width = 7, height = 5)
print(dotplot)
dev.off()

png(dotplot_png, width = 1600, height = 1200, res = 200)
print(dotplot)
dev.off()

### -----------------------------
### 9. Final message
### -----------------------------
cat("Saved output files:\n")
cat("  ", boxplot_pdf, "\n")
cat("  ", boxplot_png, "\n")
cat("  ", dotplot_pdf, "\n")
cat("  ", dotplot_png, "\n")
