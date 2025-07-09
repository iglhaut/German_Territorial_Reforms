# Main Script to Clean German Territorial Reforms Data
# Author: Felix Iglhaut
# Date: July 09, 2025


# Load packages -------------------------------------------------------
library(tidyverse)  # version used: 2.0.0
library(readxl)     # version used: 1.4.3
library(haven)      # version used: 2.5.4
library(lubridate)  # version used: 1.9.3


# Setup  -------------------------------------------------------
source("function_data_cleaning.R")
input_folder <- "../data/raw"

# Generate a list of .xlsx files and years present in the input folder
files <- list.files(input_folder, pattern = "\\.xlsx$", full.names = TRUE)
years <- str_extract(files, "\\d{4}")

# Initialize an empty dataset to store the cleaned data
final_dataset <- NULL  





# Data cleaning  ------------------------------------------------------- 
# Loop through each file and clean the data
for (i in seq_along(files)) {
  
  file <- files[i]
  
  # Adapt sheet name accordingly
  if (years[i] == 1975) {
    sheet_name <- "1975_0101-3112"
  } else if (years[i] == 1990) {
    sheet_name <- "Gebietsänderungen_1990"
  } else if (years[i] == 1991) {
    sheet_name <- "1991_Komplett"
  } else if ( (years[i] >= 1992 && years[i] <= 1999) | (years[i] == 2006 | years[i] == 2008) ) {
    sheet_name <- paste0("Gebietsänderungen_", years[i])
  } else if ( years[i] == 2009 ) {
    sheet_name <- 2
  } else if ( (years[i] >= 2000 && years[i] <= 2005) | years[i] == 2007)  {
    sheet_name <- paste0("Gebietsaenderungen_", years[i]) 
  } else if (years[i] >= 2010 && years[i] <= 2022) {
    sheet_name <- paste0("Gebietsaenderungen ", years[i]) 
  } else if (years[i] >= 2023) {
    sheet_name <- "Gebietsaenderungen" 
  }
  else {
    sheet_name <- years[i]
  }
  # Clean the data using the defined function
  cleaned_data <- data_cleaning(file, sheet_name)
  
  # Add the year to the cleaned data
  cleaned_data <- cleaned_data %>% 
    mutate(year = as.numeric(years[i])) %>% 
    relocate(year)
  
  # Combine with existing data
  if (is.null(final_dataset)) {                              
    final_dataset <- cleaned_data
  } else {
    final_dataset <- bind_rows(final_dataset, cleaned_data)
  }
}





# Data Processing ------------------------------------------------------- 
# Filter very special cases
final_dataset_filtered <- final_dataset %>%
  # Drop an addition of coastal waters with unknown area in 2012
  filter(!(year == 2012 & id == "13/2010/0006-R 2)")) %>%
  # Drop 2009 cases with all pre-variables missing
  filter(!(year == 2009 & 
             is.na(pre_region_id) & 
             is.na(pre_ags) & 
             is.na(pre_name) & 
             is.na(reform_type) &
             is.na(regional_unit))) %>%
  # Drop 2009 Gemeindeverband cases with all pre-variables missing  
  filter(!(year == 2009 & 
             regional_unit == "Gemeindeverband" &
             is.na(pre_region_id) & 
             is.na(pre_ags) & 
             is.na(pre_name) & 
             is.na(reform_type))) %>% 
  # Drop 1997 Gemeindeverband case
  filter(!(year == 1997 & 
             regional_unit == "Gemeindeverband" &
             is.na(pre_ags) & 
             is.na(pre_name) & 
             is.na(reform_type))) %>%
  # Drop 1999 Gemeindeverband case
  filter(!(year == 1999 & 
             regional_unit == "Gemeindeverband" &
             is.na(pre_ags) & 
             is.na(pre_name) & 
             is.na(reform_type)))


# Add variable and value labels
final_dataset_labeled <- final_dataset_filtered %>%
  mutate(
    # Formatting
    population = as.numeric(population),
    area_ha = as.numeric(area_ha),
    # Labeling
    year = labelled(year, label = "Year"),
    id = labelled(id, label = "Reform id"),
    regional_unit = labelled(regional_unit, label = "Regional unit: Gemeinde (municipality) or Kreis (county)"),
    pre_region_id = labelled(pre_region_id, label = "Pre-reform region ID"),
    pre_ags = labelled(pre_ags, label = "Pre-reform official municipality key (AGS)"),
    pre_county_id = labelled(pre_county_id, label = "Pre-reform county ID"),
    pre_name = labelled(pre_name, label = "Pre-reform unit name"),
    reform_type = labelled(reform_type, label = "1=dissolution, 2=partial separation, 3=key change, 4=name change, 5=new addition"),
    area_ha = labelled(area_ha, label = "Area in hectares"),
    population = labelled(population, label = "Population count"),
    post_region_id = labelled(post_region_id, label = "Post-reform region ID"),
    post_ags = labelled(post_ags, label = "Post-reform official municipality key (AGS)"),
    post_county_id = labelled(post_county_id, label = "Post-reform county ID"),
    post_name = labelled(post_name, label = "Post-reform unit name"),
    date_legal = labelled(date_legal, label = "Date of legal change"),
    month_legal = labelled(month_legal, label = "Month of legal change"),
    day_legal = labelled(day_legal, label = "Day of legal change"),
    date_statistical = labelled(date_statistical, label = "Date of statistical change"),
    month_statistical = labelled(month_statistical, label = "Month of statistical change"),
    day_statistical = labelled(day_statistical, label = "Day of statistical change")
  )


# Reforms which altered the counties of regional units 
county_switchers <- final_dataset_filtered %>%
  filter(!is.na(pre_county_id) & !is.na(post_county_id) & pre_county_id != post_county_id & !is.na(population) & population > 0) %>%
  select(year, id, regional_unit, pre_county_id, post_county_id, reform_type, population, pre_name, post_name) %>% 
  identity()

# Reforms which altered the states of regional units 
state_switchers <- county_switchers %>% 
  mutate(
    pre_state = labelled(
      str_sub(pre_county_id, 1, 2),
      label = "Pre-reform state (Bundesland)"
    ),
    post_state = labelled(
      str_sub(post_county_id, 1, 2), 
      label = "Post-reform state (Bundesland)"
    )
  ) %>%
  filter(pre_state != post_state) %>% 
  identity()





# Store cleaned data   ------------------------------------------------------- 
write_csv(final_dataset_filtered, "../data/processed/csv/county_reforms.csv")
write_dta(final_dataset_labeled, "../data/processed/dta/county_reforms.dta")

write_csv(county_switchers, "../data/processed/csv/county_switchers.csv")
write_dta(county_switchers, "../data/processed/dta/county_switchers.dta")

write_csv(state_switchers, "../data/processed/csv/state_switchers.csv")
write_dta(state_switchers, "../data/processed/dta/state_switchers.dta")


# Clean up
rm(cleaned_data, final_dataset, final_dataset_filtered,file,files, i, input_folder, sheet_name, years)