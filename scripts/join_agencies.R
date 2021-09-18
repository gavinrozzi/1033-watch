# Script used to create mapping between FBI law enforcement agency data and 1033 Program recipients

library(fuzzyjoin)
library(tidyverse)
library(stringr)
library(jsonlite)

# Get law enforcement agencies from FBI
agencies <- fromJSON('https://crime-data-explorer.fr.cloud.gov/proxy/api/agencies/list')

# Subset columns for relating FBI data to 1033 Program data
agencies_subset <- agencies %>% select(agency_name,state_abbr,ori)

# Get 1033 Program participating agencies from dataset
data1033 <- read_csv('data/data.csv') %>% select(-X1)
agencies_1033 <- data1033 %>% select(`Station Name (LEA)`,State) %>% distinct()

# Join the agency names using fuzzy string matching
#joined <- agencies_1033 %>%
#  stringdist_inner_join(agencies_subset, by = 'join_key', max_dist = 2, ignore_case = TRUE)

join_by_state <- function(state) {
  # Get all agencies for each state
  agencies_1033_state <- agencies_1033 %>% filter(State == state)
  agencies_subset_state <- agencies_subset %>% filter(state_abbr == state)

  # Join the subset
  joined <- agencies_1033_state %>%
    stringdist_inner_join(agencies_subset_state, by = c(`Station Name (LEA)` = 'agency_name'), max_dist = 1, ignore_case = TRUE)
  cat(paste(nrow(joined),'agencies matched of',nrow(agencies_1033_state),'total for state:',state,'\n'))
  result <- joined %>% select(`Station Name (LEA)`,agency_name,ori)
  return(result)
}


# Get unique state values represented in the 1033 program dataset
states <- unique(agencies_1033$State)

# Build dataset for all 50 states with initial matches
dataset <- do.call("rbind", apply(as.array(states), 1, join_by_state))

# Get rows that failed to match
unmatched <- agencies_1033 %>% anti_join(dataset, by = 'Station Name (LEA)')

# Clean up values that don't match
# Make copy of unmatched data for processing
unmatched_cleaned <- unmatched

# Change dept to department

#Create join key. join_key is equivalent to Station Name (LEA) for joining w/ 1033 data but changed to match FBI naming convention

unmatched_cleaned$join_key <- str_replace(unmatched$`Station Name (LEA)`,'DEPT','DEPARTMENT')

unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'DEPT','DEPARTMENT')
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'DEPT.','DEPARTMENT')
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'DEPTMENT','DEPARTMENT')


unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'CTY','COUNTY')

# Clean up Sheriff's Offices
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'SHERIFF OFFICE',"SHERIFF\\'\\S OFFICE")
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'SHERIFF DEPARTMENT',"SHERIFF\\'\\S DEPARTMENT")
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'CSO',"COUNTY SHERIFF\\'\\S OFFICE")


# Change TWP PD to TOWNSHIP POLICE DEPARTMENT
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'TWP',"TOWNSHIP")
unmatched_cleaned$join_key <- str_replace(unmatched_cleaned$join_key,'PD',"POLICE DEPARTMENT")

match_cleaned_cases <- function(state) {
  # Get all agencies for each state
  agencies_1033_state <- unmatched_cleaned %>% filter(State == state)
  agencies_subset_state <- agencies_subset %>% filter(state_abbr == state)

  # Join the subset
  joined <- agencies_1033_state %>% inner_join(agencies_subset_state, by = c('join_key' = 'agency_name'))
  cat(paste(nrow(joined),'agencies matched of',nrow(agencies_1033_state),'total for state:',state,'\n'))
  result <- joined %>% select(`Station Name (LEA)`,join_key,ori)
  return(result)
}


# Generate dataset of agencies able to be matched after cleaning
unmatched_cleaned_dataset <- do.call("rbind", apply(as.array(states), 1, match_cleaned_cases))

# Bind output of new matches with original matches
#dataset <- dataset %>% rename('join_key' = 'agency_name')
result_dataset <- rbind(dataset,unmatched_cleaned_dataset)

# Join the result dataset with the full agency info
result_dataset <- result_dataset %>% left_join(agencies, by = 'ori')


nomatch <- agencies_1033 %>% anti_join(result_dataset, by = 'Station Name (LEA)')
