/* ======================================================================
   File    : 09_insert_dim_tables.sql
   Purpose : Inserts standardized data into dimension tables: dim_technology, dim_geo, dim_source.
   Author  : Elene Kikalishvili
   Date    : 2025-05-20
   Depends : 01_create_schema.sql
   ====================================================================== */





/* ======================================================================
   Table 1: Populate dim_technology table
   ====================================================================== */


/* ---------------------------------------------------------------------------------------------------
	Step 1: Checked columns for tables that dim_technology connects to

	Step 2: Explored unique values in capacity_generation_staging, investments_staging, 
			ren_indicators_country_staging, ren_indicators_global_staging, and ren_primary_consumption_staging
   --------------------------------------------------------------------------------------------------- */


/* ---------------------------------------------------------------------------------------------------
    Step 3: Creating unified dataset via CTE
   --------------------------------------------------------------------------------------------------- */

-- Creating CTE to prepare values
WITH unified_tech AS (
	SELECT 
	-- Capitalizing only first letter of a string
	    UPPER(SUBSTRING(renewable_status, 7, 1)) || LOWER(SUBSTRING(renewable_status FROM 8)) AS category, -- Every value starts with 'Total '
	    group_technology,
	    technology,
	    sub_technology
    FROM renewables_project.capacity_generation_staging

    UNION

    SELECT 
	    RTRIM(category, 's') AS category, -- I need 'renewable' instead of 'renewables'
	    NULL AS group_technology,  -- investments doesn’t have this column
	    technology,
	    sub_technology
	FROM renewables_project.investments_staging
)



-- Filling missing values, standardizing columns and value names
, normalized_tech AS (
	SELECT DISTINCT
		category,
		CASE
			WHEN group_technology ILIKE 'Hydropower (excl.%' OR technology = 'Renewable hydropower' THEN 'Hydropower'
			WHEN technology = 'Other non-renewables' AND sub_technology = 'Pumped storage' THEN 'Pumped storage' -- I only need one 'Pumped storage' record in it's own group
			WHEN technology = 'Other non-renewables' THEN 'Other non-renewable energy'
			WHEN technology IN ('Oil', 'Natural gas', 'Coal and peat') THEN 'Fossil fuels'
			WHEN technology ILIKE 'fossil%' THEN 'Fossil fuels'
			WHEN group_technology IS NULL THEN COALESCE(group_technology, technology)
			ELSE group_technology
		END AS group_technology,
		
		CASE
			WHEN technology = 'Other non-renewables' AND sub_technology = 'Pumped storage' THEN 'Pumped storage'
			WHEN technology = 'Other non-renewables' AND sub_technology = 'Non-renewable municipal waste' THEN 'Non-renewable municipal waste'
			WHEN technology = 'Other non-renewables' THEN 'Other non-renewable energy'
			WHEN sub_technology IN ('Offshore wind energy',
									'Onshore wind energy', 
									'Biogas', 
									'Solid biofuels', 
									'Liquid biofuels', 
									'Renewable municipal waste') THEN sub_technology
			WHEN sub_technology IN ('Solar thermal energy', 'Concentrated solar power') THEN 'Solar thermal energy'
			WHEN sub_technology ILIKE '%photov%' THEN 'Solar photovoltaic'
			ELSE technology
		END AS technology,
		
		CASE
			--This is to map investments data that does not have breakdown for these technologies
			WHEN sub_technology IN ('Biogas', 'Solid biofuels', 'Liquid biofuels') THEN 'Agg. ' ||  sub_technology
			ELSE sub_technology
		END AS sub_technology
		
	FROM unified_tech
)


/* ---------------------------------------------------------------------------------------------------
    Step 4: Inserting into dim_technology
   --------------------------------------------------------------------------------------------------- */

INSERT INTO renewables_project.dim_technology (category, group_technology, technology, sub_technology)
SELECT DISTINCT
  category::renewables_project.energy_category,
  group_technology,
  technology,
  sub_technology
FROM normalized_tech;



