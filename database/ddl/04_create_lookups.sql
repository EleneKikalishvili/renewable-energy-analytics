/* ======================================================================
   File    : 04_create_lookups.sql
   Purpose : Creates look-up tables for investments, eu_consumption, and eu_price_breakdown fact tables, and associated ENUM types.
   Author  : Elene Kikalishvili
   Date    : 2025-05-02
   Depends : 01_create_schema.sql
   ====================================================================== */




-- Creating lookup tables for investments fact table

-- Table 1: finance_lookup
-- Purpose: Stores finance related columns for investments table

CREATE TABLE renewables_project.finance_lookup (
    finance_id SERIAL CONSTRAINT pk_finance_lookup PRIMARY KEY,
    finance_group VARCHAR(25) NOT NULL,
    finance_type VARCHAR(100) NOT NULL,
    CONSTRAINT uq_finance_lookup_group_type UNIQUE (finance_group, finance_type)
);

COMMENT ON TABLE renewables_project.finance_lookup IS
  'Stores the breakdown of finance-related categories and types for each investment record. Separates repetitive finance info into a normalized structure to simplify data management and prevent redundancy.';




-- Table 2: project_lookup
-- Purpose: Stores project-related columns for investments table

CREATE TABLE renewables_project.project_lookup (
    project_id SERIAL CONSTRAINT pk_project_lookup PRIMARY KEY,
    project TEXT, 		-- For some investment records project is not provided
    donor VARCHAR(100) NOT NULL,
    agency VARCHAR(100) NOT NULL,
    CONSTRAINT uq_project_lookup_combination UNIQUE (project, donor, agency)
);

COMMENT ON TABLE renewables_project.project_lookup IS
  'Stores information about renewable energy projects along with their donors and implementing agencies. Identifies unique project/donor/agency combinations.';




-- Table 3: inv_source_lookup
-- Purpose: Stores original source links for investments table

CREATE TABLE renewables_project.inv_source_lookup (
    original_source_id SERIAL CONSTRAINT pk_inv_source_lookup PRIMARY KEY,
    original_url TEXT NOT NULL,
    CONSTRAINT uq_inv_source_lookup_url UNIQUE (original_url)
);

COMMENT ON TABLE renewables_project.inv_source_lookup IS
  'Keeps track of original source URLs or references for investment records, making it easy to trace data.';




-- Creating lookup table for eu_consumption

-- Table 4: indicator_lookup
-- Purpose: Stores full descriptions for abbreviated indicator values

CREATE TABLE renewables_project.indicator_lookup (
    indicator renewables_project.consumption CONSTRAINT pk_indicator_lookup PRIMARY KEY,  -- abbreviated names are the keys
    full_name VARCHAR(100) NOT NULL,
    description TEXT,
    CONSTRAINT uq_indicator_lookup_full_name UNIQUE (full_name)
);

COMMENT ON TABLE renewables_project.indicator_lookup IS
  'Provides full names and descriptions for the abbreviated indicators used in the eu_consumption fact table, clarifying the meaning of key metrics.';




-- Creating lookup table for eu_price_breakdown

-- Table 5: price_component_lookup
-- Purpose: Stores full description for abbreviated price components

CREATE TABLE renewables_project.price_component_lookup (
    price_component VARCHAR(30) CONSTRAINT pk_price_component_lookup PRIMARY KEY,  -- abbreviated names are the keys
    full_name VARCHAR(255) NOT NULL,
    description TEXT,
    CONSTRAINT uq_price_component_lookup_full_name UNIQUE (full_name)
);

COMMENT ON TABLE renewables_project.price_component_lookup IS
  'Breaks down electricity price components, mapping abbreviated component codes to full descriptions, used in eu_price_breakdown.';




