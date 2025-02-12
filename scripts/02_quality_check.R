# Library ----
# Load required libraries from an external script
source("./library.R", echo = FALSE)

# Import ----
source("./scripts/function.R", echo = FALSE)
# Load the dataset from the CSV file with proper encoding and delimiters
df <- fread(paste0("./data/working_directory/01_data_import_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "Latin-1")

# Create a backup of the original dataset
df0 <- df


# Overview ----
## Summary ----
# Summary of each field of the dataset
view(summarytools::dfSummary(df))

## Missing data ----
# Visualizing missing data
visdat::vis_dat(df)

# Show the number of missing values (value = "") in each column
# NA means missing values
# >0 means the number of missing values 
# NA is different from 0
(empty_values <- apply(df, 2, function(x) sum(x == "")))

# Show the number of missing values (value = NA) in each column
(NA_values <- apply(df, 2, function(x) sum(is.na(x))))


# Metadata ----
# Identify file names associated with missing metadata values
(file_names <- df %>% filter(is.na(databaseName))    %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(institutionName)) %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(projectSource))   %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(projectUpdate))   %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(datasetName))     %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(datasetProvider)) %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(datasetSource))   %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(license))         %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(occurrenceID))    %>% pull(FILE_NAME) %>%  unique() )

# Display frequency tables including missing values
table(df$databaseName,     useNA = "always")
table(df$institutionName,  useNA = "always")
table(df$projectSource,    useNA = "always")
table(df$projectUpdate,    useNA = "always")
table(df$datasetName,      useNA = "always")
table(df$datasetProvider,  useNA = "always")
table(df$datasetSource,    useNA = "always")
table(df$license,          useNA = "always")

# Specimen data ----
## scientificName ----
# Check for missing values in scientificName fields
(sum(is.na(df$scientificName)))

## occurrenceID ----
### occurrenceID NA ----
# It is essential that the dataset has no duplicates, as the following codes may not work as expected
# Check for missing occurrenceID values
(sum(is.na(df$occurrenceID)) )
# Identify file names with missing occurrenceID values
(file_names <- df %>% filter(is.na(occurrenceID)) %>% pull(FILE_NAME) )

### occurrenceID duplicated ----
# Identify duplicated occurrenceID values (both first and subsequent occurrences)
duplicates <- duplicated(df$occurrenceID) | duplicated(df$occurrenceID, fromLast = TRUE) # first and next occurence of duplicated values

# Extract duplicated values along with their file names
duplicated_values <- df[duplicates, c("occurrenceID", "FILE_NAME")] %>%  # extract from df the duplicated values and select two columns
  arrange(occurrenceID) # Sort by occurrenceID

# Display data entries with duplicated occurrenceIDs
duplicated_values

# List of unique files containing duplicated occurrenceIDs
(unique(duplicated_values$FILE_NAME))

## individualCount ----
# Display frequency tables for individual count fields, including missing values
table(df$individualCountStart, useNA = "always")
table(df$individualCountEnd,   useNA = "always")

# Check if individualCountStart contains any non-integer values (floats or strings)
check_integers(df, individualCountStart)
check_integers(df, individualCountEnd)

# Date ----
## date type ----
# Check if date contains any non-integer values (floats or strings)
check_integers(df, yearStart)
check_integers(df, monthStart)
check_integers(df, dayStart)

check_integers(df, yearEnd)
check_integers(df, monthEnd)
check_integers(df, dayEnd)

# Check if there are incorrect characters
# Save occurrenceID before conversion
occurrenceID_before <- df %>%
  filter(is.na(yearEnd) | is.na(monthEnd) | is.na(dayEnd)) %>%
  select(occurrenceID) %>% 
  as.data.frame()

# Convert columns to integer
df2 <- df %>%
  mutate(
    yearEnd = as.integer(yearEnd),
    monthEnd = as.integer(monthEnd),
    dayEnd = as.integer(dayEnd)
  )