/* ---------------------------------------------------------------------------------------------------
	Step 5: Inserting remaining unique values from ren_primary_consumption_staging, ren_indicators_global_staging, and ren_indicators_country_staging
   --------------------------------------------------------------------------------------------------- */

-- Updating technology values inside staging tables to later join on sub_technology column inside dim_technology

-- Updating ren_idnicators_global_staging
UPDATE renewables_project.ren_indicators_global_staging
SET technology = 
		CASE 
			WHEN technology = 'CSP' THEN 'Concentrated solar power'
			WHEN technology = 'Bioenergy' THEN 'Agg. bioenergy'
			WHEN technology = 'Solar PV' THEN 'Agg. solar photovoltaic'
			WHEN technology = 'Onshore Wind' THEN 'Onshore wind energy'
			WHEN technology = 'Offshore Wind' THEN 'Offshore wind energy'
			WHEN technology = 'Geothermal' THEN 'Geothermal energy'
			WHEN technology = 'Hydropower' THEN 'Agg. hydropower'
		END 
WHERE technology IN ('CSP', 'Bioenergy', 'Solar PV', 'Onshore Wind', 'Offshore Wind', 'Geothermal', 'Hydropower');




-- Updating ren_idnicators_country_staging

UPDATE renewables_project.ren_indicators_country_staging
SET technology = 
		CASE 
			WHEN technology = 'Solar PV' THEN 'Agg. solar photovoltaic'
			WHEN technology = 'Onshore wind' THEN 'Onshore wind energy'
			WHEN technology = 'Offshore wind' THEN 'Offshore wind energy'
			WHEN technology = 'Hydropower' THEN 'Agg. hydropower'
		END 
WHERE technology IN ('Solar PV', 'Onshore wind', 'Offshore wind', 'Hydropower');




-- Updating ren_primary_consumption_staging

UPDATE renewables_project.ren_primary_consumption_staging
SET technology = 
		CASE 
			WHEN technology = 'Solar' THEN 'Agg. solar energy'
			WHEN technology = 'Wind' THEN 'Agg. wind energy'
			WHEN technology = 'Biofuels' THEN 'Agg. biofuels'
			WHEN technology = 'Hydropower' THEN 'Agg. hydropower'
		END 
WHERE technology IN ('Solar', 'Wind', 'Biofuels', 'Hydropower');





-- Manually inserting aggregated records into dim_technology
INSERT INTO renewables_project.dim_technology (
	category,
	group_technology,
	technology,
	sub_technology
)
VALUES
(
 'Renewable',
 'Solar energy', 
 'Solar energy', 
 'Agg. solar energy'
),
(
 'Renewable',
 'Solar energy', 
 'Solar photovoltaic', 
 'Agg. solar photovoltaic'
),
(
 'Renewable',
 'Wind energy', 
 'Wind energy', 
 'Agg. wind energy'
),
(
 'Renewable',
 'Geothermal, Biomass, Other', 
 'Geothermal, Biomass, Other', 
 'Geothermal, Biomass, Other'
),
(
 'Renewable',
 'Bioenergy', 
 'Biofuels', 
 'Agg. biofuels'
),
(
 'Renewable',
 'Hydropower', 
 'Hydropower', 
 'Agg. hydropower'
),
(
 'Renewable',
 'Bioenergy', 
 'Bioenergy', 
 'Agg. bioenergy'
);






/* ======================================================================
   Table 2: Populate dim_geo table 
   ====================================================================== */

/* NOTE: Regional aggregates (like ‘Other S. & Cent. America’), economic groupings (OECD, EU) 
   and other non-standard areas are treated as distinct geo entities, since they don’t map to a single country. */


/* ---------------------------------------------------------------------------------------------------
	 Step 1: Inserting main data - standard country names and regions from geo_staging
   --------------------------------------------------------------------------------------------------- */


-- Checked geo_staging columns, duplicates and row number

