# German Territorial Reforms Data Cleaning
A data cleaning pipeline for processing German territorial reforms: "Gebietsänderungen (Namens-, Grenz- und Schlüsseländerungen)" from 1950 to 2024.


## Overview
This repository contains code to clean administrative territorial reform data from Germany, tracking especially (but not exclusively) municipality (Gemeinde) and county (Kreis) boundary changes. The cleaned dataset was created for the purpose to distinguish behavioral changes of counties (e.g. moves in form of relocating a place of living) from administrative changes of counties. 


## Data
All data on territorial reforms was downloaded here: https://www.destatis.de/DE/Themen/Laender-Regionen/Regionales/Gemeindeverzeichnis/Namens-Grenz-Aenderung/namens-grenz-aenderung.html
[downloaded between July 02, 2025 and July 09, 2025]


## R Version
- code was written using R 4.5.0


## Package versions
- tidyverse "2.0.0"
- readxl "1.4.3"
- haven "2.5.4"
- lubridate "1.9.3"
