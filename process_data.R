library(plyr)
library(readxl)

# Convert the 1033 Program excel sheet to a CSV file for analysis.

# List all sheets
sheets <- excel_sheets('data/DISP_AllStatesAndTerritories_06302020.xlsx')

# Read in all sheets to a list
list <- lapply(sheets, function(x) read_excel('data/DISP_AllStatesAndTerritories_03312020.xlsx', sheet = x))

# Convert to a single dataframe
df <- rbind.fill(list)

write.csv(df, 'data/data.csv')