-- Insert 
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    is_standard,
    iso3,
    iso2,
    m49_code,
    country_name,
    region_name,
    sub_region_name,
    continent_code,
    capital
)
SELECT 
    country_name AS geo_name,
    'Country'::renewables_project.geo AS geo_type,
    TRUE AS is_standard,
    iso3,
    iso2,
    m49_code,
    country_name,
    region_name,
    sub_region_name,
    continent_code,
    capital
FROM renewables_project.geo_staging;




/* ---------------------------------------------------------------------------------------------------
	Step 2: Inserting entries into dim_geo incrementally based on each staging table 
		    to ensure clean mappings and easily debug mismatches 
   --------------------------------------------------------------------------------------------------- */


/* -------------------------------
 	Table 1
   ------------------------------- */

-- Checked primary_consumption_staging columns. 

-- Checked primary_consumption_staging location values that does not have standard country match in dim_geo



-- Updating dim_geo table to map those countries that exist but don't match because they have alternate names
UPDATE renewables_project.dim_geo
SET geo_name = 'US'
WHERE country_name = 'United States of America';

UPDATE renewables_project.dim_geo
SET geo_name = 'Czech Republic'
WHERE country_name = 'Czechia';

UPDATE renewables_project.dim_geo
SET geo_name = 'China Hong Kong SAR'
WHERE country_name = 'China, Hong Kong Special Administrative Region';

UPDATE renewables_project.dim_geo
SET geo_name = 'South Korea'
WHERE country_name = 'Republic of Korea';

UPDATE renewables_project.dim_geo
SET geo_name = 'Trinidad & Tobago'
WHERE country_name = 'Trinidad and Tobago';

UPDATE renewables_project.dim_geo
SET geo_name = 'Vietnam'
WHERE country_name = 'Viet Nam';

UPDATE renewables_project.dim_geo
SET geo_name = 'Iran'
WHERE country_name = 'Iran (Islamic Republic of)';

UPDATE renewables_project.dim_geo
SET geo_name = 'Venezuela'
WHERE country_name = 'Venezuela (Bolivarian Republic of)';

UPDATE renewables_project.dim_geo
SET geo_name = 'United Kingdom'
WHERE country_name = 'United Kingdom of Great Britain and Northern Ireland';

-- Updating 'European Union #' 
UPDATE renewables_project.primary_consumption_staging
SET region = 'European Union'
WHERE region = 'European Union #';



-- Checked again with geo_name to identify records that truly don't have match in dim_geo

-- Inserting records into dim_geo that don't match with standard country names


/*
 NOTE: Country records that have CIS as their region in original dataset are mapped to standard UN region/subregions.
	   Records that don't have standard country names and are aggregates with CIS as region, are classified as 'Residual/unallocated'
*/

INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    region_name,
    sub_region_name
)

SELECT DISTINCT
	coalesce(pcs.country, pcs.region) AS geo_name,
	-- All 'Country' geo_type records are already assigned so there is no need to have it in CASE
	CASE
		WHEN pcs.region = 'CIS' THEN 'Residual/unallocated'::renewables_project.geo
		WHEN pcs.region = 'World' THEN 'Global'::renewables_project.geo
		WHEN pcs.country IS NULL AND pcs.region <> 'World' THEN 'Economic_group'::renewables_project.geo
		WHEN pcs.country IN ('Other Asia Pacific', 'Other Middle East') THEN 'Residual/unallocated'::renewables_project.geo
		ELSE 'Region'::renewables_project.geo
	END AS geo_type,
	CASE 
		WHEN pcs.region = 'European Union' THEN 'Europe'
		WHEN pcs.region = 'S. & Cent. America' THEN 'Americas'
		WHEN pcs.region IN ('Africa', 'Europe') THEN pcs.region
		ELSE NULL
	END AS region_name,
	CASE 
		WHEN pcs.region = 'S. & Cent. America' THEN 'Latin America and the Caribbean'
		WHEN pcs.region = 'Africa' AND pcs.country <>'Other Northern Africa' THEN 'Sub-Saharan Africa'
		WHEN pcs.country = 'Other Northern Africa' THEN 'Northern Africa'
		ELSE NULL 
	END AS sub_region_name
