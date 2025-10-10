/* ======================================================================
   File    : drop_staging_tables.sql
   Purpose : Drops all temporary staging tables after data load is complete,
             for a clean production database.
   Author  : Elene Kikalishvili
   Date    : 2025-05-09
   Depends : 01_create_schema.sql
   ====================================================================== */




-- Drop staging tables

DROP TABLE IF EXISTS renewables_project.primary_consumption_staging;

DROP TABLE IF EXISTS renewables_project.ren_primary_consumption_staging;

DROP TABLE IF EXISTS renewables_project.capacity_generation_staging;

DROP TABLE IF EXISTS renewables_project.ren_share_staging;

DROP TABLE IF EXISTS renewables_project.fossil_cost_range_staging;

DROP TABLE IF EXISTS renewables_project.investments_staging;

DROP TABLE IF EXISTS renewables_project.energy_emissions_staging;

DROP TABLE IF EXISTS renewables_project.ren_indicators_global_staging;

DROP TABLE IF EXISTS renewables_project.ren_indicators_country_staging;

DROP TABLE IF EXISTS renewables_project.eu_consumption_staging;

DROP TABLE IF EXISTS renewables_project.eu_elec_prices_staging;

DROP TABLE IF EXISTS renewables_project.eu_price_breakdown_staging;

DROP TABLE IF EXISTS renewables_project.geo_staging;
