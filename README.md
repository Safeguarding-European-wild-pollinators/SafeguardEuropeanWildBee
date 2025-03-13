# Project description

This repository contains the scripts used to clean and process data for the data paper of Sentil et al. 2025, "_A Synthesized Database of Wild Bee and Hoverfly Occurrences in Europe_" based on spatial data of **wild bees** from the SAFEGUARD project. These scripts are designed to streamline data cleaning and transformation, making them easily reusable and adaptable for similar projects.

## Project funding
This work has been funded by:

**SAFEGUARD** (Safeguarding European wild pollinators). Horizon 2020 (No. 101003476). Task 1.1:  Compiling distributional data on European pollinators at EU and national levels.

**PULSE** (Providing technical and scientific support in measuring the pulse of European biodiversity using the Red List Index, contract No. 07.027755/2020/840209/SER/ENV.D.2.).

# Script description

This project includes several essential data cleaning steps to prepare spatial data of **wild bees** for analysis, including:


- **Data Import, Preprocessing, and Aggregation**: Importing raw data, cleaning it, and aggregating it for consistency.
- **Scientific Names Validation**: Ensuring that all species names are consistent with those used in Ghisbain et al. (2023).
- **Data Quality Check**: Identifying missing, erroneous, or outlier values in the dataset.
- **Taxonomic Assignment**: Assigning each species to its correct taxonomic rank (order, family, subfamily, tribes and subgenus).
- **Geographical Assignment**: Assigning administrative level (country, state province and county). 
- **Batch Mapping**: Automatically generating maps for each species based on geographic coordinates.

This project does **not** include steps such as:

- **Data Transformation and Normalization**: For scaling or transforming data values.
- **Data Encoding**: Encoding new data.
- **Spatial Data Validation**: Spatial data validation process in collaboration with expert taxonomists and national experts.

# Script requirements

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
2. Install the required packages by running source(`install_packages.R`).
3. Import the dataset(s): a test file is provided `test_data(50_rows).csv` to run the scripts. Otherwise, you can fill the `ToFill.xlsx` or the `ToFill_ToFill.csv` with your own data. Prepare your dataset according to the format described in metadata documentation (`Metadata_field_description` or `ToFill` files).
4. Run the individual scripts in the same order. 
    - `01_data_import.R`
    - `02_quality_check.R`
    - `03_scientificName_validation.R`
    - `04_taxonomy_classification.R`
    - `05_administrative_level.R`
    - `06_batch_map.R`

5. Modify the scripts as needed for your specific dataset or research requirements.

# Data Sources and Attribution

The following external sources were used to ensure the accuracy and reliability of the dataset:

- **Scientific Name Validation**: Species names were verified using:
    > [Ghisbain, Rosa et al. (2023)](https://www.researchgate.net/publication/373048571_The_new_annotated_checklist_of_the_wild_bees_of_Europe_Hymenoptera_Anthophila): The new annotated checklist of the wild bees of Europe (Hymenoptera: Anthophila) (DOI: [10.11646/zootaxa.5327.1.1](https://mapress.com/zt/article/view/zootaxa.5327.1.1).

- **Taxonomic Assignment**: The taxonomic ranks (family, subfamily, tribe, genus, and subgenus) were assigned based on: 
    > [Reverte, Milicic et al. (2023)](https://www.researchgate.net/publication/373865563): National records of 3000 European bee and hoverfly species: A contribution to pollinator conservation (DOI: [10.1111/icad.12680](https://resjournals.onlinelibrary.wiley.com/doi/10.1111/icad.12680).
    Note : scientific names have been updated and standardized to match the European checklist (Ghisbain et al. 2023): _Hylaeus longimacula_ --> _Hylaeus longimaculus_, _Dioxys atlanticus_ --> _Dioxys atlantica_, _Dioxys cinctus_ --> _Dioxys cincta_, _Dioxys moestus_ --> _Dioxys moesta_, _Dioxys pumilus_ --> _Dioxys pumila_. Note2: two species (_Bombus bisiculus_ & _Seladonia pici_) are not present in the European checklist.

-  **Country and state province assignments**: The country and state province assignments were performed using shapefiles based on the World Geographical Scheme for Recording Plant Distributions (WGSRPD):
    > [R. K. Brummitt (2001)](http://data.europa.eu/89h/jrc-10112-10004): World Geographic Scheme for Recording Plant Distributions, Edition 2. Hunt Institute for Botanical Documentation, Carnegie Mellon University (Pittsburgh). http://rs.tdwg.org/wgsrpd/doc/data/ [http://rs.tdwg.org/wgsrpd/doc/data/](http://rs.tdwg.org/wgsrpd/doc/data/).

-  **County assignments**: The county assignments were performed using shapefiles from the European Commission:
    > [Urbano, Ferdinando (2018)](http://data.europa.eu/89h/jrc-10112-10004): Global administrative boundaries. European Commission, Joint Research Centre (JRC) [Dataset] PID: [http://data.europa.eu/89h/jrc-10112-10004](http://data.europa.eu/89h/jrc-10112-10004).


## Script attribution
The scripts are designed to be easily adaptable to similar datasets, and you are welcome to reuse and modify the code as needed, provided proper attribution is given. If you use this code or adapt it for your own work, please provide attribution by citing the repository as follows:

    "Scripts for Safeguard data cleaning provided by Jordan Benrezkallah (GitHub: https://github.com/JordanBZK/)."

# License

This project is licensed under the MIT License.
You are free to use, modify, and distribute the code, as long as you provide appropriate credit to the original author.


# Contact

For any questions or feedback, feel free to contact me at jordan.benrezkallah@umons.ac.be.
