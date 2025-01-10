# Library ----
source("./library.R", echo = FALSE)

# import ----
# Import all the data from the dataset folder
files_list <- list.files(path = "./data/dataset_folder/", pattern = "\\.csv$", full.names = TRUE) # List all .csv files in folder

# Choose the number of cores to improve import speed
nThread <- detectCores() - 4

# Import all data
df <- purrr::map_df(files_list, ~{
  file_name <- basename(.x) # basename() keep only the file name without the path
  data <- fread(.x, header = TRUE, strip.white = FALSE, encoding = "UTF-8", nThread = nThread) #strip.white = FALSE prevents R to delete space
  data[, FILE_NAME := file_name] # Create FILE_NAME column
  data
}) %>%
  as.data.table() # Ensure that the data is a data.table

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


# Export ----
fwrite(df, paste0("./data/1_import_data_", Sys.Date(), ".csv"), 
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
