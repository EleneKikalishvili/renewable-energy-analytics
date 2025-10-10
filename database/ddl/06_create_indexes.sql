/* ======================================================================
   File    : 06_create_indexes.sql
   Purpose : Creates indexes for: 
   			 	FOREIGN KEY columns inside fact tables used for joins.
             	Columns that are frequently filtered in WHERE, table is moderate/large size,
             	and have many distinct values.
   Author  : Elene Kikalishvili
   Date    : 2025-05-05
   Depends : 01_create_schema.sql
   ====================================================================== */



-- Note: No index on source_id as it's used for documentation only. Add index if future joins require it.

-- Indexes for primary_consumption
CREATE INDEX idx_primary_consumption_geo_id ON renewables_project.primary_consumption(geo_id); --FOREIGN KEY
CREATE INDEX idx_primary_consumption_year ON renewables_project.primary_consumption(year);

-- Indexes for ren_primary_consumption
CREATE INDEX idx_ren_primary_consumption_geo_id ON renewables_project.ren_primary_consumption(geo_id); --FOREIGN KEY
CREATE INDEX idx_ren_primary_consumption_tech ON renewables_project.ren_primary_consumption(tech_id);
CREATE INDEX idx_ren_primary_consumption_year ON renewables_project.ren_primary_consumption(year);


-- Indexes for capacity_generation
CREATE INDEX idx_capacity_generation_geo_id ON renewables_project.capacity_generation(geo_id); --FOREIGN KEY
CREATE INDEX idx_capacity_generation_tech_id ON renewables_project.capacity_generation(tech_id); --FOREIGN KEY
CREATE INDEX idx_capacity_generation_year ON renewables_project.capacity_generation(year);


-- Indexes for ren_share
CREATE INDEX idx_ren_share_geo_id ON renewables_project.ren_share(geo_id); --FOREIGN KEY
CREATE INDEX idx_ren_share_year ON renewables_project.ren_share(year);


-- Indexes for investments
CREATE INDEX idx_investments_original_source_id ON renewables_project.investments(original_source_id); --FOREIGN KEY
CREATE INDEX idx_investments_geo_id ON renewables_project.investments(geo_id); --FOREIGN KEY
CREATE INDEX idx_investments_project_id ON renewables_project.investments(project_id); --FOREIGN KEY
CREATE INDEX idx_investments_finance_id ON renewables_project.investments(finance_id); --FOREIGN KEY
CREATE INDEX idx_investments_tech_id ON renewables_project.investments(tech_id); --FOREIGN KEY
CREATE INDEX idx_investments_year ON renewables_project.investments(year);


-- Indexes for energy_emissions
CREATE INDEX idx_energy_emissions_geo_id ON renewables_project.energy_emissions(geo_id); --FOREIGN KEY
CREATE INDEX idx_energy_emissions_year ON renewables_project.energy_emissions(year);


-- Indexes for ren_indicators_global
-- No INDEX for tech_id column because table is small and only column has few distinct values
CREATE INDEX idx_ren_indicators_global_year ON renewables_project.ren_indicators_global(year);


-- Indexes for ren_indicators_country
-- No INDEX for tech_id column because table is small and only column has few distinct values
CREATE INDEX idx_ren_indicators_country_geo_id ON renewables_project.ren_indicators_country(geo_id); --FOREIGN KEY
CREATE INDEX idx_ren_indicators_country_year ON renewables_project.ren_indicators_country(year);


-- Indexes for eu_consumption
CREATE INDEX idx_eu_consumption_geo_id ON renewables_project.eu_consumption(geo_id); --FOREIGN KEY
CREATE INDEX idx_eu_consumption_indicator ON renewables_project.eu_consumption(indicator);  --FOREIGN KEY
CREATE INDEX idx_eu_consumption_year ON renewables_project.eu_consumption(year);


-- Indexes for eu_elec_prices
CREATE INDEX idx_eu_elec_prices_geo_id ON renewables_project.eu_elec_prices(geo_id); --FOREIGN KEY
CREATE INDEX idx_eu_elec_prices_consumption_band ON renewables_project.eu_elec_prices(consumption_band);
CREATE INDEX idx_eu_elec_prices_year ON renewables_project.eu_elec_prices(year);


-- Indexes for eu_price_breakdown
CREATE INDEX idx_eu_price_breakdown_geo_id ON renewables_project.eu_price_breakdown(geo_id); --FOREIGN KEY
CREATE INDEX idx_eu_price_breakdown_consumption_band ON renewables_project.eu_price_breakdown(consumption_band);
CREATE INDEX idx_eu_price_breakdown_price_component ON renewables_project.eu_price_breakdown(price_component); --FOREIGN KEY
CREATE INDEX idx_eu_price_breakdown_year ON renewables_project.eu_price_breakdown(year);


