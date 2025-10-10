/* ======================================================================
   File    : 07_create_staging_tables.sql
   Purpose : creates staging tables inside the renewables_project schema to 
   			 temporarily store pre-cleaned CSV data before inserting into the final dimension, 
   			 lookup, and fact tables.
   Author  : Elene Kikalishvili
   Date    : 2025-05-07
   Depends : 01_create_schema.sql
   ====================================================================== */


/* ======================================================================
   Notes:
		 - CSV files are already prepared
		 
		 - Tables are temporary holding areas and should be dropped once the data is migrated.
		 
		 - Keep these tables lightweight: no constraints, no indexes, no foreign keys.
		 
		 - Tables are organized to mirror the source files 1:1.
   ====================================================================== */




-- Primary energy consumption

CREATE TABLE renewables_project.primary_consumption_staging (
	source char(16),
	region VARCHAR(25),
	country VARCHAR(30),
	year INTEGER,
	metric_type CHAR(31),
	value NUMERIC
);


-- Renewables energy consumption

CREATE TABLE renewables_project.ren_primary_consumption_staging (
	source char(16),
	technology VARCHAR(30),
	region VARCHAR(25),
	country VARCHAR(30),
	year INTEGER,
	metric_type CHAR(31),
	value NUMERIC
);


-- Renewables capacity and generation

CREATE TABLE renewables_project.capacity_generation_staging (
	source char(5),
	region VARCHAR(10),
	sub_region VARCHAR (50),
	country VARCHAR(60),
	iso3_code CHAR(3),
	m49_code VARCHAR(3),
	renewable_status VARCHAR(20),
	group_technology VARCHAR(50),
	technology VARCHAR(50),
	sub_technology VARCHAR(50),
	producer_type VARCHAR(25),
	year INTEGER,
	electricity_generation_gwh NUMERIC,
	electricity_generation_twh NUMERIC,
	electricity_installed_capacity_mw NUMERIC
);


-- Renewables share

CREATE TABLE renewables_project.ren_share_staging (
	source CHAR(5),
	geo_type VARCHAR(10),
	geo VARCHAR(60),
	metric_type VARCHAR(20),
	year INTEGER,
	value NUMERIC
);


-- Fossil fuel cost range

CREATE TABLE renewables_project.fossil_cost_range_staging (
	source CHAR(5),
	group_technology CHAR(11),
	cost_band VARCHAR(10),
	value NUMERIC,
	unit CHAR(7),
	reference_year INTEGER
);


-- Public investments

CREATE TABLE renewables_project.investments_staging (
	dataset_source CHAR(5), -- source I got data FROM. 
    iso3 CHAR(3),
    country_or_area VARCHAR(100),
    region VARCHAR(100),
    project TEXT,
    donor VARCHAR(100),
    agency VARCHAR(100),
    year INTEGER,
    category VARCHAR(50),
    technology VARCHAR(50),
    sub_technology VARCHAR(50),
    finance_group VARCHAR(25),
    finance_type VARCHAR(100),
    source TEXT, -- Original source URL links
    reference_date DATE,
    amount_usd_million NUMERIC
);


-- Energy CO2 emissions

CREATE TABLE renewables_project.energy_emissions_staging (
	source char(16),
	region VARCHAR(25),
	country VARCHAR(30),
	year INTEGER,
	metric_type VARCHAR(40),
	value NUMERIC
);


-- Renewable indicators global

CREATE TABLE renewables_project.ren_indicators_global_staging (
	source CHAR(5),
	group_technology VARCHAR(15),
	technology VARCHAR(30),
	metric_type VARCHAR(30),
	year INTEGER,
	value_category VARCHAR(20),
	value NUMERIC
);


-- Renewable indicators country

CREATE TABLE renewables_project.ren_indicators_country_staging (
	source CHAR(5),
	group_technology VARCHAR(15),
	technology VARCHAR(30),
	project_type VARCHAR(15),
	region VARCHAR(50),
	country VARCHAR(25),
	period CHAR(9),
	year INTEGER,
	metric_type VARCHAR(30),
	value_category VARCHAR(20),
	country_value NUMERIC,
	regional_value NUMERIC
);


-- Energy consumption in EU countries

CREATE TABLE renewables_project.eu_consumption_staging (
	source CHAR(8),
	iso2 VARCHAR(15), -- This column contains not standard iso code 'EU27-2020'
	year INTEGER,
	metric_type CHAR(7),
	value_tj NUMERIC,
	value_ej NUMERIC
);



-- Electricity prices in EU countries

CREATE TABLE renewables_project.eu_elec_prices_staging (
	source CHAR(8),
	consumer_type VARCHAR(15),
	consumption_band VARCHAR(20),
	tax CHAR(5),
	iso2 VARCHAR(15), -- This column contains not standard iso code 'EU27-2020'
	period CHAR(7),
	metric_type CHAR(31),
	value NUMERIC,
	is_flagged CHAR(1)
);


-- Electricity price components in EU countries

CREATE TABLE renewables_project.eu_price_breakdown_staging (
	source CHAR(8),
	consumer_type VARCHAR(15),
	consumption_band VARCHAR(20),
	price_component VARCHAR(30),
	iso2 VARCHAR(15), -- This column contains not standard iso code 'EU27-2020'
	year INTEGER,
	metric_type CHAR(31),
	value NUMERIC,
	is_flagged CHAR(1)
);


-- Country codes
-- This table will help to populate dim_geo

CREATE TABLE renewables_project.geo_staging (
	iso3 CHAR(3),
	iso2 CHAR(2),
	m49_code VARCHAR(3),
	sub_region_code VARCHAR(3),
	region_code VARCHAR(3),
	country_name VARCHAR(60),
	region_name VARCHAR(10),
	sub_region_name VARCHAR(50),
	capital VARCHAR(30),
	continent_code CHAR(2),
	geoname_id INTEGER
);




















