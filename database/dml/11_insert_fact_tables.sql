/* ======================================================================
   File    : 11_insert_fact_tables.sql
   Purpose : Prepares data from staging, dimension, and lookup tables and inserts into fact tables
   Author  : Elene Kikalishvili
   Date    : 2025-05-20
   Depends : 01_create_schema.sql
   ====================================================================== */





/* ======================================================================
	Notes: 
     - All joins to dim_geo that use COALESCE(country, region) = geo_name OR country = country_name
       ensure that both country and regional aggregate records are matched after harmonization.
     - geo_name and country_name are unique in dim_geo, so these joins are safe and unambiguous.
		
   ====================================================================== */




-- Table 1: primary_consumption

-- Checked unit in primary_consumption_staging

-- Creating CTE that stores IDs from dimension tables and data from staging table
WITH prepared_primary_consumption AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		pcs.year,
		'Exajoules'::renewables_project.energy_unit AS unit,
		pcs.value
	FROM renewables_project.primary_consumption_staging pcs
	JOIN renewables_project.dim_source s 
		ON pcs.source = s.source_name
	JOIN renewables_project.dim_geo g 
		ON COALESCE(pcs.country, pcs.region) = g.geo_name
		OR pcs.country = g.country_name
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.primary_consumption (
source_id, geo_id, year, unit, value
)
SELECT source_id, geo_id, year, unit, value
FROM prepared_primary_consumption;




-- Table 2: ren_primary_consumption

-- Checked unit

-- Creating CTE that stores IDs from dimension tables and data from staging table
WITH prepared_ren_primary_consumption AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		dt.tech_id,
		rpcs.year,
		'Exajoules'::renewables_project.energy_unit AS unit,
		rpcs.value
	FROM renewables_project.ren_primary_consumption_staging rpcs
	JOIN renewables_project.dim_source s 
		ON rpcs.source = s.source_name
	JOIN renewables_project.dim_geo g 
		ON COALESCE(rpcs.country, rpcs.region) = g.geo_name
		OR rpcs.country = g.country_name
	JOIN renewables_project.dim_technology dt  
		ON rpcs.technology = dt.sub_technology
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.ren_primary_consumption (
source_id, geo_id, tech_id, year, unit, value
)
SELECT source_id, geo_id, tech_id, year, unit, value
FROM prepared_ren_primary_consumption;




-- Table 3: capacity_generation

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_capacity_generation AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		t.tech_id,
		cgs.producer_type::renewables_project.grid_type,
		cgs.year,
		cgs.electricity_generation_gwh AS generation_gwh,
		cgs.electricity_installed_capacity_mw AS installed_capacity_mw
	FROM renewables_project.capacity_generation_staging cgs
	JOIN renewables_project.dim_source s 
		ON cgs.source = s.source_name
	JOIN renewables_project.dim_geo g 
		ON cgs.iso3_code = g.iso3
	JOIN renewables_project.dim_technology t
		ON cgs.technology = t.technology
		AND cgs.sub_technology = t.sub_technology
)

-- Tested before insert


-- Inserting data from CTE
INSERT INTO renewables_project.capacity_generation (
source_id, geo_id, tech_id, producer_type, year, generation_gwh, installed_capacity_mw
)
SELECT source_id, geo_id, tech_id, producer_type, year, generation_gwh, installed_capacity_mw
FROM prepared_capacity_generation;




-- Table 4: ren_share

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_ren_share AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		rss.metric_type::renewables_project.energy_metric AS indicator,
		rss.year,
		rss.value
	FROM renewables_project.ren_share_staging rss
	JOIN renewables_project.dim_source s 
		ON rss.source = s.source_name
	JOIN renewables_project.dim_geo g 
		ON rss.geo = g.geo_name
		OR rss.geo = g.country_name
)

-- Tested before insert

-- Inserting from the CTE
INSERT INTO renewables_project.ren_share (
source_id, geo_id, indicator, year, value
)
SELECT source_id, geo_id, indicator, year, value
FROM prepared_ren_share;




