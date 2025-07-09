# German Territorial Reforms Data Cleaning
A data cleaning pipeline for processing German territorial reforms: "Gebietsänderungen (Namens-, Grenz- und Schlüsseländerungen)" from 1950 to 2024.


## Overview
This repository contains code to clean administrative territorial reform data from Germany, primarily tracking municipality (Gemeinde) and county (Kreis) boundary changes. The cleaned dataset enables researchers to distinguish between actual behavioral changes (such as residential relocations) and administrative boundary changes when analyzing geographic mobility patterns.

## Data Input
All data on territorial reforms was downloaded here: https://www.destatis.de/DE/Themen/Laender-Regionen/Regionales/Gemeindeverzeichnis/Namens-Grenz-Aenderung/namens-grenz-aenderung.html
[downloaded between July 02, 2025 and July 09, 2025]

## Codes
Run code/main.R to produce the output.

## Data Output
Three datasets will be stored in data/processed/csv and data/processed/dta, respectively. 

- county_reforms.csv, county_reforms.dta : a combined cleaned version of all reforms taking place from 1950 to 2024. Note that the only variables that have been added to the raw data is a county (Kreis) identifier for pre and post reform, and a reform_type variable with an additional category. In contrast to the raw data, the fifth category of reforms contains new additions or creations of legal entities. 

- county_switchers.csv, county_switchers.dta: this dataset contains reforms on year--pre county--post county level and contains reforms for which a positive amount of people have switched counties in response to a reform. For example, when analyzing residential mobility based on a change in county, this dataset can be used to identify county changes that could result from mere administrative reforms, in contrast to an actual residential relocation.  

- state_switchers.csv, state_switchers.dta: similar to county switchers, just constrained to state level. 

## R Version
- 4.5.0


## Package versions
- tidyverse "2.0.0"
- readxl "1.4.3"
- haven "2.5.4"
- lubridate "1.9.3"
