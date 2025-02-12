# Library ----
source("./library.R", echo = FALSE)

# Import  ---- 
df <- fread(paste0("./data/working_directory/03_scientificName_validation_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "Latin-1")

df0 <- df

# Data with the taxonomic classification of wild bees
taxonomy <- fread("./data/wildBeeClassification.csv", header = TRUE, 
                  sep = ";", strip.white = TRUE, encoding = "Latin-1")

## scientificName ----
# Check scientificName, if there are NA values
(sum(is.na(df$scientificName)))

# Taxonomic classification ----
## Save the original taxonomic classification ----
# Ensure that original taxonomic classification have been filled
# If the original classification is empty, add the current name. The current classification will be overwritten after with taxonomy dataframe.
df <- mutate(df,
             verbatimScientificNameAuthorship = scientificNameAuthorship,
             verbatimFamily                   = family,
             verbatimSubfamily                = subfamily,
             verbatimTribe                    = tribe,
             verbatimGenus                    = genus,
             verbatimSubgenus                 = subgenus,
             verbatimSpecificEpithet          = specificEpithet
) %>% 
  select(
    -c(scientificNameAuthorship, order, family, subfamily, tribe, genus, subgenus, specificEpithet)
  )

## Assign classification ----
# Assign the taxonomic classification to the dataset
df_taxonomy <- merge(df, taxonomy, by = "scientificName", all.x = TRUE)

## Check classification ----
df_taxonomy_check <- select(df_taxonomy, scientificName, family, subfamily, tribe, genus, subgenus, specificEpithet, 
                            verbatimFamily, verbatimGenus, verbatimSubgenus, verbatimSpecificEpithet)
# Check NA values
visdat::vis_miss(df_taxonomy_check)
naniar::gg_miss_var(df_taxonomy_check)  

# Export ----
# Check the number of rows
nrow(df0) - nrow(df)

# Export with fwrite
fwrite(df_taxonomy, paste0("./data/working_directory/04_taxonomy_classification_", Sys.Date(), ".csv"),
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
