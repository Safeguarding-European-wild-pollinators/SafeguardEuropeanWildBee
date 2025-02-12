# Required Libraries
# These packages are used for various steps in the data cleaning, visualization, and analysis process:

# Data handling and manipulation
library(data.table)   # Fast data manipulation and file I/O
library(dplyr)        # Data manipulation (filter, mutate, etc.)
library(purrr)        # Functional programming tools for working with lists and functions

# Date and time manipulation
library(lubridate)    # Work with date-times in R

# Visualization
library(ggplot2)      # Data visualization
library(RColorBrewer) # Color palettes for plots
library(scales)       # Scale functions for visualizations

# Spatial data handling and mapping
library(sf)           # Simple Features for spatial data manipulation
library(rnaturalearth)  # Retrieve country and geographical data
library(rnaturalearthdata)  # Data for rnaturalearth

# Writing and reading data
library(writexl)      # Write data to Excel format
library(readxl)       # Read Excel files
library(visdat)       # Visualizing missing data
library(naniar)       # Overviewing data

# Tools
library(red)          # IUCN Redlist Tools

# Summarizing and reporting
library(summarytools) # Summary statistics and tables for data exploration
library(visdat)       # Visualizing missing data

# Parallel processing
library(parallel)     # Parallel computing for faster processing of large datasets

# You can install missing packages using `install.packages("package_name")` or 
# `devtools::install_github("username/package_name")` if the package is not on CRAN.