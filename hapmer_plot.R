#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggrepel)
  library(Polychrome)
})

### -----------------------------
### 1. Read command-line arguments
### -----------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 5) {
  stop("Usage: Rscript hapmer_plot.R <prefix> <N> <label> <show_scaffold_ids> <color_scaffolds>\n",
       "Example: Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes\n",
       "Example: Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes T\n",
       "Example: Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes T F\n",
       "Example: Rscript hapmer_plot.R Anniella_stebbinsi_HiFi_2024.asm.hic 10 Chromosomes F T\n")
}

prefix <- args[1]
N <- args[2]
label <- args[3]
show_scaffold_ids <- if (length(args) >= 4) as.logical(args[4]) else FALSE
color_scaffolds <- if (length(args) >= 5) as.logical(args[5]) else FALSE

whitelist <- NA

cat("Running analysis on prefix:", prefix, "\n")
cat("Label for plots:", label, "\n")

if (file.exists(N)) {
   cat("Treating second argument <N> as a path to the scaffold whitelist (one id per line) :", N, "\n")
   whitelist <- readLines(N)
} else {
  N <- as.integer(N)
  if (is.na(N) || N <= 0) {
    stop("Second argument <N> must be a positive integer or a path to the scaffold whitelist.")
  }
  cat("Treating second argument <N> as a number of first scaffolds to show:", N, "\n")
  cat("Using first", N, "records.\n")
}

if (is.na(show_scaffold_ids) || is.na(color_scaffolds)) {
  stop("Forth and fifth arguments must be booleans recognizable by R, i.e. T or TRUE, F or FALSE.")
}

if (show_scaffold_ids) {
    cat("Show scaffold ids on the dotplot\n")
}

if (color_scaffolds) {
    cat("Color scaffolds on the dotplot\n")
}

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

if (all(is.na(whitelist))) {
  hap1_final <- hap1_merge[1:N, c(1,2,6,7)]
  hap2_final <- hap2_merge[1:N, c(1,2,6,7)]
  } else {
    hap1_final <- hap1_merge[hap1_merge$V1 %in% whitelist, c(1,2,6,7)]
    hap2_final <- hap2_merge[hap2_merge$V1 %in% whitelist, c(1,2,6,7)]
    }

### -----------------------------
### 5. Combine & label & color scaffolds
### -----------------------------
hap1_final$Haplotype <- "hap1"
hap2_final$Haplotype <- "hap2"

# color scaffolds using Polychrome package to get distinct color for given number of scaffolds
color_number <- if (all(is.na(whitelist))) N else length(whitelist)
hap1_final$Scaffold_color <- createPalette(color_number, c("#FF0000", "#00FF00"))
hap2_final$Scaffold_color <- hap1_final$Scaffold_color[match(hap2_final$V1, hap1_final$V1)]

combined_data <- rbind(hap1_final, hap2_final)
write.table(combined_data, paste0(prefix, ".plot_data.tsv"), sep="\t", row.names = FALSE, quote=FALSE)
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

png(boxplot_png, width = 1200, height = 1800, res = 300)
boxplot(hap1_final$density, hap2_final$density,
        pch = 19,
        names = c("hap1", "hap2"),
        main = paste("Density Comparison (", label, ")", sep = ""),
        ylab = "Density")
dev.off()

### -----------------------------
### 8. Dotplot (PDF & PNG)
### -----------------------------
line_palette <- c("hap1"="#F8766D", hap2="#00BFC4")
scaffold_palette <- setNames(combined_data$Scaffold_color, combined_data$V1)
scaffold_palette <- scaffold_palette[!duplicated(names(scaffold_palette))]

if (color_scaffolds) {
  dotplot <- ggplot(combined_data, aes(x = V2.x, y = V2.y)) +
    geom_point(aes(color=V1, shape = Haplotype)) +
    geom_smooth(method = "lm", level = 0.95, aes(color=Haplotype)) +
    labs(title = paste("Sequence Length vs # Hap-mers — ", label, sep = ""),
         x = "Sequence Length",
         y = "# Hap-mers") +
    theme_minimal() +
    scale_color_manual(values = c(scaffold_palette, line_palette), name="Scaffold") +
    guides(color = guide_legend(override.aes = list(shape = 16)))
  } else {
  dotplot <- ggplot(combined_data, aes(x = V2.x, y = V2.y, color = Haplotype)) +
  geom_point() +
  geom_smooth(method = "lm", level = 0.95) +
  labs(title = paste("Sequence Length vs # Hap-mers — ", label, sep = ""),
       x = "Sequence Length",
       y = "# Hap-mers") +
  theme_minimal()
  }

if (show_scaffold_ids) {
  dotplot <- dotplot + geom_text_repel(aes(label = V1))
}

pdf(dotplot_pdf, width = 7, height = 5)
print(dotplot)
dev.off()

png(dotplot_png, width = 2400, height = 1800, res = 300)
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