# NA values after conversion
occurrenceID_after <- df2 %>%
  filter(is.na(yearEnd) | is.na(monthEnd) | is.na(dayEnd)) %>%
  select(occurrenceID) %>% 
  as.data.frame()

# Check occurrenceID if data were lost
(occurrenceID_diff <- anti_join(occurrenceID_after, occurrenceID_before, by = "occurrenceID"))

# Create a new dataframe with the occurrenceID that have been lost
df_occurrenceID_diff <- df[df$occurrenceID %in% occurrenceID_diff$occurrenceID, ]
# Show the file name of the lost occurrenceID
unique(df_occurrenceID_diff$FILE_NAME)

# Execute the code below when you are sure you will not lose information
df <- df %>%
  mutate(
    yearStart = as.integer(yearStart),
    monthStart = as.integer(monthStart),
    dayStart = as.integer(dayStart)
  )

## Year ----
# histogram of the distribution of years
# Change binwidth to your needs
# binwidth = width of bar
ggplot(df, aes(x = yearEnd)) +
  geom_histogram(binwidth = 20, fill = "#CC99FF", color = "black", alpha = 0.7, na.rm = TRUE) + 
  labs(title = "Distribution of Years", x = "Year", y = "Frequency") +
  theme_minimal()

# Check the minimum and maximum values
min_threshold_year <- 1900
max_threshold_year <- 2025
check_value_range(df, c("yearStart", "yearEnd"), 
                  min_threshold = min_threshold_year, max_threshold = max_threshold_year)

# Check extreme values of years
year_check <- df %>%
  filter(yearEnd < min_threshold_year | yearEnd > max_threshold_year) %>% # Check extreme values
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd) %>% 
  arrange(desc(yearEnd))

## Month ----
# histogram of the distribution of months
ggplot(df, aes(x = factor(monthEnd))) +
  geom_bar(fill = "#CCFF99", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Months", x = "Month", y = "Frequency") +
  theme_minimal()

# Check the minimum and maximum values
min_threshold_month <- 1
max_threshold_month <- 12
check_value_range(df, c("monthStart", "monthEnd"), 
                  min_threshold = min_threshold_month, max_threshold = max_threshold_month)

# Check extreme values of month
month_check <- df %>%
  filter(monthEnd > max_threshold_month) %>% 
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd) %>% 
  arrange(desc(yearEnd))

## Day ----
# histogram of the distribution of days
ggplot(df, aes(x = factor(dayEnd))) +
  geom_bar(fill = "#FFFF66", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Days", x = "Day", y = "Frequency") +
  theme_minimal()

# Check the minimum and maximum values
min_threshold_day <- 1
max_threshold_day <- 31
check_value_range(df, c("dayStart", "dayEnd"), 
                  min_threshold = min_threshold_day, max_threshold = max_threshold_day)

# Check extreme values of day
day_check <- df %>%
  filter(dayEnd > max_threshold_day) %>% 
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd) %>% 
  arrange(desc(yearEnd))

## eventDate ----
### Save the original eventDate in verbatimEventDate ----
df <- mutate(df, verbatimEventDate = eventDate)
# Concatenate date
df <- df %>% mutate(eventDate = paste0(yearEnd, "-", monthEnd, "-", dayEnd))


# Coordinate ----
## Coordinate NA ----
(sum(is.na(df$decimalLatitude)) )
(sum(is.na(df$decimalLongitude)) )

### non-NA % ----
### Calculate and display the percentage and count of non-NA decimalLatitude values
cat("Percentage of decimalLatitude values: ", "\n", sum(!is.na(df$decimalLatitude)) / nrow(df) * 100, "%", "\n", "\n",
    "Row number of decimalLatitude values:", "\n", sum(!is.na(df$decimalLatitude)), "\n",
    "Total number of rows:", "\n", nrow(df), "\n")
# show the file names with NA values
(file_names <- df %>% filter(is.na(decimalLatitude)) %>% pull(FILE_NAME) %>%  unique() )

