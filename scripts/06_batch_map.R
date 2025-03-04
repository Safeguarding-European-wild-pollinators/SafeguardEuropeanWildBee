# Library ----
source("./library.R", echo = FALSE)

# Import ----
df <- fread(paste0("./data/working_directory/05_administrative_level_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "Latin-1")

# Spatial data ----

## Shapefile World ----
## Will be used as background of the map
#  Projection : European Terrestrial Reference System 1989 (ETRS89-extended) EPSG:3035. 
projection_3035 <- st_crs("EPSG:3035")
# Transforming the shapefile to the ETRS89-extended projection
world_3035 <- ne_countries(scale = "large", returnclass = "sf") %>% # rnaturalearth package allows to import shapefile
  st_transform(., projection_3035) # transform projection world 

world_3035$country <- world_3035$sovereignt # rename() doesn't work with sf object

## Shapefile Europe ----
europe_3035 <- st_read("./data/shapefile/stateProvince_country/european_codes_basemap_no_duplicates.shp") %>% 
  select(country) # Keep only the country and geometry column 
# Transforming the shapefile to the ETRS89-extended projection
europe_3035 <- st_transform(europe_3035, projection_3035)

## /!\ You have to remove data without coordinates /!\
df_distribution <- df
# Remove rows with missing coordinates
df_distribution <- df_distribution[complete.cases(df_distribution$decimalLongitude, df_distribution$decimalLatitude), ]
# Check the number of rows lost
nrow(df)-nrow(df_distribution)

# Converting the df_distribution DataFrame into a simple feature
# If you import directly in CRS = 3035, there are some issues with the coordinates
df_geometry <- st_as_sf(df_distribution, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326, remove = FALSE)  

# df_db will be used to output xlsx and csv files
# df_map will be used to generate maps
# Transformation of the simple feature df_distribution to the ETRS89-extended projection
df_db <- st_transform(df_geometry, projection_3035)

## Year interval ----
# Add a column with the intervals of the years
df_map <- df_db %>% 
  mutate(YEAR_INTERVAL = factor(
    case_when(
      is.na(endYear) ~ "No year",
      endYear < 1970 ~ "<1970",
      endYear >= 1970 & endYear <= 2000 ~ "1970-2000", 
      endYear > 2000 ~ ">2000"
    ),
    levels = c("No year", "<1970", "1970-2000", ">2000")
  ))

# Remove and order columns
source("./scripts/06B_select_columns.R", echo = FALSE)

# Check values
sum(is.na(df_map$YEAR_INTERVAL))
table(df_map$YEAR_INTERVAL)

### Color palet ----
# Attribute a color to each interval of years
col_year <-             c("#FFFFFF", "#B22123", "#FFA200",   "#7EB02D")
year_interval_value <-  c("No year", "<1970",   "1970-2000", ">2000")
color_mapping <- setNames(col_year, year_interval_value)


# Species summary ----
species_summary <- df_map %>%
  as.data.frame() %>% 
  select(scientificName, decimalLongitude, decimalLatitude, country) %>% 
  group_by(scientificName) %>%
  summarize(
    ABUNDANCE = n(),
    #  Area of Occupancy (AOO) and Extent of Occurrence (EOO) from the R package 'red'
    EOO = eoo(data.frame(decimalLongitude = as.numeric(decimalLongitude), decimalLatitude = as.numeric(decimalLatitude))),
    AOO = aoo(data.frame(decimalLongitude = as.numeric(decimalLongitude), decimalLatitude = as.numeric(decimalLatitude))),
    # Countries of occurrence (COO)
    COO = length(unique(country))
  ) %>% 
  as.data.frame() %>% 
  select(scientificName, ABUNDANCE, AOO, EOO, COO) %>% 
  arrange(scientificName) 


# Function batch ----
# Function to generate all species maps with a loop
generate_all_species_maps <- function(df_map, output_dir, df_db) {
  start_time_batch <- Sys.time()
  
  cat("=====================================================================================================", "\n", "Start batch map :", "\n")

    # Create a subdirectory for CSV files
    csv_dir <- file.path(output_dir, "CSV") 
    if (!dir.exists(csv_dir)) dir.create(csv_dir, recursive = TRUE)
    
    # Create a subdirectory for XLSX files
    xlsx_dir <- file.path(output_dir, "XLSX") 
    if (!dir.exists(xlsx_dir)) dir.create(xlsx_dir, recursive = TRUE)
    
    # Create map directory
    map_dir <- file.path(output_dir, "MAP")
    if (!dir.exists(map_dir)) dir.create(map_dir, recursive = TRUE)
    
    # List of species
    unique_species <- unique(df_map$scientificName)
    # Number of species
    num_total_species <- length(unique_species)
    
    # Loop over the species
    for (i in 1:num_total_species) {
      species_name <- unique_species[i]
      cat("- Current species : >>>  ", species_name, "\n")
      generate_species_map(df_map, species_name, csv_dir, xlsx_dir, map_dir, df_db)
      
      # Progress bar
      progress <- (i / num_total_species) 
      cat("Current progress : ", round(progress * 100, 0), "%\n", "___________________________________________________________________________________________________","\n")
    }
    
    cat("=====================================================================================================", "\n")

  end_time_batch <- Sys.time()
  (execution_time_all <- end_time_batch - start_time_batch)
  cat("===================================================================================================== \n")
}



# Function map ----
# Function map per species
# generate_species_map <- function(df_map, species_name, output_dir, csv_dir, xlsx_dir, map_dir) {
generate_species_map <- function(df_map, species_name, csv_dir, xlsx_dir, map_dir, df_db) {
  
  ## filter df_map for species ----
  filtered_data <- df_db %>%
    filter(scientificName == species_name) %>% 
    mutate(footPrintWKT = st_as_text(geometry)) %>% # Convert the geometry column to a character
    st_drop_geometry()  %>% # Remove the geometry column
    as.data.frame()
  
  ## arrange dot ----  
  df_map <- df_map %>%
    arrange(YEAR_INTERVAL, endYear) # prevents NA dots from being covered on top of other dots
  
  ## remove DELETE dots ---- 
  filtered_data_map <- df_map %>%
    filter(scientificName == species_name)
  
  ## ggplot ---- 
  p <- ggplot() +
    ### shp world ---- 
  geom_sf(data = world_3035, fill = "#EBEBEB", color = "#C1C1C1", linewidth = 0.4, inherit.aes = FALSE) +
    ### shp WB ---- 
  geom_sf(data = europe_3035, linewidth = 0.5,
          fill = "#FFFFF2", # country interior color
          color = "#C1C1C1", inherit.aes = FALSE) + # country border color
    ### dot ---- 
  geom_sf(data = filtered_data_map,
          aes(fill = YEAR_INTERVAL), # associate color mapping and the dataframe by YEAR_INTERVAL
          size = 2,
          shape = 21,
          stroke = 0.2,
          color = "black",
          na.rm = FALSE, inherit.aes = FALSE) +
    ### limit ---- 
  coord_sf(xlim = c(600000, 7700000), ylim = c(800000, 6800000), expand = FALSE) +  # Limit to Europe area
    ### color mapping ---- 
  scale_fill_manual(values = color_mapping, na.value = "purple", name = "Year") + # Color dot with color mapping
    ### grid ---- 
  scale_x_continuous(breaks = seq(-90, 90, by = 2)) + # grid longitude by 2
  scale_y_continuous(breaks = seq(-90, 90, by = 2)) + # grid latitude by 2
    ### legend ----
  guides(fill = guide_legend(override.aes = list(size = 8))) + # Adjust the size of points in the legend
    ### title ----
  labs(title = bquote(paste("Distribution of ", italic(.(species_name)))),
       caption = "Map of Europe (European Terrestrial Reference System 1989 extended projection)",
       fill = "Year") + # Legend title
    xlab(expression(paste("Longitude (", degree, ")"))) +
    ylab(expression(paste("Latitude (", degree, ")"))) +
    ### theme ----
  theme_minimal() +
    theme(
      panel.ontop = FALSE,  # grid layer forward
      plot.margin = margin(t = 1,  # Top margin
                           r = 0,  # Right margin
                           b = 0,  # Bottom margin
                           l = 1), # Left margin
      plot.caption = element_text(color = "black", face = "plain", size = 7),
      axis.text.x = element_text(angle = 90, hjust = 1),
      axis.text = element_text(size = 9),
      axis.title = element_text(size = 8, face = "plain" ), # Latitude and Longitude
      legend.position = "right",
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(0.2, "cm"),
      legend.text = element_text(size = 9), # size text legend
      legend.title = element_text(size = 9, margin = margin(b = 10)), # size title legend (YEAR)
      plot.background = element_rect(fill = "white",
                                     color = "white", size = 0),
      panel.border = element_rect(color = "grey", fill = "transparent", size = 1),
      panel.background = element_rect(fill = "aliceblue"), # background color (water)
      panel.grid.major = element_line(color = "grey", linetype = "solid", size = 0.5)
    )
  

  
  # ----------- PNG ----------- #
  ### export ---- 
  #### png ---- 
  filename_png <- file.path(map_dir, paste0(gsub(" ", "_", species_name), ".png"))
  ggsave(filename = filename_png, plot = p, device = "png", width = 14, height = 10, bg = "white", dpi = 120)
  cat("Map exported:        ", filename_png, "\n")
  # ----------- PNG ----------- #
  
  # ----------- CSV ----------- #
  # Save the filtered data to a CSV file with fwrite()
  filename_csv <- file.path(csv_dir, paste0(gsub(" ", "_", species_name), ".csv"))
  fwrite(filtered_data, file = filename_csv, sep = ";", quote = FALSE, na = "", row.names = FALSE, nThread = detectCores())
  cat("CSV file exported:  ", filename_csv, "\n")
  # ----------- CSV ----------- #
  
  # ----------- XLSX ----------- #
  # Save the filtered data to an XLSX file with write_xlsx()
  filename_xlsx <- file.path(xlsx_dir, paste0(gsub(" ", "_", species_name), ".xlsx"))
  write_xlsx(filtered_data, path  = filename_xlsx)
  cat("XLSX file exported: ", filename_xlsx, "\n")
  # ----------- XLSX ----------- #
  
}


# Create output directory
output_directory <- paste0("./output/test_", Sys.Date(), "_06_batch_maps")
dir.create(output_directory, showWarnings = FALSE, recursive = TRUE)

# Batch map ----
# Launch the batch map generation
generate_all_species_maps(df_map, output_directory, df_db)

# Export species summary
write_xlsx(species_summary, paste0(directory, Sys.Date(), "species_summary.xlsx"))



# Remove objects from memory
rm(list = ls())
gc()
