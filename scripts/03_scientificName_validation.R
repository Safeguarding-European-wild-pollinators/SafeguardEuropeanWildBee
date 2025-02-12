# Library ----
source("./library.R", echo = FALSE)
library(fuzzyjoin) # More information: https://www.statology.org/fuzzy-matching-in-r/

# Import ----
# Import all data
df <- fread(paste0("./data/working_directory/02_quality_check_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "Latin-1")
df0 <- df # Save the original data

# Import dictionary
dictionary <- fread("./data/wildBeeDictionary.csv", header = TRUE, 
                    sep = ";", dec = ".", strip.white = FALSE, encoding = "UTF-8")

# Import checklist (list of species)
checklist <- fread("./data/wildBeeChecklist.csv", header = TRUE, 
                    sep = ";", dec = ".", strip.white = FALSE, encoding = "UTF-8")

# Data wrangling ----
# Add a column to check if the species is in the checklist
df <- df %>% 
  mutate(isChecklist = ifelse(scientificName %in% checklist$scientificName, TRUE, FALSE))

# Check values:
table(df$isChecklist, useNA = "always")

# Ensure that scientific names have been completed
# If the original scientificName is empty, add the current name.
# If the current scientificName has not been filled in, add the original name.
# This ensures that scientific name information has not been lost, as scientificName will be overwritten later.
df <- mutate(df,
             verbatimScientificName = scientificName)


# Validation name process ----
df <- df %>% 
  mutate(TAXON_ORIGINAL = verbatimScientificName,
         TAXON_TO_EVALUATE = scientificName) %>% 
  as.data.table(df)

## df_dico  ---- 
## Check names with dictionary :
df_dico <- copy(df) # Used as a backup
df_dico[dictionary, c("TAXON_DICO") := .(TAXON_DICO),
        on = .(TAXON_TO_EVALUATE = TAXON_ERRORS)]
## Create a "VALIDATION_NAME" column determined by the value of "TAXON_DICO".
# If it is not a valid name in the dictionary ("-" value), it's correspond to DELETE value, if it's correct the value is "OK", otherwise the value is NA.
df_dico <- mutate(df_dico, VALIDATION_NAME = ifelse(is.na(TAXON_DICO), NA, ifelse(TAXON_DICO == "-", "DELETE", "OK"))) 
df_dico <- mutate(df_dico, 
                  VALIDATION_NAME = ifelse(is.na(TAXON_TO_EVALUATE), "DELETE",        # If TAXON_TO_EVALUATE is NA, then VALIDATION_NAME is "DELETE".
                                           ifelse(is.na(TAXON_DICO), NA,              # if TAXON_DICO is NA, then VALIDATION_NAME is also NA.
                                                  ifelse(TAXON_DICO == "-", "DELETE", # if TAXON_DICO is "-", then VALIDATION_NAME is "DELETE". 
                                                         "OK"))))                     # in all other cases, VALIDATION_NAME is "OK"
# Check values:
table(df_dico$VALIDATION_NAME, useNA = "always")

## valid  ---- 
# We store data OK and DELETE
df_valid_dico <- copy(df_dico) # Used as a backup     
df_valid_dico <- df_valid_dico[VALIDATION_NAME %in% c("OK", "DELETE")] # similar to: filter(df_valid_dico, VALIDATION_NAME %in% c("OK", "DELETE"))

# Check values:
table(df_valid_dico$VALIDATION_NAME, useNA = "always")


## invalid  ---- 
## We store data NA, the value in VALIDATION_NAME is changed to "TO_CHECK", these values must be evaluated manually
df_invalid_dico <- copy(df_dico) # Used as a backup   
df_invalid_dico <- df_invalid_dico[is.na(VALIDATION_NAME), ] # similar to: filter(df_invalid_dico, is.na(VALIDATION_NAME)) 

# Check values:
table(df_invalid_dico$VALIDATION_NAME, useNA = "always")

df_invalid_dico[is.na(VALIDATION_NAME), VALIDATION_NAME := "TO_CHECK"] # change the value to "TO_CHECK"

# Check values:
table(df_invalid_dico$VALIDATION_NAME, useNA = "always")
table(df_invalid_dico$TAXON_TO_EVALUATE, useNA = "always") %>% as.data.frame() %>% arrange(desc(Freq)) # Check species not listed in the dictionary

## fuzzy search  ---- 
# Match species names not found in the dictionary using a similarity score
# You can after complete the dictionary with the closest species names if it's seems correct

# Rename columns
TAXON_invalid <- df_invalid_dico %>%
  rename(TAXON = TAXON_TO_EVALUATE) %>% # need to have the same column name as in the dictionary
  select(TAXON)

# Rename columns
TAXON_dico <-  dictionary %>%
  rename(TAXON = TAXON_DICO) %>% # need to have the same column name as in the invalid_TAXON
  select(TAXON)

# Fuzzy join
TAXON_fuzzy <- stringdist_join(TAXON_invalid, TAXON_dico,
                               by = "TAXON" , # match based on TAXON column
                               mode = "left", # use left join
                               method = "jw", # use Jaro-Winkler distance metric
                               max_dist = 99,
                               distance_col = "dist") %>%
  group_by(TAXON.x) %>%
  slice_min(dist) %>% # select the row with the smallest distance for each TAXON.x
  distinct() %>% # only unique rows are retained
  arrange(dist) %>% 
  rename(TAXON_TO_EVALUATED = TAXON.x,
         TAXON_DICO = TAXON.y,
         DISTANCE = dist)  # rename the columns)

# Export ----
## export Fuzzy name ----
# Export the fuzzy name to an Excel file
dir.create("./output", showWarnings = FALSE)
write_xlsx(TAXON_fuzzy, "./output/TAXON_fuzzy.xlsx") 

## export validated data ----
# Export only data with correct species names
table(df_dico$VALIDATION_NAME, useNA = "always")

# # Add a column to check if the species is in the checklist
# df_dico <- df_dico %>% 
#   mutate(isChecklist = ifelse(scientificName %in% checklist$scientificName, TRUE, FALSE))

# Check values:
table(df_dico$isChecklist, useNA = "always")

# Check species not listed in the checklist
is_not_in_checklist <- filter(df_dico, isChecklist == FALSE)

# Keep only validated rows
df_valid <- filter(df_dico, VALIDATION_NAME == "OK") %>% 
  # mutate(scientificName = TAXON_TO_EVALUATE, # 
  #        verbatimScientificName = TAXON_ORIGINAL) %>% 
  select(-VALIDATION_NAME, -TAXON_DICO, -TAXON_ORIGINAL, -TAXON_TO_EVALUATE, -isChecklist)


# Check the number of rows
nrow(df0) - nrow(df_valid)

# Export with fwrite
fwrite(df_valid, paste0("./data/working_directory/03_scientificName_validation_", Sys.Date(), ".csv"),
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
