/* ======================================================================
   File    : 03_create_dim_tables.sql
   Purpose : Creates all dimension tables for the Renewable Energy star schema.
   Author  : Elene Kikalishvili
   Date    : 2025-05-02
   Depends : 01_create_schema.sql
   ====================================================================== */




-- Table 1: dim_technology
-- Purpose: Stores standardized technology names 

CREATE TABLE renewables_project.dim_technology (
    tech_id SERIAL CONSTRAINT pk_dim_technology PRIMARY KEY,
    category renewables_project.energy_category NOT NULL,
    group_technology VARCHAR(50) NOT NULL,
    technology VARCHAR(50) NOT NULL,
    sub_technology VARCHAR(50) NOT NULL,
    CONSTRAINT uq_dim_technology_tech_subtech UNIQUE (technology, sub_technology)
);

COMMENT ON TABLE renewables_project.dim_technology IS
  'Stores standardized renewable and non-renewable technology categories and subcategories to enable consistent reference across all fact tables.';




--Table 2: dim_geo
--Purpose: Stores standardized geographic locations

CREATE TABLE renewables_project.dim_geo (
    geo_id SERIAL CONSTRAINT pk_dim_geo PRIMARY KEY,
    geo_name VARCHAR(60) NOT NULL,  -- stores standard and non-standard country/region names
    geo_type renewables_project.geo NOT NULL,
    is_standard BOOLEAN NOT NULL DEFAULT FALSE,
    iso3 CHAR(3),
    iso2 CHAR(2),
    m49_code VARCHAR(3),
    country_name VARCHAR(60),
    region_name VARCHAR(10),
    sub_region_name VARCHAR(50),
    continent_code CHAR(2),
    capital VARCHAR(50),
    CONSTRAINT uq_dim_geo_geo_name UNIQUE (geo_name),
    CONSTRAINT uq_dim_geo_iso3 UNIQUE (iso3),
    CONSTRAINT uq_dim_geo_iso2 UNIQUE (iso2),
    CONSTRAINT uq_dim_geo_m49_code UNIQUE (m49_code),
    CONSTRAINT uq_dim_geo_country_name UNIQUE (country_name)
);

COMMENT ON TABLE renewables_project.dim_geo IS
  'Stores standardized geographic entities including countries, regions, global groups, economic groups, multilateral groupings, and residual/unallocated categories to allow consistent geo-referencing.';

COMMENT ON COLUMN renewables_project.dim_geo.geo_name IS 
	'Stores standard and non-standard country/area/region/economic group names (Europian Union, Other Asia, Tai Wan, etc.).';




--Table 3: dim_source
--Purpose: Stores detailed source data for all tables

CREATE TABLE renewables_project.dim_source (
    source_id SERIAL CONSTRAINT pk_dim_source PRIMARY KEY,
    source_name VARCHAR(50) NOT NULL,
    source_type VARCHAR(50),
    dataset_url TEXT NOT NULL,
    notes TEXT,
    CONSTRAINT uq_dim_source_name_dataset UNIQUE (source_name, dataset_url)
);

COMMENT ON TABLE renewables_project.dim_source IS
  'Stores metadata about data sources, ensuring traceability of all fact table records.'
