/* ======================================================================
   File    : rq3_cost_trends.sql
   Purpose : Analyze trends in the Levelized Cost of Energy (LCOE) and installed costs globally
             for each renewable technology over time, benchmarked against fossil fuel cost bands,
             and few key renewbale technologies at the sub-regional and country levels.
   Author  : Elene Kikalishvili
   Date    : 2025-06-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 3: Which renewable technologies have experienced the largest declines in Levelized Cost of Energy (LCOE)
   			            and installed costs?
   ============================================================================================================================ */



/* ================================================================================================
   SECTION 1: Global Analysis - LCOE and Installed Costs from ren_indicators_global
   ================================================================================================ */

/* ============================================================================
   SECTION 1A: QA & Data Exploration 
   ============================================================================ */

-- DE: Preview sample global cost data
SELECT * 
FROM renewables_project.ren_indicators_global
LIMIT 5;

-- DE: Check available indicators
SELECT DISTINCT indicator
FROM renewables_project.ren_indicators_global;

-- DE: Preview fossil fuel benchmark dataset
SELECT * 
FROM renewables_project.fossil_cost_range;


-- QA: Check missing or zero LCOE/Cost values by technology-year
SELECT 
    dt.technology,
    COUNT(*) FILTER (WHERE rig.value IS NULL) AS null_count,
    COUNT(*) FILTER (WHERE rig.value = 0) AS zero_count
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt ON rig.tech_id = dt.tech_id
WHERE 
	rig.indicator IN ('LCOE (USD/kWh)', 'Total installed cost (USD/kW)')
	AND rig.value_category = 'Weighted average'
GROUP BY dt.technology
ORDER BY null_count DESC; -- Geothermal data has 2 NULLS

-- DE: Review technology data
SELECT DISTINCT
	dt.technology,
	dt.sub_technology
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt  ON rig.tech_id = dt.tech_id;
--NOTE: Only has CSP data not general Solar thermal energy data


-- DE: Review renewable cost structure by technology and year
SELECT
	dt.technology,
	rig.year,
	MAX(CASE WHEN rig.indicator = 'LCOE (USD/kWh)' THEN rig.value END) AS lcoe_usd_per_kwh,
	MAX(CASE WHEN rig.indicator = 'Total installed cost (USD/kW)' THEN rig.value END) AS tot_installed_cost_usd_per_kw
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt  ON rig.tech_id = dt.tech_id
WHERE 
	rig.value_category = 'Weighted average'
	AND (rig.indicator::text ILIKE '%cost%' OR rig.indicator::text ILIKE 'LCOE%')
--	AND dt.technology = 'Geothermal energy' -- 2011 data is missing
GROUP BY 
	dt.technology, rig.year
ORDER BY rig.year;


-- QA: Verify consistent year coverage
SELECT 
    dt.technology,
    MIN(rig.year) AS first_year,
    MAX(rig.year) AS last_year,
    COUNT(DISTINCT rig.year) AS year_count
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt ON rig.tech_id = dt.tech_id
WHERE rig.indicator = 'LCOE (USD/kWh)'
GROUP BY dt.technology
ORDER BY first_year;



/* ============================================================================
   Query 1: Analyze Global LCOE and Installed Cost Trends (2010–2023)
   ============================================================================ */

WITH global_costs_base AS (
    -- Aggregate global weighted-average LCOE and installed cost by technology and year
    SELECT
        g.tech_id,
        CASE 
        	WHEN dt.technology = 'Solar thermal energy' THEN 'CSP'
        	ELSE dt.technology
        END AS technology,
        g.year,
        MAX(CASE WHEN g.indicator = 'LCOE (USD/kWh)' THEN g.value END) AS lcoe_usd_per_kwh,
        MAX(CASE WHEN g.indicator = 'Total installed cost (USD/kW)' THEN g.value END) AS installed_cost_usd_per_kw
    FROM renewables_project.ren_indicators_global g
    JOIN renewables_project.dim_technology dt 
        ON g.tech_id = dt.tech_id
    WHERE
        g.value_category = 'Weighted average'
        AND g.indicator IN ('LCOE (USD/kWh)', 'Total installed cost (USD/kW)')
    GROUP BY g.tech_id, technology, g.year
),

fossil_costs AS ( 
    -- Extract 2023 fossil fuel benchmark ranges
    SELECT 
        MAX(CASE WHEN cost_band = 'Low band'  THEN value END) AS lowest_fossil_cost_usd_per_kwh_2023,
        MAX(CASE WHEN cost_band = 'High band' THEN value END) AS highest_fossil_cost_usd_per_kwh_2023
    FROM renewables_project.fossil_cost_range
),

