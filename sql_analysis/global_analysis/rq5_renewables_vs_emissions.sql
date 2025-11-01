/* ======================================================================
   File    : Q1_renewables_vs_emissions.sql
   Purpose : Analyze relationship between renewable energy growth and CO2 emissions trends
   Author  : Elene Kikalishvili
   Date    : 2025-09-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 1: How has the global growth of renewable electricity generation influenced CO2 emissions over time, and 
   						do countries with higher shares of renewable generation tend to emit less?
   ============================================================================================================================ */



/* ================================================================================================
   SECTION 1: QA & Data Exploration - Emissions Dataset
   ================================================================================================ */

-- DE: Preview sample records
SELECT * 
FROM renewables_project.energy_emissions
LIMIT 5;

-- DE: Check available geographic types
SELECT DISTINCT dg.geo_type 
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id;
/*
 Available geo_type values:
   - Country
   - Region
   - Residual/unallocated
   - Economic_group
   - Global
*/

-- DE: Inspect non-country records (Residual, Economic group, Region)
SELECT DISTINCT dg.geo_type, dg.geo_name, dg.sub_region_name
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
WHERE dg.geo_type IN ('Residual/unallocated', 'Economic_group', 'Region');

-- DE: Check which African countries have emission data
SELECT DISTINCT dg.geo_name
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Country' 
  AND dg.region_name = 'Africa';
-- Includes only: South Africa, Egypt, Algeria, and Morocco

-- DE: Explore regional emission records (Africa example)
SELECT dg.geo_type, dg.geo_name, dg.sub_region_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Region' AND dg.region_name = 'Africa';

-- DE: Explore regional emission records for other continents
SELECT dg.geo_type, dg.geo_name, dg.sub_region_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Region' AND dg.region_name <> 'Africa';
-- Region-level records are not aggregates of countries; valid for use in regional/global analysis.

-- QA: Check year coverage
SELECT MIN(year) AS first_year, MAX(year) AS last_year
FROM renewables_project.energy_emissions;
-- Expected coverage: 1965-2023

-- QA: Identify missing or zero values
SELECT 
    COUNT(*) FILTER (WHERE value IS NULL) AS null_count,
    COUNT(*) FILTER (WHERE value = 0) AS zero_count
FROM renewables_project.energy_emissions; -- 340 NULLS

-- QA: Identify missing or zero values per year
SELECT
  year,
  COUNT(*) FILTER (WHERE value IS NULL) AS null_count,
  COUNT(*) FILTER (WHERE value = 0) AS zero_count
FROM renewables_project.energy_emissions
GROUP BY year
ORDER BY year;
-- Observation: 
	-- till 1970 NULL count is 15, and between 1971-1984 - 14.
	-- After 1985 there are 4 NULLs, and since 1990 there is 1 NULL each year.

-- QA: Inspect which geo entities have missing emission values
SELECT DISTINCT dg.geo_type, dg.geo_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
--WHERE ee.value IS NULL AND year < 1990;
WHERE ee.value IS NULL AND year >= 1990;
-- All yearly NULLs after 1990 correspond to the 'USSR', which ceased to exist after 1991.

-- QA: Verify units (should be MtCO2)
SELECT DISTINCT unit 
FROM renewables_project.energy_emissions;
-- Expected: MtCO2

-- QA: Check for potential duplicates
SELECT year, geo_id, COUNT(*) AS record_count
FROM renewables_project.energy_emissions
GROUP BY year, geo_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- QA: Validate total record count and match with dim_geo
SELECT COUNT(*) AS emission_rows FROM renewables_project.energy_emissions; 

SELECT COUNT(*) 
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id;
-- Counts should match (ensures no join loss)


/* ------------------------------------------------------------------
   NOTES:
   - Residual/unallocated entities (e.g., 'Other Middle East', 'USSR', 'Other CIS', 'Other Asia Pacific') 
     are excluded from regional/subregional analysis.
   - Economic_group rows (e.g., EU, OECD) are aggregates of country data and excluded.
   - Global rows are valid for global trend analysis (they are pre-aggregated).
   - Region rows are standalone records (not country aggregates) and valid for regional analysis.
   - Analysis coverage: 2000-2023
   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 2: Analyze Global CO2 Emissions vs Renewable and Fossil Generation (2000-2022)
   ================================================================================================ */

