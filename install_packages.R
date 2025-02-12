# Define the list of required packages
required_packages <- c(
  "data.table",
  "summarytools",
  "visdat",
  "ggplot2",
  "dplyr",
  "purrr",
  "parallel",
  "lubridate",
  "writexl",
  "readxl",
  "RColorBrewer",
  "scales",
  "red",
  "visdat",
  "naniar",
  "summarytools",
  "sf",
  "rnaturalearth",
  "rnaturalearthdata"
)

# Function to check if a package is installed, and install it if necessary
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Installing package:", pkg))
    install.packages(pkg, dependencies = TRUE)
  } else {
    message(paste("Package already installed:", pkg))
  }
}

# Install all required packages
invisible(lapply(required_packages, install_if_missing))

# Message to confirm installation is complete
message("All required packages are installed!")
