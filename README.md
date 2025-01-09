# Data Cleaning Scripts for SAFEGUARD project data

This repository contains the scripts we used to clean and process the data for the data paper titled _A synthesized dataset of wild bees and hoverflies occurrences in Europe_ on spatial data of **wild bees** from the SAFEGUARD project. These scripts are intended to facilitate data cleaning and transformation for reuse and adaptation in similar projects.

# Description

This project includes several essential data cleaning steps to prepare spatial data of **wild bees** for analysis, including:


- **Data Import, Preprocessing, and Aggregation**: Importing raw data, cleaning it, and aggregating it for consistency.
- **Scientific Names Validation**: Ensuring that all species names are consistent with those used in Ghisbain et al. (2023).
- **Data Quality Check**: Identifying missing, erroneous, or outlier values in the dataset.
- **Taxonomic Assignment**: Assigning each species to its correct taxonomic rank (family, genus, etc.).
- **Batch Mapping**: Automatically generating maps for each species based on geographic coordinates.

This project does **not** include steps such as:

- **Data Transformation and Normalization**: For scaling or transforming data values.
- **Data Encoding**: Encoding new data.
- **Spatial Data Validation**: Spatial data validation process in collaboration with expert taxonomists and national experts.


The scripts are designed to be easily adaptable to similar datasets, and you are welcome to reuse and modify the code as needed, provided proper attribution is given.

# Requirements

To run the scripts, you'll need:

- R
- All the required packages listed in the `library.R` file

You can install the required packages by running the following command in your R console:

```R
source('install_packages.R')
```

# Usage
To use the scripts, simply follow these steps:

    1. Clone or download the repository to your local machine.
    2. Install the required packages by running source('library.R').
    3. Prepare your dataset according to the format described in the project's documentation (e.g., .csv or .tsv files).
    4. Run the individual scripts in the desired order. For example:
        - script_data_import.R to import your raw data.
        - script_taxonomic_assignment.R for assigning taxonomic ranks.
    5. Modify the scripts as needed for your specific dataset or research requirements.

# License

This project is licensed under the MIT License.
You are free to use, modify, and distribute the code, as long as you provide appropriate credit to the original author.

# Attribution

If you use this code or adapt it for your own work, please provide attribution by citing the repository as follows:

    "Scripts for Safeguard data cleaning provided by Jordan Benrezkallah (GitHub: https://github.com/Jack177)."

# Contact

For any questions or feedback, feel free to contact me at jordan.benrezkallah@umons.ac.be.
