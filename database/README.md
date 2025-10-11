# Database: Renewable Energy Analytics

This folder contains all SQL scripts and schema definitions used to build and populate the **PostgreSQL** database for the Renewable Energy Analytics project.

---

## Purpose
The database serves as the analytical foundation of the project.  
It integrates multiple cleaned datasets from **IRENA**, **Eurostat**, and the **Energy Institute**, harmonized through a shared geographic and technology schema.  
It supports SQL-based analysis, data validation, and Tableau visualization.

---

## Folder Structure
| Folder | Description |
|---------|--------------|
| **ddl/** | Data Definition Language scripts - create schema, enums, dimension, lookup, and fact tables. |
| **dml/** | Data Manipulation Language scripts - load, clean, and insert data into the final schema. |
| **views/** | Tableau-ready and analysis views (created after fact and dimension tables are populated). |
| **00_run_all.sql** | Master build script that rebuilds the entire database in one run (schema -> data -> views). |

---

## Schema Overview
- **Schema name:** `renewables_project`
- **Database:** PostgreSQL
- **Design:** Star schema with light normalization  
  - Core dimensions: `dim_geo`, `dim_technology`, `dim_source`.
  - Fact tables: `investments`, `capacity_generation`, `primary_consumption`, `ren_primary_consumption`, etc.
  - Lookup tables: `project_lookup`, `finance lookup`, `inv_source_lookup`, `indicator_lookup`, `price_component_lookup`.
- **Relationship logic:** All tables connect through standardized country/region codes and technology keys.

---  

## Entity-Relationship Diagram (ERD)
![ERD Diagram](../docs/images/renewables_project_ERD.png)

*The ERD illustrates table relationships, primary/foreign keys, and core data flow.*  

*For detailed column-level definitions and metadata, see the [Data Dictionary](./data_dictionary.md).*
---

## Schema Design and Table Roles

The database follows a **lightly normalized star schema**, combining multiple renewable energy datasets into a unified analytical model.  

**Dimension Tables** - provide standardized references and contextual metadata:  
- **`dim_geo`** - Contains standardized geographic identifiers (countries, regions, economic groups, residuals).  
  Enables joining data across sources with inconsistent location naming conventions.  
- **`dim_technology`** - Lists renewable and non-renewable technologies, grouped by type (e.g., solar, wind, hydro).  
  Used to relate cost, capacity, and generation datasets consistently.  
- **`dim_source`** - Tracks the origin of each dataset (IRENA, Energy Institute, Eurostat, etc.) for transparency and traceability.

**Lookup Tables** - store supplementary metadata used for reference:  
- Hold additional descriptive fields not required in the main analytical queries (e.g., indicator codes, units, and definitions).  
  Examples include lookups for energy balance indicators or price components.

**Fact Tables** - hold the core analytical data:  
- Contain time-series measurements such as installed capacity, generation, emissions, investments, costs, and consumption.  
- All fact tables link to `dim_geo`, `dim_technology`, and `dim_source` via foreign keys, allowing cross-dataset comparisons and aggregation.

---

### Core Standardization Dimensions

#### Geographic Standardization (`dim_geo`)

The **`dim_geo`** table was created to unify and standardize all geographic identifiers across datasets from IRENA, Eurostat, and the Energy Institute.  
It was initially populated using the **DataHub Country Codes Mapping** dataset, which provided ISO country codes and UN region/subregion classifications.  
From there, additional custom logic was applied to support non-standard geographic groupings and improve compatibility across all sources.

**Key Table Design:**
- **`geo_name`** - Stores the geographic entity name and is used to mapp non-standard records with standard country names stored in country_name column. Initially populated using ISO-standard country names, but later added non-standard country names ("Czech Republic") and non-standard records such as regional aggregates (e.g., *"Other North Africa"*) or economic groups (e.g., *"European Union"*).  
- **`geo_type`** - Categorizes each record as *Country*, *Region*, *Global*, *Economic group*, *Residual/unallocated*, *Unspecified*, etc. This enables flexible filtering during analysis.  
- **`is_standard`** - Boolean flag identifying whether the record is an ISO/UN standard location (`TRUE`) or a non-standard, derived record (`FALSE`).  

**Standardization Process:**
- The table was seeded with ISO country codes and UN region/subregion mappings from DataHub.  
- Country names were harmonized to standard naming conventions (e.g., *"Czech Republic" -> "Czechia"*).  
- Regional aggregates (e.g., *"Other S. & Cent. America"*) and economic groups (*OECD*, *EU*) were added as distinct geographic entities because they do not map directly to individual countries.  
- Country records originally assigned to the *CIS*, *"Asia Pacific"* and *"Middle East"* regions were reclassified under their corresponding UN standard regions/subregions.  
  Remaining aggregate records under *CIS*, *"Asia Pacific"* and *"Middle East"* (e.g., *"Other CIS"*, *"Other Asia Pacific"* ) were categorized as `Residual/unallocated`.  
- Datasets that only contained region-level data (e.g., *"Western Africa"*, *"Eastern Africa"*) were incorporated as `Region`-type records.  
  Partial aggregates such as *"Other Europe"* or *"Other Southern Africa"* were also treated as distinct `Region` entries.    
- Investment data contained special regional labels such as *"Multilateral"*, *"Unspecified"*, and *"Residual/unallocated"*, all of which were categorized consistently under matching `geo_type` values.


#### Technology Standardization (`dim_technology`)

The **`dim_technology`** table was created to harmonize and standardize technology classifications across heterogeneous datasets from IRENA and the Energy Institute.  
It unifies different naming conventions and levels of granularity, allowing consistent joins between datasets.

**Key Table Design:**
- **`category`** - High-level classification: *Renewable* or *Non-renewable*.  
- **`group_technology`** - Broader family grouping (e.g., *Solar energy*, *Wind energy*, *Hydropower*, *Fossil fuels*).  
- **`technology`** - Canonical technology label (e.g., *Solar photovoltaic*, *Onshore wind energy*, *Oil*).  
- **`sub_technology`** - More detailed subtype or aggregate label (e.g., *Off-grid Solar photovoltaic*, *Agg. bioenergy*).

**Standardization Process:**
- The table was built from consolidated records across **capacity_generation**, **investments**, **renewable consumption**, and **renewable indicators** staging tables.  
- First `dim_technology` table was populated by unioned technology data from `investments` and `capacity_generation` staging tables (These tables have the most detailed technology data). 
  Then inserted remaining unique values from `ren_primary_consumption_staging`, `ren_indicators_global_staging`, and `ren_indicators_country_staging` tables.
- Categories were normalized (e.g., *"Renewables"* -> *"Renewable"*, *"Total renewable"* -> *"Renewable"*).  
- Energy technologies were grouped under consistent families. 
- Hydropower and fossil variants were standardized to common groups (*Hydropower*, *Fossil fuels*).  
- Sub-technologies were retained where available - e.g., *Offshore wind*, *Biogases from thermal processes*, *Renewable industrial waste*, etc.
- *Solar photovoltaic* and *Solar thermal* were clearly separated; *Concentrated Solar Power (CSP)* and *Solar thermal energy* were also separated and stored as a `sub_technology` under *Solar thermal energy*.  
- Aggregated technologies were introduced to support datasets reporting totals without subtype breakdowns.  
  e.g., *"Solar PV"* data that had no subtype like Off-grid or On-grid detail was stored as *"Agg. solar photovoltaic"* under `sub_technology` column.
- To ensure 1-to-1 joins onto dim_technology, staging tables were conformed: 
  - normalized labels such as CSP -> Concentrated solar power; Solar PV -> Agg. solar photovoltaic; Onshore Wind -> Onshore wind energy; etc.
  - normalized families to aggregates (Solar -> Agg. solar energy, Wind -> Agg. wind energy, Biofuels -> Agg. biofuels, Hydropower -> Agg. hydropower).

---

## How to Rebuild the Database

### 1. Requirements
- PostgreSQL 13 or higher  
- psql command-line tool  
- Cleaned CSVs located in [clean_data](/data/clean_data/) folder.

### 2. Run the Build Script

**Note:** Before running this command, navigate to the `/database` folder in your local repository.

```bash
cd database
psql -U <your_user> -d <your_database> -f 00_run_all.sql
```