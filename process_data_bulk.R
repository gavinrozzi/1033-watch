#!/usr/bin/env Rscript
# Bulk version of script for converting 1033 Program Excel spreadsheet w/ sheets for each state into a single CSV file usable in analysis.
# Loops over every 1033 Program spreadsheet in the data directory and writes out a CSV version.
#
# USAGE: Rscript process_data_bulk.R 
library(plyr)
library(readxl)

setwd('data/')

# Get all excel files in data directory
excel_files <- list.files(pattern = "\\.xlsx$")

# Process each Excel file into a CSV version
for (file in excel_files) {
    cat(paste('Processing file',file,'\n'))
    # Convert the 1033 Program excel sheet to a CSV file for analysis.
    sheets <- excel_sheets(file)
    # Read in all sheets to a list
    list <- lapply(sheets, function(x) read_excel(file, sheet = x))
    # Convert to a single dataframe
    df <- rbind.fill(list)
    # Get filename from Excel sheet, remove XLSX extension
    filename <- paste0(sub('\\..*$', '', basename(file)),'.csv')
    # Write out processed CSV for later analysis
    write.csv(df, filename)
}