-- Table 5: fossil_cost_range

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_fossil_cost_range AS (
	SELECT DISTINCT
		s.source_id,
		fcrs.group_technology,
		fcrs.cost_band::renewables_project.band,
		fcrs.value,
		fcrs.unit::renewables_project.price_unit,
		fcrs.reference_year
	FROM renewables_project.fossil_cost_range_staging fcrs 
	JOIN renewables_project.dim_source s 
		ON fcrs.source = s.source_name
)

-- Inserting data
INSERT INTO renewables_project.fossil_cost_range (
source_id, group_technology, cost_band, value, unit, reference_year
)
SELECT source_id, group_technology, cost_band, value, unit, reference_year
FROM prepared_fossil_cost_range;




-- Table 6: investments

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_investments AS (
	SELECT DISTINCT
		s.source_id,
		isl.original_source_id,
		g.geo_id,
		pl.project_id,
		fl.finance_id,
		dt.tech_id, 
		inv.year,
		inv.reference_date,
		inv.amount_usd_million
	FROM renewables_project.investments_staging inv 
	JOIN renewables_project.dim_source s 
		ON inv.dataset_source = s.source_name
	JOIN renewables_project.inv_source_lookup isl
		ON inv.source = isl.original_url
	JOIN renewables_project.dim_geo g 
		ON inv.iso3 = g.iso3
	JOIN renewables_project.project_lookup pl 
		ON inv.project IS NOT DISTINCT FROM pl.project -- I have nulls in project column
		AND inv.donor = pl.donor
		AND inv.agency = pl.agency
	JOIN renewables_project.finance_lookup fl 
		ON inv.finance_group = fl.finance_group
		AND inv.finance_type = fl.finance_type
	-- Handle aggregated sub_technology values created in prior harmonization step when inserting dim_technology.
	JOIN renewables_project.dim_technology dt  
		ON inv.sub_technology = dt.sub_technology
		OR 'Agg. ' || inv.sub_technology = dt.sub_technology -- I've modified values in dim_technology
)

-- Tested before insert


-- Inserting
INSERT INTO renewables_project.investments 
	(source_id, original_source_id, geo_id, project_id, finance_id, tech_id, year, reference_date, amount_usd_million)
SELECT DISTINCT
	source_id, original_source_id, geo_id, project_id, finance_id, tech_id, year, reference_date, amount_usd_million
FROM prepared_investments;




-- Table 7: energy_emissions

-- Checked unit

-- Creating CTE that stores IDs from dimension tables and data from staging table
WITH prepared_energy_emissions AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		ems.year,
		'MtCO₂'::renewables_project.emission_unit  AS unit,
		ems.value
	FROM renewables_project.energy_emissions_staging ems
	JOIN renewables_project.dim_source s 
		ON ems.source = s.source_name
	JOIN renewables_project.dim_geo g 
		ON COALESCE(ems.country, region) = g.geo_name
		OR ems.country = g.country_name
)

-- Tested before insert

-- Isert
INSERT INTO renewables_project.energy_emissions
(source_id, geo_id, year, unit, value)

SELECT source_id, geo_id, year, unit, value
FROM prepared_energy_emissions;




