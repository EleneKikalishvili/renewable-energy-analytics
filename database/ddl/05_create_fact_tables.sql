/* ======================================================================
   File    : 05_create_fact_tables.sql
   Purpose : Creates all the fact tables that store main data for analysis, and associated ENUM types.
   Author  : Elene Kikalishvili
   Date    : 2025-05-04
   Depends : 01_create_schema.sql
   ====================================================================== */




-- Table 1: primary_consumption
-- Purpose: Stores primary energy consumption by country and region

CREATE TABLE renewables_project.primary_consumption (
	consumption_id SERIAL CONSTRAINT pk_primary_consumption PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	year INTEGER NOT NULL CHECK (year >= 1965 AND year <= 2028), --Prevents bad data, gives small buffer for future updates. Available year data 1965-2023
	unit renewables_project.energy_unit NOT NULL,
	value NUMERIC,
	CONSTRAINT uq_primary_consumption_geo_year UNIQUE (geo_id, year)
);

COMMENT ON TABLE renewables_project.primary_consumption IS
  'Stores yearly primary energy consumption by country and region, measured in exajoules. Enables analysis of global and regional consumption trends.';




-- Table 2: ren_primary_consumption
-- Purpose: Stores primary energy consumption by country, region and renewable energy technology

CREATE TABLE renewables_project.ren_primary_consumption (
	ren_consumption_id SERIAL CONSTRAINT pk_ren_primary_consumption PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	tech_id INTEGER NOT NULL REFERENCES renewables_project.dim_technology(tech_id),
	year INTEGER NOT NULL CHECK (year >= 1965 AND year <= 2028), --Available year data 1965-2023
	unit renewables_project.energy_unit NOT NULL,
	value NUMERIC,
	CONSTRAINT uq_ren_primary_consumption_geo_tech_year UNIQUE (geo_id, tech_id, year)
);

COMMENT ON TABLE renewables_project.ren_primary_consumption IS
  'Stores renewable energy consumption data by country, region, and renewable technology, enabling tech-level trend analysis.';




-- Table 3: capacity_generation
-- Purpose: Stores electricity generation and installed capacity data by country and technology

CREATE TABLE renewables_project.capacity_generation (
	cap_gen_id SERIAL CONSTRAINT pk_capacity_generation PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	tech_id INTEGER NOT NULL REFERENCES renewables_project.dim_technology(tech_id),
	producer_type renewables_project.grid_type NOT NULL,
	year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2028), --Available year data 2000-2023
	generation_gwh NUMERIC,
	installed_capacity_mw NUMERIC,
	CONSTRAINT uq_capacity_generation_geo_tech_prod_year UNIQUE (geo_id, tech_id, producer_type, year)
);

COMMENT ON TABLE renewables_project.capacity_generation IS
  'Stores data on electricity generation and installed capacity by country, technology, and producer type (on-grid/off-grid).';




-- Table 4: ren_share
-- Purpose: Stores percentage data of renewable technologies share of electricity generation and capacity

CREATE TABLE renewables_project.ren_share (
	ren_share_id SERIAL CONSTRAINT pk_ren_share PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	indicator renewables_project.energy_metric NOT NULL,
	year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2028),  --Available year data 2000-2023
	value NUMERIC,
	CONSTRAINT uq_ren_share_geo_indic_year UNIQUE (geo_id, indicator, year)
);

COMMENT ON TABLE renewables_project.ren_share IS
  'Stores percentage-based indicators related to renewable energy (e.g., capacity share, generation share).';




-- Table 5: fossil_cost_range
-- Purpose: A reference table storing aggregated fossil fuels' lowest and highest cost. Will be used for comparison

CREATE TABLE renewables_project.fossil_cost_range (
	cost_band_id SERIAL CONSTRAINT pk_fossil_cost_range PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	group_technology VARCHAR(15) NOT NULL,
	cost_band renewables_project.band NOT NULL,
	value NUMERIC NOT NULL,
	unit renewables_project.price_unit NOT NULL,
	reference_year INTEGER NOT NULL CHECK (reference_year >= 2023 AND reference_year <= 2028), --Available year data 2023
	CONSTRAINT uq_fossil_cost_range_tech_band_year UNIQUE (group_technology, cost_band, reference_year)
); 

