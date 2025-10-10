/* ======================================================================
   File    : 02_create_enums.sql
   Purpose : Creates all ENUM types for dimension, look-up, and fact tables.
   Author  : Elene Kikalishvili
   Date    : 2025-05-02
   Depends : 01_create_schema.sql
   ====================================================================== */

-- Used in: dim_technology
CREATE TYPE renewables_project.energy_category AS ENUM ('Renewable', 'Non-renewable');


-- Used in: dim_geo
CREATE TYPE renewables_project.geo AS ENUM ('Country', 'Region', 'Global', 'Economic_group', 'Multilateral', 'Residual/unallocated', 'Unspecified');


-- Used in: indicator_lookup, eu_consumption
CREATE TYPE renewables_project.consumption AS ENUM ('FEC_EED', 'PEC_EED');


-- Used in: primary_consumption, ren_primary_consumption, ren_indicators_country, eu_consumption
CREATE TYPE renewables_project.energy_unit AS ENUM ('Exajoules');


-- Used in: capacity_generation
CREATE TYPE renewables_project.grid_type AS ENUM ('On-grid electricity', 'Off-grid electricity');


-- Used in: ren_share, ren_indicators_global,
CREATE TYPE renewables_project.energy_metric AS ENUM ('RE Capacity (%)', 'RE Generation (%)', 'Capacity factor (%)', 'Total installed cost (USD/kW)', 'LCOE (USD/kWh)');


-- Used in: fossil_cost_range
CREATE TYPE renewables_project.band AS ENUM ('Low band', 'High band');


-- Used in: fossil_cost_range, eu_elec_prices, eu_price_breakdown
CREATE TYPE renewables_project.price_unit AS ENUM ('USD/kWh', 'EUR/kWh'); 


-- Used in: energy_emissions
CREATE TYPE renewables_project.emission_unit AS ENUM ('MtCO₂');


-- Used in: eu_elec_prices, eu_price_breakdown
CREATE TYPE renewables_project.consumer AS ENUM ('Household', 'Non-household');


-- Used in: eu_elec_prices
CREATE TYPE renewables_project.energy_tax AS ENUM ('I_TAX', 'X_VAT');