-- Table 8: ren_indicators_global

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_ren_indicators_global AS (
	SELECT DISTINCT
		s.source_id,
		dt.tech_id,
		rig.year,
		rig.metric_type::renewables_project.energy_metric AS indicator,
		rig.value_category,
		rig.value
	FROM renewables_project.ren_indicators_global_staging rig
	JOIN renewables_project.dim_source s 
		ON rig.source = s.source_name
	JOIN renewables_project.dim_technology dt  
		ON rig.technology = dt.sub_technology
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.ren_indicators_global 
(source_id, tech_id, year, indicator, value_category, value)

SELECT source_id, tech_id, year, indicator, value_category, value
FROM prepared_ren_indicators_global;




-- Table 9: ren_indicators_country

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_ren_indicators_country AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		dt.tech_id,
		ric.project_type,
		ric.period,
		ric.year,
		ric.metric_type::renewables_project.energy_metric AS indicator,
		ric.value_category,
		ric.country_value,
		ric.regional_value
	FROM renewables_project.ren_indicators_country_staging ric
	JOIN renewables_project.dim_source s 
		ON ric.source = s.source_name
	JOIN renewables_project.dim_geo g
		ON COALESCE(ric.country, ric.region) = g.geo_name
		OR ric.country = g.country_name
	JOIN renewables_project.dim_technology dt  
		ON ric.technology = dt.sub_technology
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.ren_indicators_country
(source_id, geo_id, tech_id, project_type, period, year, indicator, value_category, country_value, regional_value)

SELECT 
source_id, geo_id, tech_id, project_type, period, year, indicator, value_category, country_value, regional_value
FROM prepared_ren_indicators_country;




-- Table 10: eu_consumption

-- Creating CTE that stores IDs from dimension tables and data from staging table

WITH prepared_eu_consumption AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		ecs.metric_type::renewables_project.consumption AS indicator,
		ecs."year",
		'Exajoules'::renewables_project.energy_unit AS unit,
		ecs.value_ej AS value
	FROM renewables_project.eu_consumption_staging ecs
	JOIN renewables_project.dim_source s 
		ON ecs.source = s.source_name
	JOIN renewables_project.dim_geo g
		ON ecs.iso2 = g.iso2
	JOIN renewables_project.indicator_lookup il
		ON ecs.metric_type::renewables_project.consumption = il.indicator
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.eu_consumption
(source_id, geo_id, indicator, year, unit, value)

SELECT source_id, geo_id, indicator, year, unit, value
FROM prepared_eu_consumption;




-- Table 11: eu_elec_prices

-- Checked  unit

-- Creating CTE that stores IDs from dimension tables and data from staging table
WITH prepared_eu_elec_prices AS (
	SELECT 
		s.source_id,
		g.geo_id,
		eps.consumer_type::renewables_project.consumer AS consumer_type,
		eps.consumption_band,
		eps.tax::renewables_project.energy_tax AS tax,
		LEFT(eps.period, 4)::INTEGER AS year, -- extracting year from period (2023-S1)
		'EUR/kWh'::renewables_project.price_unit AS unit,
		AVG(eps.value) AS value,
		MAX(eps.is_flagged) AS flag
	FROM renewables_project.eu_elec_prices_staging eps
	JOIN renewables_project.dim_source s 
		ON eps.source = s.source_name
	JOIN renewables_project.dim_geo g
		ON eps.iso2 = g.iso2
	GROUP BY 
    	source_id, 
    	geo_id, 
    	consumer_type, 
    	consumption_band, 
    	tax, 
    	year, 
    	unit
)

-- Tested before insert

INSERT INTO renewables_project.eu_elec_prices (
    source_id, geo_id, consumer_type, consumption_band, tax, year, unit, value, flag
)
SELECT 
    source_id, geo_id, consumer_type, consumption_band, tax, year, unit, value, flag
FROM prepared_eu_elec_prices;




-- Table 12: eu_price_breakdown

-- Checked unit

-- Creating CTE that stores IDs from dimension tables and data from staging table
WITH prepared_eu_price_breakdown AS (
	SELECT DISTINCT
		s.source_id,
		g.geo_id,
		epb.consumer_type::renewables_project.consumer AS consumer_type,
		epb.consumption_band,
		epb.price_component,
		epb.year,
		'EUR/kWh'::renewables_project.price_unit AS unit,
		epb.value,
		epb.is_flagged AS flag
	FROM renewables_project.eu_price_breakdown_staging epb
	JOIN renewables_project.dim_source s 
		ON epb.source = s.source_name
	JOIN renewables_project.dim_geo g
		ON epb.iso2 = g.iso2
	JOIN renewables_project.price_component_lookup pcl
		ON pcl.price_component  = epb.price_component 
)

-- Tested before insert

-- Insert
INSERT INTO renewables_project.eu_price_breakdown (
	source_id, geo_id, consumer_type, consumption_band, price_component, year, unit, value, flag
)
SELECT 
	source_id, geo_id, consumer_type, consumption_band, price_component, year, unit, value, flag
FROM prepared_eu_price_breakdown;















