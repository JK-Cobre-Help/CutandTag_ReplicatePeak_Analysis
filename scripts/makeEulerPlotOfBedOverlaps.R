###############################################
# Script name: makeEulerPlotOfBedOverlaps.R
# Author: Kevin Boyd
# Date: Dec 31, 2024
# Purpose: Generate an Euler plot of overlapping BED files.
#          Each BED file is treated as a "set".
#          Output is a PDF + RDS with an euler plot.
###############################################

# Load required packages
library(data.table)   # for fread
library(GenomicRanges)
library(eulerr)
library(ggplotify)
library(magrittr)
library(stringr)

# set input variables
args <- commandArgs(trailingOnly = TRUE)
bed_files  <- unlist(strsplit(args[1], ","))  
set_names  <- unlist(strsplit(args[2], ","))  
output_rds <- args[3]
output_pdf <- args[4]
font_size  <- as.numeric(args[5])
colors     <- strsplit(args[6], ",")[[1]]   # split the comma-separated hex codes
pdf_width  <- as.numeric(args[7])
pdf_height <- as.numeric(args[8])

# A simple function to read a BED file into a GRanges,
# making sure coordinates are integers.
read_bed_gr <- function(bed_file) {
  # Read as tab-delimited (no header) with data.table::fread
  dt <- fread(bed_file, header = FALSE)
  # Convert columns 2 and 3 to integer (round or floor, your choice)
  dt[[2]] <- as.integer(round(as.numeric(dt[[2]])))
  dt[[3]] <- as.integer(round(as.numeric(dt[[3]])))
  
  # Create a GRanges; 
  # Adjust to match your BED’s columns if needed.
  gr <- GRanges(
    seqnames = dt[[1]],
    ranges   = IRanges(start = dt[[2]], end = dt[[3]]),
    strand   = if (ncol(dt) >= 6) dt[[6]] else "*"
  )
  
  # If there are additional columns, store them in mcols()
  if (ncol(dt) > 3) {
    mcols(gr) <- dt[, -(1:3)]
  }
  
  gr
}

# Read all BEDs into a list of GRanges
gr_list <- lapply(bed_files, read_bed_gr)
names(gr_list) <- set_names

# Combine them into one big GRanges, then reduce:
all_combined <- do.call("c", unname(gr_list))
all_union    <- reduce(all_combined)

# Build presence/absence table
mcols(all_union) <- do.call(
  cbind,
  lapply(seq_along(gr_list), function(i) {
    overlaps <- findOverlaps(all_union, gr_list[[i]])
    in_set <- rep(0, length(all_union))
    in_set[queryHits(overlaps)] <- 1
    in_set
  })
)
colnames(mcols(all_union)) <- set_names

# Make the Euler plot
presence_absence_mat <- as.matrix(mcols(all_union))
eulerr_options(
  labels = list(fontsize = font_size),
  quantities = list(
    fontsize = font_size - 2,
    padding = grid::unit(100, "mm")
  ),
  legend = list(fontsize = font_size, vgap = 0.01)
)

EulerPlot <- presence_absence_mat %>%
  euler(shape = "ellipse") %>%
  plot(quantities = TRUE, legend = TRUE, adjust_labels = TRUE, fills = colors) %>%
  as.ggplot()

# Save plot to RDS
saveRDS(EulerPlot, file = output_rds)

# Save plot to PDF
pdf(output_pdf, width = pdf_width, height = pdf_height)
print(EulerPlot)
dev.off()
