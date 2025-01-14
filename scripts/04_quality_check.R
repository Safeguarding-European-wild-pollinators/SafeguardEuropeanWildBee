# Library ----
source("./library.R", echo = FALSE)

# Import ----
# Import all data
df <- fread(paste0("./data/working_directory/03_taxonomy_classification_", Sys.Date(), ".csv"), header = TRUE, 
            sep = ";", dec = ".", strip.white = FALSE, encoding = "UTF-8")

df0 <- df # Used as a backup

# Quality check ----

## scientificName ----
# verification scientificName, if there are NA values
(sum(is.na(df$scientificName)))
(sum(is.na(df$verbatimScientificName)))

## occurrenceID ----
### occurrenceID NA ----
# Check occurrenceID, if there are NA values
(sum(is.na(df$occurrenceID)) )
# show the file names with NA values
(file_names <- df %>% filter(is.na(occurrenceID)) %>% pull(FILE_NAME) )

### occurrenceID duplicated  ----
duplicates <- duplicated(df$occurrenceID) | duplicated(df$occurrenceID, fromLast = TRUE) # first and next occurence of duplicated values
duplicated_values <- df[duplicates, c("occurrenceID", "FILE_NAME")] %>%  # extract from df the duplicated values and select two columns
  arrange(occurrenceID) # sort by occurrenceID
# Data with duplicated
duplicated_values
# List of files with duplicated
(unique(duplicated_values$FILE_NAME))


# Metadata ----
# Check metadata, if there are NA values
(sum(is.na(df$datasetName)))
(sum(is.na(df$dataProvider)))
(sum(is.na(df$rightsHolder)))
(sum(is.na(df$license)))

# show the file names with NA values
(file_names <- df %>% filter(is.na(datasetName))   %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(dataProvider))  %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(rightsHolder))  %>% pull(FILE_NAME) %>%  unique() )
(file_names <- df %>% filter(is.na(license))  %>% pull(FILE_NAME) %>%  unique() )

# Check metadata
table(df$datasetName, useNA = "always")
table(df$dataProvider, useNA = "always")
table(df$rightsHolder, useNA = "always")
table(df$license, useNA = "always")


# Coordinate ----
## Coordinate NA ----
(sum(is.na(df$decimalLatitude)) )
(sum(is.na(df$decimalLongitude)) )

### NA % ----
cat("Percentage of LATITUDE values: ", "\n", sum(!is.na(df$decimalLatitude)) / nrow(df) * 100, "%", "\n", "\n",
    "Row number of LATITUDE values:", "\n", sum(!is.na(df$decimalLatitude)), "\n",
    "Total number of rows:", "\n", nrow(df), "\n")
# show the file names with NA values
(file_names <- df %>% filter(is.na(decimalLatitude)) %>% pull(FILE_NAME) %>%  unique() )

cat("Percentage of LONGITUDE values: ", "\n", sum(!is.na(df$decimalLongitude)) / nrow(df) * 100, "%", "\n", "\n",
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

ggplot(na_percentage, aes(x = FILE_NAME, y = na_percentage)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Percentage of NA values in LATITUDE for each FILE_NAME",
       x = "FILE_NAME",
       y = "Percentage of NA values") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

###  as.numeric ----
####  lost after conversion ----
na_before_latitude <- sum(is.na(df$decimalLatitude))
na_before_longitude <- sum(is.na(df$decimalLongitude))

df2 <- df %>%
  mutate(
    decimalLatitude = as.numeric(decimalLatitude),
    decimalLongitude = as.numeric(decimalLongitude)
  )

na_after_latitude <- sum(is.na(df2$decimalLatitude))
na_after_longitude <- sum(is.na(df2$decimalLongitude))

na_converted_latitude <- na_after_latitude - na_before_latitude
na_converted_longitude <- na_after_longitude - na_before_longitude

cat("Number of values transformed into NA for LATITUDE : ", na_converted_latitude, "\n")
cat("Number of values transformed into NA for LONGITUDE : : ", na_converted_longitude, "\n")

df_no_numerique <- df[!grepl("^[0-9.]+$", df$decimalLatitude), ]
table(df_no_numerique$decimalLatitude)
#### conversion ----
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
# Vline show the limits of the study scope

### latitude plot ----
latitude_distribution <- as.data.frame(table(df$decimalLatitude))
colnames(latitude_distribution) <- c("decimalLatitude", "Frequency")

ggplot(latitude_distribution, aes(x = as.numeric(as.character(decimalLatitude)), y = Frequency)) +
  geom_bar(stat = "identity", fill = "lightcoral", color = "lightcoral") +
  geom_vline(xintercept = c(14, 81), color = "red", linetype = "dashed", size = 1) + # Latitude 81 (= Svalbard and Jan Mayen Islands) and -14 (= Cape Verde) are the limits of the scope
  theme_minimal() +
  labs(title = "Latitude distribution", x = "Latitude", y = "Frequency") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

### longitude plot ----
longitude_distribution <- as.data.frame(table(df$decimalLongitude))
colnames(longitude_distribution) <- c("decimalLongitude", "Frequency")

ggplot(longitude_distribution, aes(x = as.numeric(as.character(decimalLongitude)), y = Frequency)) +
  geom_bar(stat = "identity", fill = "#97DEF0", color = "#97DEF0") +
  geom_vline(xintercept = c(-32, 70), color = "blue", linetype = "dashed", size = 1) + # Longitude -32 (= Azores) and 70 (= Arkhangelsk Oblast) are the limits of the scope
  theme_minimal() +
  labs(title = "Longitude distribution", x = "Longitude", y = "Frequency") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))