COMMENT ON TABLE renewables_project.fossil_cost_range IS
  'Stores reference values of aggregated fossil fuel lowest and highest costs for global comparison against renewable energy data.';




-- Table 6: investments
-- Purpose: Stores public investment data for different energy technologies and will be used to compare with LCOE and electricity prices data 

CREATE TABLE renewables_project.investments (
	investment_id SERIAL CONSTRAINT pk_investments PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	original_source_id INTEGER NOT NULL REFERENCES renewables_project.inv_source_lookup(original_source_id), --references original source links provided by IRENA
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	project_id INTEGER NOT NULL REFERENCES renewables_project.project_lookup(project_id),
	finance_id INTEGER NOT NULL REFERENCES renewables_project.finance_lookup(finance_id),
	tech_id INTEGER NOT NULL REFERENCES renewables_project.dim_technology(tech_id),
	year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2028),  --Available year data 2000-2020
	reference_date DATE NOT NULL,
	amount_usd_million NUMERIC NOT NULL,
	CONSTRAINT uq_investments_all UNIQUE (original_source_id, geo_id, project_id, finance_id, tech_id, year, reference_date, amount_usd_million)
); --In the orginal data some different amount_usd_million values have exact same data in every other column, I am not considering them duplicates

COMMENT ON TABLE renewables_project.investments IS
  ' Holds detailed public investment data per country, year, project, and energy technology. Useful for financial trends & LCOE comparisons.';




-- Table 7: energy_emissions
-- Purpose: Stores CO2 emission data from energy per country and region

CREATE TABLE renewables_project.energy_emissions (
	emission_id SERIAL CONSTRAINT pk_energy_emissions PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	year INTEGER NOT NULL CHECK (year >= 1965 AND year <= 2028), --Available year data 1965-2023
	unit renewables_project.emission_unit NOT NULL,
	value NUMERIC,
	CONSTRAINT uq_energy_emissions_geo_year UNIQUE (geo_id, year)
);

COMMENT ON TABLE renewables_project.energy_emissions IS
  'Stores CO₂ emissions (million tonnes) per country/region for energy use, enabling carbon footprint tracking.';




-- Table 8: ren_indicators_global
-- Purpose: Stores Total installed cost, LCOE, and Capacity factor data per year and renewable technology

CREATE TABLE renewables_project.ren_indicators_global (
	indicator_gl_id SERIAL CONSTRAINT pk_ren_indicators_global PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	tech_id INTEGER NOT NULL REFERENCES renewables_project.dim_technology(tech_id),
	year INTEGER NOT NULL,
	indicator renewables_project.energy_metric NOT NULL,
	value_category VARCHAR(20) NOT NULL, --This column stores calculation-type values: '5th percentile', 'Weighted average', AND '95th percentile'
	value NUMERIC,
	CONSTRAINT uq_rig_tech_indic_year_valcat UNIQUE (tech_id, indicator, year, value_category)
);

COMMENT ON TABLE renewables_project.ren_indicators_global IS
  'Holds global indicators like Total Installed Cost, LCOE, and Capacity Factor for each renewable technology per year.';




-- Table 9: ren_indicators_country
-- Purpose: Stores Total installed cost, LCOE, and Capacity factor data per country, year and renewable technology

CREATE TABLE renewables_project.ren_indicators_country (
	indicator_c_id SERIAL CONSTRAINT pk_ren_indicators_country PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	tech_id INTEGER NOT NULL REFERENCES renewables_project.dim_technology(tech_id),
	project_type VARCHAR(15), --this column is specifically for hydroenergy and solar for other technologies it's NULL
	period CHAR(9) NOT NULL, 
	year INTEGER,   --some records only have periods
	indicator renewables_project.energy_metric NOT NULL,
	value_category VARCHAR(20) NOT NULL, --This column stores calculation-type values: '5th percentile', 'Weighted average', AND '95th percentile'
	country_value NUMERIC,
	regional_value NUMERIC,
	CONSTRAINT uq_ric_geo_tech_projtype_indic_year_valcat UNIQUE (geo_id, tech_id, project_type, indicator, year, value_category)
);

