# Library ----
source("./library.R", echo = FALSE)
library(fuzzyjoin) # More information: https://www.statology.org/fuzzy-matching-in-r/

# Import ----
# Import all data
df <- fread(paste0("./data/1_import_data_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ",", dec = ".", strip.white = FALSE, encoding = "UTF-8")

# Import dictionary
dictionary <- fread("./data/dictionary.csv", header = TRUE, 
                    sep = ";", dec = ".", strip.white = FALSE, encoding = "UTF-8")


# Validation name process ----
df <- df %>% 
  rename(TAXON_ORIGINAL = verbatimScientificName,
         TAXON_TO_EVALUATE = ScientificName) %>% 
  as.data.table(df)

## df_dico  ---- 
## Check names with dictionary :
df_dico <- copy(df) # Used as a backup
df_dico[dictionary, c("TAXON_DICO") := .(TAXON_DICO),
        on = .(TAXON_TO_EVALUATE = TAXON_ERRORS)]
## Create a "VALIDATION_NAME" column determined by the value of "TAXON_DICO".
# If it is not a valid name in the dictionnary ("-" value), it's correspond to DELETE value, if it's correct the value is "OK", otherwise the value is NA.
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

# export ----
# Export the data to an Excel file
write_xlsx(TAXON_fuzzy, "./output/TAXON_fuzzy.xlsx") 

# Export only data with correct species names
df_valid <- filter(df, VALIDATION_NAME == "OK")
fwrite(df_valid, paste0("./data/2_quality_check_", Sys.Date(), ".csv"))

# Remove objects from memory
rm(list = ls())
gc()
