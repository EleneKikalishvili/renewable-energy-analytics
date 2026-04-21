/* ======================================================================
   File    : 08_copy_to_staging_tables.sql
   Purpose : To bulk load cleaned and pre-structured datasets into temporary staging tables, 
             allowing controlled population of dimension, lookup, and fact tables in later steps.
   Author  : Elene Kikalishvili
   Date    : 2026-02-23
   Depends : 01_create_schema.sql
   ====================================================================== */
 
/* ======================================================================
   Notes: 
   	
 - This build script is designed for psql (PostgreSQL command-line).

 - If you are using DBeaver or pgAdmin, see the README 'How to Reproduce / Run This Project' section for manual steps.

 - All source CSVs were cleaned and standardized in Power Query, with:
   
		- Trimmed headers and whitespace
			
		- Consistent column naming
			
		- Long-format restructuring where needed
			
		- Standard unit conversions (e.g., TJ → EJ)
			
		- Removal of known duplicates
			
		- Blank cells converted to null
		
   ====================================================================== */




-- Setting a path to the file directory
\set data_dir 'D:/Data Analytics/Renewable Energies Project Data Sources/Final Processed Data (Ready for SQL Import)/'




-- Copying data into primary_energy_consumption_staging table

\set file 'ei_primary_energy_consumption.csv'
\set fullpath :data_dir:file \echo :fullpath
 
COPY renewables_project.primary_consumption_staging
(source, region, country, year, metric_type, value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.primary_consumption_staging
LIMIT 5;

-- Expected row count: 2,304 rows
SELECT COUNT(*)
FROM renewables_project.primary_consumption_staging; */




-- Copying data into ren_primary_consumption_staging table

\set file 'ei_renewables_consumption.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.ren_primary_consumption_staging
(source, technology, region, country, year, metric_type, value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.ren_primary_consumption_staging
LIMIT 5;

-- Expected row count: 12,336 rows
SELECT COUNT(*)
FROM renewables_project.ren_primary_consumption_staging; */




-- Copying data into capacity_generation_staging table

\set file 'irena_renewable_capacity_generation.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.capacity_generation_staging
(source, region, sub_region, country, iso3_code, m49_code, 
renewable_status, group_technology, technology, sub_technology, producer_type, year, 
electricity_generation_gwh, electricity_generation_twh, electricity_installed_capacity_mw)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.capacity_generation_staging
LIMIT 5;

-- Expected row count: 40,208 rows
SELECT COUNT(*)
FROM renewables_project.capacity_generation_staging; */




-- Copying data into ren_share_staging table

\set file 'irena_renewables_share.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.ren_share_staging
(source, geo_type, geo, metric_type, year, value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.ren_share_staging
LIMIT 5;

-- Expected row count: 11,650 rows
SELECT COUNT(*)
FROM renewables_project.ren_share_staging; */




-- Copying data into fossil_cost_range_staging table

\set file 'irena_fossil_cost_range.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.fossil_cost_range_staging
(source, group_technology, cost_band, value, unit, reference_year)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
-- Testing
SELECT *
FROM renewables_project.fossil_cost_range_staging;

-- Expected row count: 2 rows
SELECT COUNT(*)
FROM renewables_project.fossil_cost_range_staging; */




-- Copying data into investments_staging table

\set file 'irena_public_energy_investments.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.investments_staging
(dataset_source, iso3, country_or_area, region, project, donor, agency, year, category, technology, sub_technology, finance_group, finance_type, source, reference_date, amount_usd_million)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.investments_staging
LIMIT 5;

-- Expected row count: 16,457 rows
SELECT COUNT(*)
FROM renewables_project.investments_staging; */




-- Copying data into energy_emissions_staging table

\set file 'ei_energy_co2_emissions.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.energy_emissions_staging
(source, region, country, year, metric_type, value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.energy_emissions_staging
LIMIT 5;

-- Expected row count: 5,664 rows
SELECT COUNT(*)
FROM renewables_project.energy_emissions_staging; */




-- Copying data into ren_indicators_global_staging table

\set file 'irena_renewable_costs_global.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.ren_indicators_global_staging
(source, group_technology, technology, metric_type, year, value_category, value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.ren_indicators_global_staging
LIMIT 5;

-- Expected row count: 882 rows
SELECT COUNT(*)
FROM renewables_project.ren_indicators_global_staging; */




-- Copying data into ren_indicators_country_staging table

\set file 'irena_renewable_costs_country.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.ren_indicators_country_staging
(source, group_technology, technology, project_type, region, country, period, year, metric_type, value_category, country_value, regional_value)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.ren_indicators_country_staging
LIMIT 5;

-- Expected row count: 2,767 rows
SELECT COUNT(*)
FROM renewables_project.ren_indicators_country_staging; */




-- Copying data into eu_consumption_staging table

\set file 'eurostat_energy_balances.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.eu_consumption_staging
(source, iso2, year, metric_type, value_tj, value_ej)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.eu_consumption_staging
LIMIT 5;

-- Expected row count: 2,584 rows
SELECT COUNT(*)
FROM renewables_project.eu_consumption_staging; */




-- Copying data into eu_elec_prices_staging table

\set file 'eurostat_electricity_prices.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.eu_elec_prices_staging
(source, consumer_type, consumption_band, tax, iso2, period, metric_type, value, is_flagged)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.eu_elec_prices_staging
LIMIT 5;

-- Expected row count: 32,340 rows
SELECT COUNT(*)
FROM renewables_project.eu_elec_prices_staging; */




-- Copying data into eu_price_breakdown_staging table

\set file 'eurostat_electricity_price_components.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.eu_price_breakdown_staging
(source, consumer_type, consumption_band, price_component, iso2, year, metric_type, value, is_flagged)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.eu_price_breakdown_staging
LIMIT 5;

-- Expected row count: 48,097 rows
SELECT COUNT(*)
FROM renewables_project.eu_price_breakdown_staging; */




-- Copying data into geo_staging table

\set file 'datahub_country_codes_mapping.csv'
\set fullpath :data_dir:file \echo :fullpath

COPY renewables_project.geo_staging
(iso3, iso2, m49_code, sub_region_code, region_code, country_name, region_name, sub_region_name, capital, continent_code, geoname_id)
FROM :'fullpath'
DELIMITER ','
CSV HEADER;

/* For QA:
--Testing
SELECT *
FROM renewables_project.geo_staging
LIMIT 5;

-- Expected row count: 249 rows
SELECT COUNT(*)
FROM renewables_project.geo_staging; */





