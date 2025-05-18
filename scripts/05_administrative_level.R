# 0) Library ---- 
source("./library.R", echo = FALSE)

# 1) Import ----
## 1.1) Import dataset ----
df <- fread(paste0("./data/working_directory/04_taxonomy_classification_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "Latin-1")

df0 <- df %>% select( -country,-stateProvince, -county) 

## 1.2) Import shapefile ----
# Define projection
projection_3035 <- st_crs("EPSG:3035")
### 1.3) country and stateProvince ----
# Shapefile used to assign country and stateProvince fields
stateProvince_country_shp <- st_read("./data/shapefile/stateProvince_country/european_codes_basemap_no_duplicates.shp") %>%  
  st_transform(projection_3035) %>%  # Transform to projection 3035
  rename(stateProvince = name) %>% 
  select(stateProvince, country) # Select columns

### 1.4) county ----
# Shapefile used to assign county field
county_shp <- st_read("./data/shapefile/county/gaul1_asap.shp") %>%  
  st_transform(projection_3035) %>%  # Transform to projection 3035
  rename(county = name1, 
         country = name0) %>% 
  select(county) # Select columns

# 2) Data wrangling ----
# !!! Remove rows with NA values in decimalLongitude and decimalLatitude !!!
# Missing values in st_as_sf() are not allowed
df <- df[complete.cases(df$decimalLongitude, df$decimalLatitude), ]

# Transform df to sf object
df <- st_as_sf(df, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326, remove = FALSE) %>% # Transform to sf object
  st_transform(projection_3035) # Transform to projection 3035

# Remove old columns, will be assigned
df <- df %>% select( -country,-stateProvince, -county) 

##  2.1) Assign country and stateProvince ----
chrono1 <- Sys.time()
stateProvince_country <- st_intersection(df, stateProvince_country_shp, remove = FALSE) %>% arrange(occurrenceID)
chrono2 <- Sys.time()
chrono2 - chrono1 

# Retrieve data outside the shapefiles
missing_stateProvince_country <- df %>%
  anti_join(as.data.frame(stateProvince_country), by = "occurrenceID") %>% 
  mutate(
    country = "not available", 
    stateProvince = "not available")

# Bind data
stateProvince_country <- rbind(stateProvince_country, missing_stateProvince_country)

# Left join country and stateProvince
stateProvince_country <- stateProvince_country %>% select(occurrenceID, stateProvince, country) %>% 
  st_drop_geometry() # Remove geometry column

# Join country and stateProvince
df_stateProvince_country <- left_join(df0, stateProvince_country, by = "occurrenceID")
nrow(df_stateProvince_country) == nrow(df0)

##  2.2) Assign county ----
chrono1 <- Sys.time()
county <- st_intersection(df, county_shp, remove = FALSE) %>% arrange(occurrenceID)
chrono2 <- Sys.time()
chrono2 - chrono1 

# Retrieve data outside the shapefiles
missing_county <- df %>%
  anti_join(as.data.frame(county), by = "occurrenceID") %>% 
  mutate(
    county = "not available")

# Bind data
county <- rbind(county, missing_county)

# Left join county
county <- county %>% select(occurrenceID, county) %>% 
  st_drop_geometry() # Remove geometry column

# Join administrative level
df_admin <- left_join(df_stateProvince_country, county, by = "occurrenceID")
nrow(df_admin) == nrow(df0)

# Check values
table(df_admin$country, useNA = "always")


# Export ----
# Check the number of rows
nrow(df0) - nrow(df)
# Export with fwrite
fwrite(df_admin, paste0("./data/working_directory/05_administrative_level_", Sys.Date(), ".csv"),
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()