FROM renewables_project.primary_consumption_staging pcs
LEFT JOIN renewables_project.dim_geo dg
ON coalesce(pcs.country, pcs.region) = dg.geo_name
WHERE dg.country_name IS NULL;





/* -------------------------------
 	Table 2
   ------------------------------- */


-- Checked ren_primary_consumption_staging columns

-- Checked location values that does not have match in dim_geo


-- Updating 'European Union #' and 'of which: OECD' 
UPDATE renewables_project.ren_primary_consumption_staging
SET region = 'European Union'
WHERE region = 'European Union #';

UPDATE renewables_project.ren_primary_consumption_staging
SET region = 'OECD'
WHERE region = 'of which: OECD';




-- Inserting regional aggregate records into dim_geo that don't match
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    region_name,
    sub_region_name
)

SELECT DISTINCT
	COALESCE(rpcs.country, rpcs.region) AS geo_name,
	CASE 
		WHEN rpcs.region = 'CIS' THEN 'Residual/unallocated'::renewables_project.geo -- 'CIS' is not a pure region in this SCHEMA
		WHEN rpcs.region IN ('Asia Pacific', 'Middle East') THEN 'Residual/unallocated'::renewables_project.geo
		ELSE 'Region'::renewables_project.geo
	END AS geo_type,
	CASE 
		WHEN rpcs.region = 'S. & Cent. America' THEN 'Americas'
		WHEN rpcs.region = 'Africa' THEN 'Africa'
		ELSE NULL
	END AS region_name,
	CASE 
		WHEN rpcs.region = 'S. & Cent. America' THEN 'Latin America and the Caribbean'
		ELSE NULL 
	END AS sub_region_name
FROM renewables_project.ren_primary_consumption_staging rpcs
LEFT JOIN renewables_project.dim_geo dg
ON COALESCE(rpcs.country, rpcs.region) = dg.geo_name 
WHERE 
	geo_name IS NULL;





/* -------------------------------
 	Table 3
   ------------------------------- */

-- Checked capacity_generation_staging columns

-- Checked location values that does not have match in dim_geo



-- Inserting into dim_geo 
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    iso3,
    m49_code,
    region_name,
    sub_region_name
)

SELECT DISTINCT
	cgs.country AS geo_name,
	'Country'::renewables_project.geo AS geo_type,
	cgs.iso3_code AS iso3,
	cgs.m49_code,
	cgs.region AS region_name,
	cgs.sub_region AS sub_region_name
FROM renewables_project.capacity_generation_staging cgs
LEFT JOIN renewables_project.dim_geo dg
ON cgs.iso3_code = dg.iso3 
WHERE dg.iso3 IS NULL;





/* -------------------------------
 	Table 4
   ------------------------------- */

-- Checked ren_share_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating ren_share_staging geo values with standard names 
-- Updating only those records that I can't update geo_name values for. Because they are already populated with other non-standard names from other tables

UPDATE renewables_project.ren_share_staging
SET geo = 
	CASE
		WHEN geo = 'Chinese Taipei' THEN 'Taiwan'
		WHEN geo = 'Kosovo*' THEN 'Kosovo'
		ELSE geo
	END
WHERE geo IN ('Chinese Taipei', 'Kosovo*');
	


-- Updating geo_name null values for the records that have standard country_name values in dim_geo
UPDATE renewables_project.dim_geo
SET geo_name =
	CASE 
		WHEN country_name = 'Saint Martin (French Part)' THEN 'Saint Martin'
		WHEN country_name = 'Turkey' THEN 'Türkiye'
		WHEN country_name = 'Ivory Coast' THEN 'Côte d''Ivoire'
		WHEN country_name = 'Falkland Islands' THEN 'Falkland Islands (Malvinas)'
		ELSE country_name 
	END
WHERE country_name IN ('Saint Martin (French Part)', 'Turkey', 'Ivory Coast', 'Falkland Islands');



-- Inserting region records into dim_geo as new geo_name
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    region_name,
    sub_region_name
)