WITH emissions_global AS (
    -- Global total CO2 emissions (MtCO2)
    SELECT 
        ee.year,
        ROUND(SUM(ee.value), 2) AS global_emissions_mtco2
    FROM renewables_project.energy_emissions ee
    JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
    WHERE dg.geo_type = 'Global'
      AND ee.year >= 2000 AND ee.year < 2023
    GROUP BY ee.year
),

renewables_generation AS (
    -- Global renewable generation and share of total
    SELECT 
        cg.year,
        SUM(CASE WHEN dt.category = 'Renewable' THEN cg.generation_gwh ELSE 0 END) AS renewable_generation_gwh,
        ROUND(
            SUM(CASE WHEN dt.category = 'Renewable' THEN cg.generation_gwh ELSE 0 END)
            / NULLIF(SUM(cg.generation_gwh), 0) * 100.0, 2
        ) AS renewable_share_pct
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
    WHERE cg.year >= 2000 AND cg.year < 2023
    GROUP BY cg.year
),

fossil_generation AS (
    -- Global fossil fuel generation and share of total
    SELECT 
        cg.year,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN cg.generation_gwh ELSE 0 END)
            AS fossil_generation_gwh,
        ROUND(
            SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN cg.generation_gwh ELSE 0 END)
            / NULLIF(SUM(cg.generation_gwh), 0) * 100.0, 2
        ) AS fossil_share_pct
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
    WHERE cg.year >= 2000
    GROUP BY cg.year
),