cost_trends AS (
    -- Compute 2010 and 2023 values using window functions
    SELECT DISTINCT
        tech_id,
        technology,
        -- Baseline (2010)
        FIRST_VALUE(lcoe_usd_per_kwh) 
            OVER (PARTITION BY tech_id ORDER BY year) AS lcoe_usd_per_kwh_2010,
        FIRST_VALUE(installed_cost_usd_per_kw) 
            OVER (PARTITION BY tech_id ORDER BY year) AS installed_cost_usd_per_kw_2010,
        -- Latest (2023 or last available)
        LAST_VALUE(lcoe_usd_per_kwh) 
            OVER (PARTITION BY tech_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lcoe_usd_per_kwh_2023,
        LAST_VALUE(installed_cost_usd_per_kw) 
            OVER (PARTITION BY tech_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS installed_cost_usd_per_kw_2023
    FROM global_costs_base
)

SELECT
    c.technology,
    fc.lowest_fossil_cost_usd_per_kwh_2023,
    fc.highest_fossil_cost_usd_per_kwh_2023,
    c.lcoe_usd_per_kwh_2010,
    c.lcoe_usd_per_kwh_2023,
    ROUND(
        (c.lcoe_usd_per_kwh_2023 - c.lcoe_usd_per_kwh_2010)
        / NULLIF(c.lcoe_usd_per_kwh_2010, 0) * 100, 1
    ) AS rel_change_lcoe_pct,
    c.installed_cost_usd_per_kw_2010,
    c.installed_cost_usd_per_kw_2023,
    ROUND(
        (c.installed_cost_usd_per_kw_2023 - c.installed_cost_usd_per_kw_2010)
        / NULLIF(c.installed_cost_usd_per_kw_2010, 0) * 100, 1
    ) AS rel_change_installed_cost_pct,
    ROUND(
        (POWER(c.lcoe_usd_per_kwh_2023 / NULLIF(c.lcoe_usd_per_kwh_2010, 0), 1.0 / (2023 - 2010)) - 1) * 100,
        2
    ) AS lcoe_cagr_pct,
    ROUND(
        (POWER(c.installed_cost_usd_per_kw_2023 / NULLIF(c.installed_cost_usd_per_kw_2010, 0), 1.0 / (2023 - 2010)) - 1) * 100,
        2
    ) AS installed_cost_cagr_pct
FROM cost_trends c
CROSS JOIN fossil_costs fc
ORDER BY c.lcoe_usd_per_kwh_2023;
--ORDER BY lcoe_usd_per_kwh_2010;
--ORDER BY rel_change_lcoe_pct ASC;

/* ------------------------------------------------------------------  
 Insights Summary:

   - Largest declines:
	     - Solar PV: LCOE ~−90%, Installed cost ~−86% (biggest overall)
	     - Onshore wind: LCOE ~−71%, Cost ~−49%
	     - CSP: LCOE ~−70%, Cost ~−38% ; Offshore wind: LCOE ~−63%, Cost ~−48%
     
   - Modest: Bioenergy (LCOE ~−15%, Cost ~−9%)
   
   - Cost Risers: Hydropower & Geothermal (LCOE and costs)
   
   - 2023 competitiveness (USD/kWh):
	     - Below fossil low (0.07): Onshore (0.033), Solar PV (0.044), Hydro (0.057)
	     - Within fossil band: Offshore (~0.075), CSP (~0.12), Geothermal (~0.071), Bioenergy (~0.072)

   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 2: Country-Level Analysis - LCOE and Installed Cost Trends from ren_indicators_country
   ================================================================================================ */

/* ============================================================================
   SECTION 2A: QA & Data Exploration 
   ============================================================================ */

-- DE: Preview sample records
SELECT *
FROM renewables_project.ren_indicators_country
LIMIT 5;

-- DE: check available geo_type
SELECT DISTINCT dg.geo_type
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id;

/*
 Region
 Residual/unallocated
 Country
 */

-- DE: explore Region and Residual records
SELECT DISTINCT dt.technology, dg.geo_type, dg.geo_name, dg.sub_region_name
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dg.geo_type = 'Residual/unallocated';
-- WHERE dg.geo_type = 'Region';

/*
 * NOTES:
 * 	- Only Hydropower has 'Region' type records which are standalone area-level records.
 *  - Only Hydropower has 'Residual/unallocated' record - 'Middle East'
 */

-- DE: Check available indicators
SELECT DISTINCT indicator
FROM renewables_project.ren_indicators_country;


-- DE: Count unique countries overall and by technology
SELECT COUNT(DISTINCT geo_id) AS total_countries
FROM renewables_project.ren_indicators_country;  -- Expect 58

SELECT dt.technology, COUNT(DISTINCT geo_id) AS country_count
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
GROUP BY dt.technology
ORDER BY country_count DESC;


-- DE: Count countries reporting in baseline year (2010)
SELECT COUNT(DISTINCT geo_id) AS countries_2010
FROM renewables_project.ren_indicators_country
WHERE "year" = 2010;  -- Around 25 (~33 missing in 2010)


-- QA: Verify available year range per technology
SELECT dt.technology, MIN(year) AS first_year, MAX(year) AS last_year
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
--WHERE dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
GROUP BY dt.technology
ORDER BY first_year;


-- QA: Check for missing or zero values
SELECT
    dt.technology,
    COUNT(*) FILTER (WHERE ric.country_value IS NULL) AS null_count,
    COUNT(*) FILTER (WHERE ric.country_value = 0) AS zero_count
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE 
    ric.indicator IN ('LCOE (USD/kWh)', 'Total installed cost (USD/kW)')
    AND ric.value_category = 'Weighted average'
GROUP BY dt.technology
ORDER BY null_count DESC; -- Hydropower data is incomplete

-- QA: Country vs regional fields (spot-check a tech)
SELECT
    ric.indicator,
    COUNT(*) FILTER (WHERE ric.country_value IS NULL ) AS country_null_count, -- 28
    COUNT(DISTINCT dg.geo_id) FILTER (WHERE ric.country_value IS NOT NULL) AS country_value_c,
    COUNT(*) FILTER (WHERE ric.regional_value IS NULL) reg_null_count,
    COUNT(DISTINCT dg.geo_id) FILTER (WHERE ric.regional_value IS NOT NULL) reg_value_c
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
JOIN renewables_project.dim_geo dg ON  ric.geo_id = dg.geo_id
WHERE 
	--dt.technology = 'Hydropower'
	dt.technology = 'Offshore wind energy'
    AND ric.indicator IN ('LCOE (USD/kWh)', 'Total installed cost (USD/kW)')
    AND ric.value_category = 'Weighted average'
GROUP BY ric.indicator; -- Hydropower data is incomplete


/* ------------------------------------------------------------------ 
 * === Notes on Data Limitation ===
   - Hydropower LCOE and Installed cost data is only available in 3 countries and 10 regions.
   - Hydropower data does not have yearly data only period.
   - Offshore wind data is limited to 8 countries and 7 regions.
   - Due to data limitation only 3 leading technologies - Solar PV, Onshore wind, and Offshroe wind - will be analyzed.
   - Regional average calcualtions represent average of countries' reporting data in that year/technology,
     not true average of all countries in the region.
   - Results of the analysis should be interpreted as "spotlights" rather than a comprehensive world view.
   - This analysis is best used as a supplement to global trends.
   ------------------------------------------------------------------ */



/* ============================================================================
   Query 1: Analyze Country and Subregional LCOE & Installed Cost Trends (2010–2023)
   
   Goal: Highlight where costs have dropped fastest, and which regions/countries 
         are global “cost leaders” in renewables.
   ============================================================================ */

WITH subregional_tech_avg AS (
    -- Calculate average LCOE and installed cost by subregion, year, and technology
    SELECT
        dg.sub_region_name AS subregion,
        dt.technology,
        ric.year,
        AVG(ric.country_value) FILTER (WHERE ric.indicator = 'LCOE (USD/kWh)') AS avg_lcoe_subregion,
        COUNT(DISTINCT dg.geo_name) FILTER (WHERE ric.indicator = 'LCOE (USD/kWh)' AND ric.country_value IS NOT NULL) AS n_countries_lcoe,
        AVG(ric.country_value) FILTER (WHERE ric.indicator = 'Total installed cost (USD/kW)') AS avg_installed_cost_subregion,
        COUNT(DISTINCT dg.geo_name) FILTER (WHERE ric.indicator = 'Total installed cost (USD/kW)' AND ric.country_value IS NOT NULL) AS n_countries_cost
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
    WHERE
        ric.value_category = 'Weighted average'
        AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
        AND ric.year >= 2010
    GROUP BY dg.sub_region_name, dt.technology, ric.year
),

country_tech_costs AS ( 
    -- Retrieve individual country-level costs for reference
    SELECT
        dg.sub_region_name AS subregion,
        dg.geo_name AS country,
        dt.technology,
        ric.year,
        MAX(ric.country_value) FILTER (WHERE ric.indicator = 'LCOE (USD/kWh)') AS lcoe_usd_per_kwh,
        MAX(ric.country_value) FILTER (WHERE ric.indicator = 'Total installed cost (USD/kW)') AS installed_cost_usd_per_kw
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
    WHERE
        ric.value_category = 'Weighted average'
        AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
        AND ric.year >= 2010
    GROUP BY dg.sub_region_name, dg.geo_name, dt.technology, ric.year
)

SELECT 
    sra.technology,
    sra.subregion,
    cc.country,
    sra.year,
    cc.lcoe_usd_per_kwh,
    sra.avg_lcoe_subregion,
    sra.n_countries_lcoe,
    ROUND(
        (sra.avg_lcoe_subregion - FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))
        / NULLIF(FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 0) * 100,
        2
    ) AS pct_change_since_2010_lcoe_subregion,
    cc.installed_cost_usd_per_kw,
    sra.avg_installed_cost_subregion,
    sra.n_countries_cost,
    ROUND(
        (sra.avg_installed_cost_subregion - FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))
        / NULLIF(FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 0) * 100,
        2
    ) AS pct_change_since_2010_installed_cost_subregion
