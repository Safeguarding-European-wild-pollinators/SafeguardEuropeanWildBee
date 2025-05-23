# First, don't forget to install the packages if you haven't done it yet
# source('install_packages.R')

# Library ----
source("./library.R", echo = FALSE)

# import ----
# Import all the data from the dataset folder
files_list <- list.files(path = "./data/working_directory/", pattern = "\\.csv$", full.names = TRUE) # List all .csv files in folder

# Choose the number of cores to improve import speed
nThread <- detectCores() - 2

# Import all data
df <- purrr::map_df(files_list, ~{
  file_name <- basename(.x) # basename() keep only the file name without the path
  data <- fread(.x, header = TRUE, strip.white = FALSE, encoding = "Latin-1", 
                nThread = nThread, colClasses = "character") #strip.white = FALSE prevents R to delete space
  data[, FILE_NAME := file_name] # Create FILE_NAME column
  data
}) %>%
  as.data.table() # Ensure that the data is a data.table

df0 <- df # Save the original data



# Cleaning character ----
# Function that applies iconv and gsub to a column
clean_column <- function(column) {
  column <- iconv(column, to = "UTF-8", sub = "")
  column <- gsub("�", "", column)
  return(column)
}

# Apply function to all dataframe columns
clean_all_columns <- function(df) {
  df <- df %>%
    mutate(across(everything(), ~ clean_column(.)))
  return(df)
}

df <- clean_all_columns(df)

# Check the number of rows
nrow(df0) - nrow(df)

# Export ----
fwrite(df, paste0("./data/working_directory/01_data_import_", Sys.Date(), ".csv"), 
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