merged AS (
    SELECT 
        e.year,
        e.global_emissions_mtco2,
        r.renewable_generation_gwh,
        f.fossil_generation_gwh,
        r.renewable_share_pct,
        f.fossil_share_pct,

        -- Relative change since base year (2000)
        ROUND((e.global_emissions_mtco2 / NULLIF(FIRST_VALUE(e.global_emissions_mtco2) OVER w_base, 0) - 1) * 100.0, 2)
            AS emissions_change_pct_since_2000,
        ROUND((r.renewable_share_pct / NULLIF(FIRST_VALUE(r.renewable_share_pct) OVER w_base, 0) - 1) * 100.0, 2)
            AS renewables_share_change_pct_since_2000,
        ROUND((f.fossil_share_pct / NULLIF(FIRST_VALUE(f.fossil_share_pct) OVER w_base, 0) - 1) * 100.0, 2)
            AS fossil_share_change_pct_since_2000,
            
        -- YoY changes (share)   
        ROUND( (r.renewable_share_pct / NULLIF(LAG(r.renewable_share_pct) OVER w_lag, 0) - 1) * 100.0, 2)
            AS renewables_share_yoy_change_pct,
        ROUND( (f.fossil_share_pct / NULLIF(LAG(f.fossil_share_pct) OVER w_lag, 0) - 1) * 100.0, 2)
            AS fossil_share_yoy_change_pct,  

        -- YoY changes (absolute generation, preferred for analysis)
        ROUND((r.renewable_generation_gwh / NULLIF(LAG(r.renewable_generation_gwh) OVER w_lag, 0) - 1) * 100.0, 2)
            AS renewables_gen_yoy_change_pct,
        ROUND((f.fossil_generation_gwh / NULLIF(LAG(f.fossil_generation_gwh) OVER w_lag, 0) - 1) * 100.0, 2)
            AS fossil_gen_yoy_change_pct,

        -- YoY changes (for emissions)
        ROUND((e.global_emissions_mtco2 / NULLIF(LAG(e.global_emissions_mtco2) OVER w_lag, 0) - 1) * 100.0, 2)
            AS emissions_yoy_change_pct

    FROM emissions_global e
    JOIN renewables_generation r USING (year)
    JOIN fossil_generation f USING (year)
    WINDOW 
        w_base AS (ORDER BY e.year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        w_lag  AS (ORDER BY e.year)
)
-- Comment and uncomment fields separately for analzying in chunks
SELECT 
    year,
    global_emissions_mtco2,
  --  renewable_generation_gwh,
  --  fossil_generation_gwh,
    renewable_share_pct,
    fossil_share_pct,
    
    emissions_change_pct_since_2000,
    renewables_share_change_pct_since_2000,
    fossil_share_change_pct_since_2000,
    
    renewables_gen_yoy_change_pct,
    fossil_gen_yoy_change_pct,
    emissions_yoy_change_pct,
    
   -- renewables_share_yoy_change_pct,
   -- fossil_share_yoy_change_pct 
    
FROM merged
ORDER BY year;

/* ------------------------------------------------------------------
	 Insights Summary (2000-2022):
	
	 Global CO2 emissions rose ~46% since 2000, while renewables' share in electricity generation
	 grew ~59% (18.3% -> 29.1%) and fossil fuels' share declined ~5%. 
	 Between 2000-2010 emissions climbed +31%, but only +11% since 2010-signaling early decoupling.
	
	 From 2008 onward, renewables generation share expanded every year, while fossil fuels mostly 
	 declined except minor rebounds in 2010-2011. During 2010-2018 renewables grew +5-8% YoY as fossil 
	 growth slowed, flattening emissions. 
	 By 2019 fossil generation plateaued; in 2020 emissions dropped (-5%) while renewables rose (+6.6%). 
	 In 2022 renewables grew +7% versus fossil +1%, keeping emissions growth to just +2%.
	
	 Overall, renewables now offset most new electricity demand, stabilizing emissions but not yet
	 achieving sustained global declines.

   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 3: Analyze Emissions Intensity vs. Renewables Share by Country (2010-2022)
   ================================================================================================ */

-- QA: Count available country records in each dataset
SELECT 
  (SELECT COUNT(DISTINCT ee.geo_id) 
   FROM renewables_project.energy_emissions ee
   JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
   WHERE dg.geo_type = 'Country' AND ee.year BETWEEN 2010 AND 2022) AS emissions_countries,
  (SELECT COUNT(DISTINCT pc.geo_id)
   FROM renewables_project.primary_consumption pc
   JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
   WHERE dg.geo_type = 'Country' AND pc.year BETWEEN 2010 AND 2022) AS consumption_countries,
  (SELECT COUNT(DISTINCT rs.geo_id)
   FROM renewables_project.ren_share rs
   JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
   WHERE dg.geo_type = 'Country' AND rs.indicator = 'RE Generation (%)'
     AND rs.value IS NOT NULL AND rs.year BETWEEN 2010 AND 2022) AS renewables_share_countries;

/* -----------------------------------------------------------
   NOTES:
   - 79 countries have emissions data and consumption data.
   - 223 countries have renewable share data.
   - Matching coverage will be limited to countries appearing in all 3 datasets.
   
   Analysis Methodology:
   - Emissions Intensity (MtCO2 per EJ) normalizes emissions by total
     energy consumption, controlling for national energy demand size.
   - Enables fairer cross-country comparison between renewable share
     and carbon output.
   - Countries with lower emissions intensity and higher renewable share
     exhibit more decarbonized energy systems.
--------------------------------------------------------------*/


/*
  Normalize CO2 emissions by total primary energy consumption (EJ) to assess whether higher 
  renewable electricity shares correspond to lower carbon intensity of national energy systems.
 */
WITH emissions AS (
  SELECT ee.geo_id, AVG(ee.value) AS avg_emissions_mtco2
  FROM renewables_project.energy_emissions ee
  JOIN renewables_project.dim_geo dg ON ee.geo_id = dg.geo_id
  WHERE dg.geo_type = 'Country'
    AND ee.year BETWEEN 2010 AND 2022
  GROUP BY ee.geo_id
),
energy_use AS (
  SELECT pc.geo_id, AVG(pc.value) AS avg_consumption_ej
  FROM renewables_project.primary_consumption pc
  JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
  WHERE dg.geo_type = 'Country'
    AND pc.year BETWEEN 2010 AND 2022
  GROUP BY pc.geo_id
),
renewables AS (
  SELECT rs.geo_id, AVG(rs.value) AS avg_renewables_share_pct
  FROM renewables_project.ren_share rs
  JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
  WHERE dg.geo_type = 'Country'
    AND rs.indicator = 'RE Generation (%)'
    AND rs.value IS NOT NULL
    AND rs.year BETWEEN 2010 AND 2022
  GROUP BY rs.geo_id
),
nuclear AS (
  SELECT 
      cg.geo_id,
      AVG(
          SUM(CASE WHEN dt.technology = 'Nuclear' THEN cg.generation_gwh ELSE 0 END)
          / NULLIF(SUM(cg.generation_gwh), 0) * 100.0
      ) OVER (PARTITION BY cg.geo_id) AS avg_nuclear_share_pct
  FROM renewables_project.capacity_generation cg
  JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
  JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
  WHERE dg.geo_type = 'Country'
    AND cg.year BETWEEN 2010 AND 2022
  GROUP BY cg.geo_id
)
SELECT 
  dg.geo_name AS country,
  ROUND(r.avg_renewables_share_pct, 2) AS avg_renewables_share_pct,
  ROUND(n.avg_nuclear_share_pct, 2) AS avg_nuclear_share_pct,
  ROUND(e.avg_emissions_mtco2, 2) AS avg_emissions_mtco2,
  ROUND(en.avg_consumption_ej, 2) AS avg_consumption_ej,
  ROUND(e.avg_emissions_mtco2 / NULLIF(en.avg_consumption_ej, 0), 2) AS emissions_intensity_mtco2_per_ej
FROM emissions e
JOIN energy_use en USING (geo_id)
JOIN renewables r USING (geo_id)
JOIN nuclear n USING (geo_id)
JOIN renewables_project.dim_geo dg USING (geo_id)
WHERE r.avg_renewables_share_pct IS NOT NULL
  AND e.avg_emissions_mtco2 IS NOT NULL
  AND en.avg_consumption_ej IS NOT NULL
--ORDER BY emissions_intensity_mtco2_per_ej DESC
ORDER BY emissions_intensity_mtco2_per_ej ASC
--ORDER BY avg_emissions_mtco2 DESC
LIMIT 10;

/* ------------------------------------------------------------------
	Insights Summary: CO2 Intensity vs Renewables & Nuclear (2010-2022 averages)
	
	Normalizing CO2 emissions by total energy use (MtCO2/EJ) reveals clear differences in 
	carbon intensity across countries. Higher renewable shares correspond to lower intensity:
	Iceland, Norway, and Sweden emit <20 MtCO2/EJ, while fossil-heavy economies like 
	South Africa, Estonia, Kazakhstan, India, and China exceed 70 MtCO2/EJ.  
	
	A strong negative relationship confirms that expanding renewables - or other low-carbon sources 
	like nuclear - significantly reduces CO2 intensity per unit of energy.
	
	- Low-intensity leaders pair high RE and/or nuclear:
	    - Iceland 12.1, Norway 18.8 (near-100% hydro/geo);
	    - Sweden 20.0, France 31.4, Switzerland 32.5 (large nuclear + RE);
	    - Brazil 36.4 (~80% RE), Canada 38.4 (65% RE + 15% nuclear) ...
	
	- High-intensity cluster maps to fossil systems w/ little to 0 nuclear:
	    - South Africa 89.1, Estonia 84.7 (oil shale), Kazakhstan 77.5,
	      India 72.7, China 71.4, Poland 73.0 ...
	
	- Largest economies - China, US, India, Russia, Japan, Germany - dominate
      global CO2 totals, but their carbon intensity diverges.
		- Coal-heavy systems (China, India) ~70 MtCO2/EJ.
		- Balanced mixes (US, Germany, Russia) ~55-60 MtCO2/EJ.
		- Hydro + nuclear balance (Canada) ~38 MtCO2/EJ.
		- Large economies emit most overall, but those with strong
		  renewable + nuclear shares are far less carbon-intensive.
	
	Conclusion: Higher RE share - and especially RE + nuclear - correlates with
	lower CO2 intensity. Where fossil dominates, intensity remains high even as
	RE grows. 
------------------------------------------------------------------ */