FROM subregional_tech_avg sra
LEFT JOIN country_tech_costs cc
    ON sra.subregion = cc.subregion
    AND sra.technology = cc.technology
    AND sra.year = cc.year
--ORDER BY sra.technology, sra.year DESC, cc.installed_cost_usd_per_kw;
ORDER BY sra.technology, sra.year DESC, pct_change_since_2010_installed_cost_subregion, cc.installed_cost_usd_per_kw;
--ORDER BY sra.technology, sra.year DESC, sra.avg_installed_cost_subregion ASC, cc.installed_cost_usd_per_kw;
--ORDER BY sra.technology, sra.year DESC, sra.avg_lcoe_subregion;


/* ------------------------------------------------------------------  
 Insights Summary:

   Data coverage: Up to 58 countries, focused on Solar PV, Onshore wind, and Offshore wind. 
   Offshore wind has limited sample size (8 countries).
   
   LCOE Trends (USD/kWh):
	   Regional Overview:
	      - Offshore wind: Largest decline in Western Europe (~−72%), limited country data.
	      - Onshore wind: Biggest drops in Northern Europe (~−71%), Australia & NZ (~−70%), and North America (~−68%).
	      - Solar PV: Steepest declines in Australia (~−92%), India (~−88%), and Southern Europe (~−87%).
	
	   2023 Regional LCOE Leaders:
	      - Offshore wind: Northern Europe (~$0.054/kWh)
	      - Onshore wind: North America (~$0.037), Northern Europe (~$0.038), Australia & NZ (~$0.042)
	      - Solar PV: Australia & NZ (~$0.038), Southern Asia (~$0.048), Southern Europe (~$0.052)
	
	   Country-Level Highlights:
	      - Offshore wind: Cheapest in Denmark ($0.048), UK ($0.059), Netherlands ($0.061)
	      - Onshore wind: Cheapest in Brazil ($0.025), China ($0.026), UK ($0.031)
	      - Solar PV: Cheapest in China ($0.036), Australia ($0.038), Chile ($0.041)
	      - Japan remains among the highest-cost markets for all three technologies.
      
      
   Installed Cost Trends (USD/kW):
      Regional Overview:
         - Offshore wind: Western Europe recorded the largest installed cost decline (~−62%), 
           with an average subregional cost of ~$2,730/kW; the Netherlands reports the lowest cost ($2,564/kW).
         - Onshore wind: Australia & NZ saw the largest drop (~−60%, avg ~$1,624/kW), 
           followed by Latin America & the Caribbean (~−54%, avg ~$1,434/kW) 
           and Northern Europe (~−51%, avg ~$1,505/kW). 
           Country standouts include Brazil ($1,079/kW) and the UK ($1,273/kW).
         - Solar PV: Exceptional declines of ~−88% in India (South Asia’s only reporting country, ~$711/kW) 
           and ~−88% in Australia (~$989/kW). Southern Europe also showed ~−88% decline 
           with an average of ~$710/kW and the lowest national cost in Greece ($626/kW).

      Country-Level Installed Cost Highlights:
         - Offshore wind: Lowest costs in China ($2,370/kW), Netherlands ($2,564/kW), and Germany ($2,895/kW). 
           Eastern Asia’s regional average remains higher (~$3,950/kW).
         - Onshore wind: Cheapest in China ($986/kW), Brazil ($1,079/kW), and Spain ($1,158/kW).
         - Solar PV: Lowest costs in Greece ($626/kW), Spain ($671/kW), and China ($671/kW)
  
   ------------------------------------------------------------------ */


