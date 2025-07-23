columns <- c(
  # Metadata
  "databaseName",
  "institutionName", 
  "projectSource",
  "datasetName",
  "license",
  "occurrenceID",
  
  # Specimen
  "order",
  "family",
  "subfamily",
  "tribe",
  "subgenus",
  "genus",
  "scientificName",
  "infraspecificEpithet",
  "sex", 
  "individualCountInterval",
  "startIndividualCount",
  "endIndividualCount",
  
  # Temporal
  "endYear",
  "endMonth",
  "endDay",
  "startYear",
  "startMonth",
  "startDay",
  
  # Spatial
  "country",
  "stateProvince",
  "county",
  "verbatimLocality",
  "decimalLatitude",
  "decimalLongitude",
  "coordinatePrecision",
  "manualGeoreferencing",
  "geometry"
)

#colnames(df)
cat("Columns in df_geometry before conversion to template:", "\n", ncol(df_geometry), "\n")
df_geometry_before <- df_geometry 
df_geometry_after <- df_geometry %>% select(all_of(columns))
cat("Columns in df_geometry after conversion to template:", "\n", ncol(df_geometry_after), "\n")


original_columns <- names(df_geometry_before)
selected_columns <- names(df_geometry_after)
columns_removed <- setdiff(original_columns, selected_columns)
cat("The following columns have not been retained :\n")
print(columns_removed)
