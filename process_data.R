#!/usr/bin/env Rscript
# Script for converting 1033 Program Excel spreadsheet w/ sheets for each state into a single CSV file usable in analysis.
# USAGE: Rscript process_data.R FILENAME, where FILENAME is the path to an Excel spreadsheet of 1033 Program data for a quarter

library(plyr)
library(readxl)

# Get arguments, print filename being processed
args <- commandArgs(trailingOnly = TRUE)

cat(paste('Processing file',args[1]))

# Convert the 1033 Program excel sheet to a CSV file for analysis.
sheets <- excel_sheets(args[1])

# Read in all sheets to a list
list <- lapply(sheets, function(x) read_excel(args[1], sheet = x))

# Convert to a single dataframe
df <- rbind.fill(list)

# Get filename from Excel sheet, remove XLSX extension

filename <- paste0('data/',sub('\\..*$', '', basename(args[1])),'.csv')

# Write out processed CSV for later analysis
write.csv(df, filename)