### Calculate and display the percentage and count of non-NA decimalLongitude values
cat("Percentage of decimalLongitude values: ", "\n", sum(!is.na(df$decimalLongitude)) / nrow(df) * 100, "%", "\n", "\n",
    "Row number of LONGITUDE values:", "\n", sum(!is.na(df$decimalLongitude)), "\n",
    "Total number of rows:", "\n", nrow(df), "\n")
# show the file names with NA values
(file_names <- df %>% filter(is.na(decimalLongitude)) %>% pull(FILE_NAME) %>%  unique() )

### ---- plot NA % ----
na_percentage <- df %>%
  group_by(FILE_NAME) %>%
  summarise(na = sum(is.na(decimalLatitude)),
            nrow = n()) %>%  
  mutate(na_percentage = (na / nrow) * 100) %>% 
  filter(na_percentage > 0) %>% 
  arrange(desc(na_percentage)) %>% 
  mutate(FILE_NAME = factor(FILE_NAME, levels = FILE_NAME))

# Plot dataset with NA values
# It is blank if there are no NA values
ggplot(na_percentage, aes(x = FILE_NAME, y = na_percentage)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Percentage of NA values in LATITUDE for each FILE_NAME",
       x = "FILE_NAME",
       y = "Percentage of NA values") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

### Convert to numeric ----
### This step ensures that coordinate values are numeric before spatial data processing.
### It helps detect incorrect formatting, such as commas (",") instead of decimal points ("."), 
### which could cause issues during data wrangling.

#### Detect values lost after conversion ----
# Count the number of NA values in decimalLatitude and decimalLongitude before conversion
na_before_latitude <- sum(is.na(df$decimalLatitude))
na_before_longitude <- sum(is.na(df$decimalLongitude))

# Convert coordinates to numeric
df2 <- df %>%
  mutate(
    decimalLatitude = as.numeric(decimalLatitude),
    decimalLongitude = as.numeric(decimalLongitude)
  )

# Count the number of NA values after conversion
na_after_latitude <- sum(is.na(df2$decimalLatitude))
na_after_longitude <- sum(is.na(df2$decimalLongitude))

# Calculate how many values were transformed into NA due to conversion issues
na_converted_latitude <- na_after_latitude - na_before_latitude
na_converted_longitude <- na_after_longitude - na_before_longitude

# Display the number of values lost during conversion
cat("Number of values transformed into NA for LATITUDE: ", na_converted_latitude, "\n")
cat("Number of values transformed into NA for LONGITUDE: ", na_converted_longitude, "\n")

# Check if there are incorrect characters
df_no_numerique <- df[!grepl("^[0-9.]+$", df$decimalLatitude), ]
table(df_no_numerique$decimalLatitude)


#### conversion ----
# Convert the decimal separator “,” to “.”
# Save occurrenceID before conversion
occurrenceID_before <- df %>%
  filter(is.na(decimalLatitude) | is.na(decimalLongitude)) %>%
  select(occurrenceID) %>% 
  as.data.frame()

# Execute the code below when you are sure you will not lose information
# Convert columns to numeric
df <- df %>%
  mutate(
    decimalLatitude = gsub(",", ".", decimalLatitude), # Replace commas with dots (if not we get NA values)
    decimalLongitude = gsub(",", ".",decimalLongitude),
    decimalLatitude = as.numeric(decimalLatitude), # as.numeric() ignore float numbers with commas
    decimalLongitude = as.numeric(decimalLongitude)
  )

# NA values after conversion
occurrenceID_after <- df %>%
  filter(is.na(decimalLatitude) | is.na(decimalLongitude)) %>%
  select(occurrenceID) %>% 
  as.data.frame()

# Check occurrenceID, if data were lost
occurrenceID_diff <- anti_join(occurrenceID_after, occurrenceID_before, by = "occurrenceID")
occurrenceID_diff