SELECT DISTINCT
	rss.geo AS geo_name,
	rss.geo_type::renewables_project.geo,
	
	CASE 
		WHEN rss.geo IN ('Central America and the Caribbean', 'North America', 'South America') THEN 'Americas'
		WHEN rss.geo = 'Eurasia' THEN NULL 
		ELSE geo
	END AS region_name,

	CASE 
		WHEN rss.geo IN ('Central America and the Caribbean', 'South America') THEN 'Latin America and the Caribbean'
		WHEN rss.geo = 'North America' THEN 'Northern America'
		ELSE NULL 
	END AS sub_region_name
FROM renewables_project.ren_share_staging rss
LEFT JOIN renewables_project.dim_geo dg
ON rss.geo = COALESCE(dg.country_name, dg.geo_name)
WHERE 
	dg.geo_name IS NULL 
	AND dg.country_name IS NULL 
	AND rss.geo_type = 'Region';





/* -------------------------------
 	Table 5
   ------------------------------- */

-- Checked investments_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating 'European Union (27)' with 'European Union' to later be able to join on geo_name
UPDATE renewables_project.investments_staging
SET country_or_area = 'European Union'
WHERE country_or_area = 'European Union (27)';

-- Updating iso3 code inside dim_geo for European Union
UPDATE renewables_project.dim_geo
SET iso3 = 'EUE'
WHERE geo_name = 'European Union';



-- Inserting aggregated records 
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    iso3,
    region_name,
    sub_region_name
)

SELECT DISTINCT
	CASE 
		WHEN inv.country_or_area ILIKE '%latin%' THEN 'Residual/unallocated ODA: ' || inv.region -- geo_name has to be unique
		ELSE inv.country_or_area
	END AS geo_name,
	
	CASE 
		WHEN inv.country_or_area ILIKE 'residual%' THEN 'Residual/unallocated'::renewables_project.geo
		WHEN inv.country_or_area ILIKE 'unspecified%' THEN 'Unspecified'::renewables_project.geo
		ELSE 'Multilateral'::renewables_project.geo
	END AS geo_type,
	
	inv.iso3 AS iso3,
	
	CASE 
		WHEN inv.region IN ('Central America and the Caribbean', 'South America') THEN 'Americas'
		WHEN inv.region = 'Middle East' THEN null
		WHEN inv.region ILIKE 'unspecified%' OR inv.region ILIKE 'multi%'THEN NULL
		ELSE inv.region
	END AS region_name,

	CASE 
		WHEN inv.region IN ('Central America and the Caribbean', 'South America') THEN 'Latin America and the Caribbean'
		WHEN inv.country_or_area = 'Residual/unallocated ODA: Sub-Saharan Africa' THEN 'Sub-Saharan Africa'
		ELSE NULL 
	END AS sub_region_name
	
FROM renewables_project.investments_staging inv
LEFT JOIN renewables_project.dim_geo dg
ON inv.iso3 = dg.iso3 OR inv.country_or_area = COALESCE(dg.geo_name, dg.country_name)
WHERE dg.iso3 IS NULL AND geo_name IS NULL;





/* -------------------------------
 	Table 6
   ------------------------------- */

-- Checked energy_emissions_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating 'European Union #' in energy_emissions_staging
UPDATE renewables_project.energy_emissions_staging
SET region = 'European Union'
WHERE region = 'European Union #';





/* -------------------------------
 	Table 7
   ------------------------------- */

-- Checked ren_indicators_country_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating country name in ren_indicators_country_staging
UPDATE renewables_project.ren_indicators_country_staging
SET country = 'United States of America'
WHERE country = 'United States';



-- Inserting new regional aggregate record in dim_geo
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    region_name
)

SELECT DISTINCT
	ric.region AS geo_name,
	'Residual/unallocated'::renewables_project.geo AS geo_type,
	'Asia' AS region_name
