# Data Preparation

This section summarizes how raw datasets were cleaned, transformed, and standardized before loading into the PostgreSQL database.  
All transformations were performed in **Microsoft Excel Power Query**, focusing on consistent column naming, data type alignment, and long-format structuring for SQL import.  

Final cleaned outputs were exported as UTF-8 CSV files and stored in [clean_data](/data/clean_data/) folder for SQL import.

---

## Overview of the Cleaning Workflow

| Step | Description |
|------|--------------|
| **1. Data Selection** | Multi-sheet Excel files were inspected manually and only relevant data were kept. |
| **2. Data ingestion** | Imported Excel or TSV files into Power Query. |
| **3. Structural cleanup** | Removed empty rows/columns; addressed inconsistent or missing values; unified units and formats; removed pre-aggregated totals; removed duplicates. |
| **4. Transformation to long format** | Unpivoted year columns to `year` / `value` structure for SQL compatibility. |
| **5. Data standardization** | Renamed columns to snake_case; standardized text casing; applied Trim & Clean; fixed Unicode and encoding issues; converted data types. |
| **6. Integration consistency** | Added common fields (`source`, `metric_type`, `technology`, etc.). |
| **7. Export** | Saved final outputs as UTF-8 CSV files in `/data/clean_data/`. |

---

## Key Standardization Rules

| Element | Convention |
|----------|-------------|
| **Column naming** | lowercase snake_case |
| **Null values** | Represented as SQL `NULL` |
| **Text cleanup** | Applied Trim & Clean; removed non-printable chars and diacritics |
| **Aggregated totals** | Excluded pre-aggregated regional totals, as they become invalid after reclassifying countries into standardized regions inside a SQL database |
| **Numeric precision** | Preserved original numeric precision for SQL analysis |
| **Units** | Converted GWh→TWh, TJ→EJ for consistency |  
| **Encoding** | UTF-8 CSV for SQL import | 

---

## Dataset-Specific Preparation Summaries

### 1. Energy Institute – Statistical Review of World Energy (2024)
- Prepared **3 datasets**: primary consumption, renewables consumption, and CO₂ emissions.  
- Unpivoted wide year columns → `year` / `value`.  
- Added `metric_type`, `country_value`, and `source`.  
- Converted PJ → EJ for renewables; replaced zeros and “:” with NULL.
- Appended technology tables into unified long-format dataset - `ei_primary_energy_consumption_renewables.csv`.
- Checked for and removed duplicate rows.
- Exported CSVs ready for SQL import:  
  - `ei_primary_energy_consumption.csv`  
  - `ei_primary_energy_consumption_renewables.csv`  
  - `ei_energy_co2_emissions.csv`  

---

### 2. IRENA – Renewable Energy Statistics and Costs
- Prepared **6 datasets**: capacity & generation, cost datasets (global and country), fossil fuel cost range, investments, and renewables share.  
- Removed irrelevant sheets.
- Standardized headers
- Converted units GWh → TWh and kept both.
- Removed rows with unnecessary data.
- Replaced blanks and dashes with NULLs.
- Handled different time representations by adding `period` column - some had annual data and some used periods.
- Unpivoted all year columns.
- To ensure psql database compatibility diacritics were removed in project names inside investments dataset.
- Harmonized field names: `technology`, `metric_type`, `value_category`, `group_technology`.  
- Added `geo_type` classification for global/region/country in renewables share dataset.
- Appended related technology tables resulting in global and country level costs datasets.
- Checked for and removed duplicate rows.
- Exported CSVs ready for SQL import:
  - `irena_renewable_costs_country.csv`  
  - `irena_renewable_costs_global.csv`  
  - `irena_fossil_cost_range.csv`
  - `irena_public_energy_investments.csv`
  - `irena_renewable_capacity_generation.csv`
  - `irena_renewables_share.csv`

---

### 3. Eurostat – European Energy Data
- Prepared **3 datasets**: electricity prices, price components, and energy balances.
- Removed non-informative metadata.
- Filtered records:
  - Kept records with EUR currency.
  - Retained household prices data with "I_TAX"(including all taxes and levies) records only.
  - Non-household data was filtered for "I_TAX" and "X_VAT"(actual costs after VAT recovery).
- unpivoted semi-annual and year columns → `period` / `value` or `year` / `value`.
- Replaced missing values (:) with NULLs.
- Renamed columns for readability (e.g. nrg_cons -> consumption_band).
- Stripped annotation characters from values that represented estimation or warning (e.g. p = provisional)
- Added `is_flagged` column to retain these warning/estimation letters
- Added `source`, `consumer_type`, `metric_type` columns.  
- converted TJ → EJ and kept both.
- Converted data types.
- Ensured consistency in numeric precision and column order.
- Appended related household and non-household datasets.
- Exported CSVs ready for SQL import:  
  - `eurostat_electricity_prices.csv`  
  - `eurostat_electricity_price_components.csv`  
  - `eurostat_energy_balances.csv`

---

### 4. DataHub – Country Codes Mapping
- Renamed columns (E.g. ISO366-1-Alpha-3 -> iso3).
- Standardized all column names using snake_case and lowercase.  
- Retained only essential fields (`iso2`, `iso3`, `country_name`, `region_name`, `sub_region_name`, etc.).  
- Final file: `datahub_country_codes_mapping.csv`  

---

## Example Resources  

Illustrative examples of specific cleaning and transformation steps — including **Power Query M code** snippets and **before-and-after visualizations** — are available in  
[`/docs/power_query_examples.md`](./power_query_examples.md).  

*Detailed Power Query scripts and dataset-specific screenshots are archived locally and can be shared upon request.*