# Create a new dataframe with the occurrenceIDs that have been lost
df_occurrenceID_diff <- df[df$occurrenceID %in% occurrenceID_diff$occurrenceID, ]
# Show the DB names of the lost occurrenceIDs
unique(df_occurrenceID_diff$FILE_NAME)


## Overview of coordinate ----
# This code visualizes the distribution of the coordinates
# Vline show the limits of the study scope

### latitude plot ----
# Create a dataframe counting occurrences of each unique latitude
latitude_distribution <- as.data.frame(table(df$decimalLatitude))
colnames(latitude_distribution) <- c("decimalLatitude", "Frequency")

# Latitude distribution plot
ggplot(latitude_distribution, aes(x = as.numeric(as.character(decimalLatitude)), y = Frequency)) +
  geom_bar(stat = "identity", fill = "lightcoral", color = "lightcoral") +
  # Add vertical lines to show study area boundaries
  # 81°N corresponds to Svalbard and Jan Mayen Islands
  # 14°N corresponds to Cape Verde
  geom_vline(xintercept = c(14, 81), color = "red", linetype = "dashed", size = 1) + 
  theme_minimal() +
  labs(title = "Latitude distribution", x = "Latitude", y = "Frequency") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

### longitude plot ----
# Create a dataframe counting occurrences of each unique longitude
longitude_distribution <- as.data.frame(table(df$decimalLongitude))
colnames(longitude_distribution) <- c("decimalLongitude", "Frequency")

# Longitude distribution plot
ggplot(longitude_distribution, aes(x = as.numeric(as.character(decimalLongitude)), y = Frequency)) +
  geom_bar(stat = "identity", fill = "#97DEF0", color = "#97DEF0") +
  # Add vertical lines to show study area boundaries
  # -32° corresponds to the Azores
  # 70° corresponds to Arkhangelsk Oblast
  geom_vline(xintercept = c(-32, 70), color = "blue", linetype = "dashed", size = 1) + 
  theme_minimal() +
  labs(title = "Longitude distribution", x = "Longitude", y = "Frequency") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))


# Coordinates provided ----
(sum(is.na(df$manualGeoreferencing)) )
cat("Percentage of NA (manualGeoreferencing):\n", sum(is.na(df$manualGeoreferencing))/ nrow(df)*100, "% \n")

## plot NA % ----
provided_percentage <- df %>%
  group_by(datasetName) %>%
  summarise(na = sum(is.na(manualGeoreferencing)),
            nrow = n()) %>%  
  mutate(provided_percentage = (na / nrow) * 100) %>% 
  filter(provided_percentage > 0) %>% 
  arrange(desc(provided_percentage)) %>% 
  mutate(datasetName = factor(datasetName, levels = datasetName))

ggplot(provided_percentage, aes(x = datasetName, y = provided_percentage)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = nrow), vjust = -0.5) +  # Ajouter les annotations de nrow
  theme_minimal() +
  labs(title = "Percentage of NA values in manualGeoreferencing for each FILE_NAME",
       x = "FILE_NAME",
       y = "Percentage of NA values") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))


# Country ----
# Frequencies of countries
country <- as.data.frame(table(df$country)) %>%
  rename(country = Var1, FREQUENCY = Freq) %>%
  arrange(desc(FREQUENCY), country)

# Reorder the factor levels of country based on FREQUENCY
country$country <- factor(country$country, levels = country$country)

# plot
ggplot(country, aes(x = country, y = FREQUENCY, fill = country)) +
  geom_bar(stat = "identity") +  # Use frequencies as values for bar heights
  labs(title = "Number of rows per country",  # Title of the plot
       x = "Country",  # X-axis label
       y = "Number of rows") +  # Y-axis label
  geom_text(aes(label = FREQUENCY), vjust = -0.5, color = "black", size = 3) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

# Export ----
# Check if rows were deleted
nrow(df0) - nrow(df)

# Export with fwrite
fwrite(df, paste0("./data/working_directory/02_quality_check_", Sys.Date(), ".csv"),
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