COMMENT ON TABLE renewables_project.ren_indicators_country IS
  'Holds country-level data for Total Installed Cost, LCOE, and Capacity Factor for Solar PV, Offshore Wind, Onshore Wind, and hydropower per year.';

COMMENT ON COLUMN renewables_project.ren_indicators_country.project_type IS
  'Project type: only populated for hydropower and solar, otherwise NULL.';




-- Table 10: eu_consumption
-- Purpose: Stores primary and final energy consumption data for EU countries

CREATE TABLE renewables_project.eu_consumption (
	eu_cons_id SERIAL CONSTRAINT pk_eu_consumption PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	indicator renewables_project.consumption NOT NULL REFERENCES renewables_project.indicator_lookup(indicator),
	year INTEGER NOT NULL CHECK (year >= 1990 AND year <= 2028), --Available year data 1990-2023
	unit renewables_project.energy_unit NOT NULL,
	value NUMERIC,
	CONSTRAINT uq_eu_consumption_geo_indic_year UNIQUE (geo_id, indicator, year)
);

COMMENT ON TABLE renewables_project.eu_consumption IS
  'Stores energy consumption data (primary and final) for EU countries across different years.';




-- Table 11: eu_elec_prices
-- Purpose: Stores EU electricity prices data by for household and non-household consumers

CREATE TABLE renewables_project.eu_elec_prices (
	el_price_id SERIAL CONSTRAINT pk_eu_elec_prices PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	consumer_type renewables_project.consumer NOT NULL,
	consumption_band VARCHAR(20) NOT NULL,
	tax renewables_project.energy_tax NOT NULL,
	year INTEGER NOT NULL CHECK (year >= 2007 AND year <= 2028), --Available year data 2007-2024
	unit renewables_project.price_unit NOT NULL,
	value NUMERIC,
	flag char(1), --shows how reliable data is
	CONSTRAINT uq_eu_elec_prices_geo_consumer_band_year UNIQUE (geo_id, consumer_type, consumption_band, tax, year)
);

COMMENT ON TABLE renewables_project.eu_elec_prices IS
  'Stores EU electricity prices by consumer type (household vs. non-household) and consumption_band, per year.';

COMMENT ON COLUMN renewables_project.eu_elec_prices.tax IS
  'Stores tax values I_TAX AND X_VAT. I_TAX - prices including all taxes and levies is for household consumers. X_VAT - prices excluding VAT and other recoverable taxes and levies is for non-household consumers.';

COMMENT ON COLUMN renewables_project.eu_elec_prices.flag IS
  'Data reliability flag: null means reliable, letter codes indicate estimated or provisional values.';




-- Table 12: eu_price_breakdown
-- Purpose: Stores electricity price component data to analyze what drives electricity prices

CREATE TABLE renewables_project.eu_price_breakdown (
	component_id SERIAL CONSTRAINT pk_eu_price_breakdown PRIMARY KEY,
	source_id INTEGER NOT NULL REFERENCES renewables_project.dim_source(source_id),
	geo_id INTEGER NOT NULL REFERENCES renewables_project.dim_geo(geo_id),
	consumer_type renewables_project.consumer NOT NULL,
	consumption_band VARCHAR(20) NOT NULL,
	price_component VARCHAR(30) NOT NULL REFERENCES renewables_project.price_component_lookup(price_component),
	year INTEGER NOT NULL CHECK (year >= 2017 AND year <= 2028), --Available year data 2017-2023
	unit renewables_project.price_unit NOT NULL,
	value NUMERIC,
	flag char(1), --shows how reliable data is
	CONSTRAINT uq_eu_price_breakdown_geo_consumer_band_comp_year UNIQUE (geo_id, consumer_type, consumption_band, price_component, year)
);

COMMENT ON TABLE renewables_project.eu_price_breakdown IS
  'Holds granular breakdowns of EU electricity prices, to analyze drivers like network fees, taxes, and levies.';

COMMENT ON COLUMN renewables_project.eu_price_breakdown.flag IS
  'Data reliability flag: null means reliable, letter codes indicate estimated or provisional values.';





