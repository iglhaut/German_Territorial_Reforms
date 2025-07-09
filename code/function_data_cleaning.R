# Data Cleaning Function for German Territorial Reforms
# Author: Felix Iglhaut
# Date: July 09, 2025

data_cleaning <- function(file, sheet_name) {
  raw_data <- read_excel(file, sheet = sheet_name)
  
  # Identify data boundaries
  first_row_with_data <- raw_data %>% 
    pull(1) %>% 
    as.character() %>% 
    str_detect("\\d") %>% 
    which %>% 
    first()
  
  last_row_with_data <- raw_data %>%
    pull(1) %>%
    tail(-first_row_with_data + 1) %>%
    is.na() %>%
    which() %>%
    first()
  
  # Clean and transform data
  data <- raw_data %>% 
    # Select relevant rows and columns
    slice(first_row_with_data:(first_row_with_data + last_row_with_data - 2)) %>% 
    select(1:13) %>%
    
    # Rename columns
    rename(
      id = 1,
      regional_unit = 2,
      pre_region_id = 3,
      pre_ags = 4,
      pre_name = 5,
      reform_type_raw = 6,
      area_ha = 7,
      population = 8,
      post_region_id = 9,
      post_ags = 10,
      post_name = 11,
      date_legal = 12,
      date_statistical = 13
    ) %>% 
    
    # Format date variables
    mutate(
      date_legal = as.Date(as.numeric(date_legal), origin = "1899-12-30"),
      month_legal = month(date_legal, label = TRUE, abbr = FALSE),
      day_legal = day(date_legal),      
      date_statistical = as.Date(as.numeric(date_statistical), origin = "1899-12-30"),
      month_statistical = month(date_statistical, label = TRUE, abbr = FALSE),
      day_statistical = day(date_statistical)
    ) %>%
    
    # Create county (Kreis) variables with fallback logic
    mutate(
      pre_county_id = case_when(
        regional_unit == "Gemeinde" ~ str_sub(pre_ags, 1, 5),
        regional_unit == "Kreis" ~ pre_region_id,
        TRUE ~ NA_character_                                     
      ),
      post_county_id = case_when(
        regional_unit == "Gemeinde" ~ str_sub(post_ags, 1, 5),   
        regional_unit == "Kreis" ~ post_region_id,
        TRUE ~ NA_character_
      ),
      # Fallback: try alternative sources if county_id is missing
      pre_county_id = case_when(
        !is.na(pre_county_id) ~ pre_county_id,
        !is.na(pre_region_id) ~ str_sub(pre_region_id, 1, 5),
        !is.na(pre_ags) ~ str_sub(pre_ags, 1, 5),
        TRUE ~ NA_character_
      ),
      post_county_id = case_when(
        !is.na(post_county_id) ~ post_county_id,
        !is.na(post_region_id) ~ str_sub(post_region_id, 1, 5),
        !is.na(post_ags) ~ str_sub(post_ags, 1, 5),
        TRUE ~ NA_character_
      )
    ) %>%
    relocate(pre_county_id, .after = pre_ags) %>%
    relocate(post_county_id, .after = post_ags) %>% 
    
    # Process reform types
    mutate(
      reform_type_char = as.character(reform_type_raw),
      reform_type_numeric = suppressWarnings(as.numeric(reform_type_char)),
      
      # Identify special formations (Neubildung, Neuaufnahme, etc.)
      is_special_formation = str_detect(
        paste(
          tolower(as.character(pre_region_id)),
          tolower(as.character(pre_ags)),
          tolower(as.character(pre_county_id)),
          tolower(as.character(pre_name)),
          tolower(as.character(reform_type_raw)),
          sep = " "
        ),
        pattern = "neubildung|neuaufnahme|neubi|rückführung aus den niederlanden"
      ),
      
      # Standardize reform type codes
      reform_type = case_when(
        is_special_formation ~ "5",
        is.na(reform_type_raw) ~ NA_character_,
        # Fix floating point precision issues (e.g., 2.2999999 → 2,3)
        !is.na(reform_type_numeric) & abs(reform_type_numeric - 2.3) < 0.01 ~ "2,3",
        # Handle whole numbers
        !is.na(reform_type_numeric) & reform_type_numeric == round(reform_type_numeric) ~ as.character(round(reform_type_numeric)),
        # Handle decimals
        !is.na(reform_type_numeric) ~ {
          int_part <- floor(reform_type_numeric)
          dec_part <- round((reform_type_numeric - int_part) * 10)
          ifelse(dec_part > 0, paste0(int_part, ",", dec_part), as.character(int_part))
        },
        # Extract multiple reform types (e.g., "2 and 3" → "2,3")
        str_detect(reform_type_char, "\\d.*\\d") ~ 
          str_extract_all(reform_type_char, "\\d") %>% 
          map_chr(~ paste(.x, collapse = ",")),
        TRUE ~ reform_type_char
      )
    ) %>% 
    
    # Clear pre-reform fields for new formations
    mutate(
      pre_region_id = ifelse(is_special_formation, NA_character_, pre_region_id),
      pre_ags = ifelse(is_special_formation, NA_character_, pre_ags),
      pre_county_id = ifelse(is_special_formation, NA_character_, pre_county_id),
      pre_name = ifelse(is_special_formation, NA_character_, pre_name)
    ) %>%
    
    # Remove temporary columns
    select(-is_special_formation, -reform_type_char, -reform_type_numeric, -reform_type_raw)
  
  return(data)
}