FROM renewables_project.ren_indicators_country_staging ric
LEFT JOIN renewables_project.dim_geo dg
ON COALESCE(ric.country, ric.region) = dg.country_name
OR COALESCE(ric.country, ric.region) = dg.geo_name
WHERE dg.country_name IS NULL AND geo_name IS NULL; 



  

/* -------------------------------
 	Table 8
   ------------------------------- */

-- Checked eu_consumption_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating EL iso2 code in eu_consumption_staging
UPDATE renewables_project.eu_consumption_staging
SET iso2 = 'GR'
WHERE iso2 = 'EL';

-- Updating EU27_2020 iso2 code in eu_consumption_staging
UPDATE renewables_project.eu_consumption_staging
SET iso2 = 'EU'
WHERE iso2 = 'EU27_2020';


-- Updating iso2 codes for Kosovo and Europian Union
UPDATE renewables_project.dim_geo
SET iso2 = 
	CASE
		WHEN iso3 = 'XKX' THEN 'XK'
		WHEN geo_name = 'European Union' THEN 'EU'
	END
WHERE iso3 = 'XKX' OR geo_name = 'European Union';





/* -------------------------------
 	Table 9
   ------------------------------- */

-- Checked eu_elec_prices_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating EL iso2 code in eu_elec_prices_staging
UPDATE renewables_project.eu_elec_prices_staging
SET iso2 = 'GR'
WHERE iso2 = 'EL';

-- Updating EU27_2020 iso2 code in eu_elec_prices_staging
UPDATE renewables_project.eu_elec_prices_staging
SET iso2 = 'EU'
WHERE iso2 = 'EU27_2020';

-- Updating UK iso2 code in eu_elec_prices_staging
UPDATE renewables_project.eu_elec_prices_staging
SET iso2 = 'GB'
WHERE iso2 = 'UK';



-- Inserting new record for EA in dim_geo
INSERT INTO renewables_project.dim_geo (
    geo_name,
    geo_type,
    iso2,
    region_name
)

VALUES (
	'Euro Area', 
	'Economic_group'::renewables_project.geo,
	'EA', 
	'Europe'
);





/* -------------------------------
 	Table 10
   ------------------------------- */

-- Checked eu_elec_prices_staging columns

-- Checked location values that does not have match in dim_geo



-- Updating iso2 records in eu_price_breakdown_staging
UPDATE renewables_project.eu_price_breakdown_staging
SET iso2 = 
	CASE 
		WHEN iso2 = 'EL' THEN 'GR'
		WHEN iso2 = 'EU27_2020' THEN 'EU'
		WHEN iso2 = 'UK' THEN 'GB'
	END
	
WHERE 
	iso2 = 'EL' 
	OR iso2 = 'EU27_2020' 
	OR iso2 = 'UK';





/* ======================================================================
   Table 3: Populate dim_source table
   ====================================================================== */


/* ---------------------------------------------------------------------------------------------------
	Step 1: Checked unique source names from staging tables
   --------------------------------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------------------------------
	Step 2: Inserting data into dim_source
   --------------------------------------------------------------------------------------------------- */

INSERT INTO renewables_project.dim_source (
	source_name,
	source_type,
	dataset_url,
	notes
)
VALUES
(
 'Eurostat',
 'Statistics agency (EU)', 
 'https://ec.europa.eu/eurostat/databrowser', 
 'Official statistical office of the European Union. Datasets used: estat_nrg_bal_c, estat_nrg_pc_204, estat_nrg_pc_204_c, estat_nrg_pc_205, estat_nrg_pc_205_c.'
),
(
 'IRENA',
 'International Organization', 
 'https://www.irena.org/Data', 
 'International Renewable Energy Agency is an intergovernmental organization. Datasets used: Stats_extract_2024 H2, RE_Public_Investment_July2022, RenPwrGenCosts-in-2023-v1, RESHARE_20250303.'
),
(
 'Energy Institute',
 'Not-for-profit organization',
 'https://www.energyinst.org/statistical-review',
 'Engineering society based in the UK. Dataset used: 2024 Energy Institute Statistical Review of World Energy.'
);