# Coordinates provided ----
(sum(is.na(df$coordinatesProvided)) )
nrow(df)
cat("Percentage of NA (coordinatesProvided):\n", sum(is.na(df$coordinatesProvided))/ nrow(df)*100, "% \n")

## plot NA % ----
provided_percentage <- df %>%
  group_by(datasetName) %>%
  summarise(na = sum(is.na(coordinatesProvided)),
            nrow = n()) %>%  
  mutate(provided_percentage = (na / nrow) * 100) %>% 
  filter(provided_percentage > 0) %>% 
  arrange(desc(provided_percentage)) %>% 
  mutate(datasetName = factor(datasetName, levels = datasetName))

ggplot(provided_percentage, aes(x = datasetName, y = provided_percentage)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = nrow), vjust = -0.5) +  # Ajouter les annotations de nrow
  theme_minimal() +
  labs(title = "Percentage of NA values in coordinatesProvided for each FILE_NAME",
       x = "FILE_NAME",
       y = "Percentage of NA values") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Date ----
## date type ----
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
min(df$yearEnd, na.rm = TRUE)
max(df$yearEnd, na.rm = TRUE)

# Check extreme values of years
year_check <- df %>%
  filter(yearEnd < 1700 | yearEnd > 2024) %>% # Check extreme values
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd, verbatimEventDate) %>% 
  arrange(desc(yearEnd))

## Month ----
# histogram of the distribution of months
ggplot(df, aes(x = factor(monthEnd))) +
  geom_bar(fill = "#CCFF99", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Months", x = "Month", y = "Frequency") +
  theme_minimal()

# Check the minimum and maximum values
min(df$monthEnd, na.rm = TRUE)
max(df$monthEnd, na.rm = TRUE)
table(df$monthEnd)

# Check extreme values of month
month_check <- df %>%
  filter(monthEnd > 12) %>% 
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd, verbatimEventDate) %>% 
  arrange(desc(yearEnd))

## Day ----
# histogram of the distribution of days
ggplot(df, aes(x = factor(dayEnd))) +
  geom_bar(fill = "#FFFF66", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Days", x = "Day", y = "Frequency") +
  theme_minimal()

# Check the minimum and maximum values
min(df$dayEnd, na.rm = TRUE)
max(df$dayEnd, na.rm = TRUE)
table(df$dayEnd)

# Check extreme values of day
day_check <- df %>%
  filter(dayEnd > 31) %>% 
  select(occurrenceID, FILE_NAME, yearEnd, monthEnd, dayEnd, verbatimEventDate) %>% 
  arrange(desc(yearEnd))

## eventDate ----
### Save the original eventDate in verbatimEventDate ----
# Ensure that original eventDate have been filled in verbatimEventDate
df <- mutate(df, verbatimEventDate = if_else(is.na(verbatimEventDate), eventDate, verbatimEventDate))
# Concatenate date
df <- df %>% mutate(eventDate = paste0(yearEnd, "-", monthEnd, "-", dayEnd))

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
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Export ----
# Check if rows were deleted
nrow(df0) - nrow(df)

# Export with fwrite
fwrite(df, paste0("./data/working_directory/04_quality_check_", Sys.Date(), ".csv"),
       sep = ";", dec = ".", row.names = FALSE)

# Remove objects from memory
rm(list = ls())
gc()
