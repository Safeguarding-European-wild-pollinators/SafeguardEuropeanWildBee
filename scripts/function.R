# Function ----

## check integer ----
check_integers <- function(df, column) {
  column_name <- enquo(column)  # Capture the column name as a symbol
  
  # Get the column type
  column_type <- class(df[[quo_name(column_name)]])[1]
  
  # Check if the column type is integer
  if (column_type == "integer") {
    result_message <- paste("Data type: ", class(df[[quo_name(column_name)]])[1], ".", " The column '", quo_name(column_name), "' contains valid integers.", sep = "")
  } else {
    result_message <- paste("Data type: ", class(df[[quo_name(column_name)]])[1], "!!!", " The column '", quo_name(column_name), "' contains non-integer values. This could be due to the absence of data in the entire column.", sep = "")
  }
  
  return(result_message)
}

# check max value ----
# Check min and max values in specified columns
check_value_range <- function(df, columns, min_threshold, max_threshold) {
  for (col in columns) {
    # Check if the column is of numeric or integer type
    if (is.numeric(df[[col]]) || is.integer(df[[col]])) {
      # Get min and max values ignoring NA
      min_value <- min(df[[col]], na.rm = TRUE)
      max_value <- max(df[[col]], na.rm = TRUE)
      
      # Check the thresholds
      if (max_value > max_threshold) {
        print(paste("WARNING: The column '", col, "' has a max value greater than ", max_threshold, ". Max value: ", max_value, sep = ""))
      } else {
        print(paste("The column '", col, "' has a max value of ", max_value, " which is acceptable.", sep = ""))
      }
      
      if (min_value < min_threshold) {
        print(paste("WARNING: The column '", col, "' has a min value less than ", min_threshold, ". Min value: ", min_value, sep = ""))
      } else {
        print(paste("The column '", col, "' has a min value of ", min_value, " which is acceptable.", sep = ""))
      }
    } else {
      print(paste("ERROR: The column '", col, "' is not of integer or numeric type.", sep = ""))
    }
  }
}
