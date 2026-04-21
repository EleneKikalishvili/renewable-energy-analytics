/* ======================================================================
   File    : rq1_global_renewables_share.sql
   Purpose : Analyze the share of renewables in global electricity generation, capacity, and primary energy consumption over time.
   Author  : Elene Kikalishvili
   Date    : 2025-06-18
   ====================================================================== */

/* ===========================================================================================================================================================  
   Research Question 1: How has the share of renewables in global electricity generation, installed capacity and primary energy consumption changed over time?
   =========================================================================================================================================================== */



/* ================================================================================================
   SECTION 1: Renewable Share Analysis (% of Generation and Capacity) from ren_share
   ================================================================================================ */

/* ============================================================================
   SECTION 1A: QA & Data Exploration
   
   Goal: 
   		Understand data granularity, indicators, and geographic tagging logic
   ============================================================================ */

-- DE: Preview ren_share sample rows
SELECT * 
FROM renewables_project.ren_share 
LIMIT 5;

-- DE: Check geo_type breakdown (Global, Country, Region, etc.)
SELECT DISTINCT dg.geo_type
FROM renewables_project.ren_share rs
JOIN renewables_project.dim_geo dg 
  ON rs.geo_id = dg.geo_id;

-- QA: Inspect residual/unallocated region labels (e.g., Other Middle East)
SELECT DISTINCT dg.geo_type, dg.geo_name
FROM renewables_project.ren_share rs
JOIN renewables_project.dim_geo dg 
  ON rs.geo_id = dg.geo_id
WHERE dg.geo_type = 'Residual/unallocated';

-- DE: List all geo_name entries linked to ren_share
SELECT DISTINCT dg.geo_name
FROM renewables_project.ren_share rs
JOIN renewables_project.dim_geo dg 
  ON rs.geo_id = dg.geo_id;

-- DE: View available indicators (should include RE Generation % and Capacity %)
SELECT DISTINCT indicator
FROM renewables_project.ren_share;

-- QA: Check row count
SELECT count(*) -- 11,184
FROM renewables_project.ren_share;

-- QA: Ensure no row loss during joins
SELECT count(*) -- 11,184
FROM
	renewables_project.ren_share rs 
	JOIN renewables_project.dim_geo dg
	ON rs.geo_id = dg.geo_id;

-- QA: indicator presence by geo_type (quick completeness scan)
SELECT 
  rs.indicator,
  dg.geo_type,
  COUNT(*) AS n_rows
FROM renewables_project.ren_share rs
JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
GROUP BY rs.indicator, dg.geo_type
ORDER BY rs.indicator, dg.geo_type;


/* ------------------------------------------------------------------ 
 * === Notes on Geography Standardization ===
   - This table has global, region and country granularity, also has Residual/unallocated geo type.
   - "Middle East" is classified as Residual/unallocated because it is not a UN-standard region.
   - Countries that were originally assigned "Middle East" were manually remapped to standard regions.
   - Region-level rows in this dataset are aggregates and will not be used for regional analysis.
     Instead, regional insights will be computed by aggregating country-level data using standardized subregions.
   - Global analysis will use rows tagged as geo_type = 'Global' (not summed from country-level).
   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 1B: Analyze Renewable Electricity Share - Global and Country-Level Trends
   ================================================================================================ */

/* ============================================================================
   Query 1: Global renewables share in electricity generation and installed capacity
   ============================================================================ */

WITH base AS (
  SELECT
    rs.year,
    AVG(rs.value) FILTER (WHERE rs.indicator = 'RE Generation (%)') AS re_generation_pct,
    AVG(rs.value) FILTER (WHERE rs.indicator = 'RE Capacity (%)') AS re_capacity_pct
  FROM renewables_project.ren_share rs
  JOIN renewables_project.dim_geo dg
    ON rs.geo_id = dg.geo_id
  WHERE dg.geo_type = 'Global'
    AND rs.indicator IN ('RE Generation (%)','RE Capacity (%)')
  GROUP BY rs.year
),
final AS (
  SELECT
    year,
    re_generation_pct,
    re_capacity_pct,
    -- "Effectiveness" of capacity: gen% vs cap%
    (re_capacity_pct - re_generation_pct) AS gap_pp,
    -- Since-2000 changes (use first observed value in the series)
    (re_generation_pct - FIRST_VALUE(re_generation_pct) OVER (ORDER BY year))                     AS abs_change_since_2000_gen_pp,
    (re_capacity_pct   - FIRST_VALUE(re_capacity_pct)   OVER (ORDER BY year))                     AS abs_change_since_2000_cap_pp,
    100.0 * (re_generation_pct - FIRST_VALUE(re_generation_pct) OVER (ORDER BY year))
          / NULLIF(FIRST_VALUE(re_generation_pct) OVER (ORDER BY year), 0)                        AS rel_change_since_2000_gen_pct,
    100.0 * (re_capacity_pct   - FIRST_VALUE(re_capacity_pct)   OVER (ORDER BY year))
          / NULLIF(FIRST_VALUE(re_capacity_pct)   OVER (ORDER BY year), 0)                        AS rel_change_since_2000_cap_pct
  FROM base
)
SELECT
  year,
  ROUND(re_generation_pct, 2)				AS re_generation_pct,
  ROUND(abs_change_since_2000_gen_pp, 2)	AS abs_change_since_2000_generation_pp,
  ROUND(rel_change_since_2000_gen_pct, 2)	AS rel_change_since_2000_generation_pct,
  ROUND(re_capacity_pct, 2)	    			AS re_capacity_pct,
  ROUND(abs_change_since_2000_cap_pp, 2)	AS abs_change_since_2000_capacity_pp,
  ROUND(rel_change_since_2000_cap_pct, 2)	AS rel_change_since_2000_capacity_pct,
  ROUND(gap_pp, 2) 							AS gap_pp
FROM final
ORDER BY year;  


/* ------------------------------------------------------------------ 
 * Insights Summary:
 
   - Renewables’ share of electricity generation rose from 18.3% (2000) to 29.9% (2023): +11.6 pp (~+63% relative).
   - Renewables’ share of installed capacity doubled from 22% (2000) to 43% (2023): +21 pp (+95.6% relative).
   - Installed capacity is outpacing generation: the gap widened from 3.7 pp (2000) to 13.2 pp (2023),
     reflecting the rapid build-out of solar/wind (lower average capacity factors) and integration needs (grid/storage).
   ------------------------------------------------------------------ */



/* ============================================================================
   Query 2: Top 50 countries by renewables share of generation
   ============================================================================ */ 

SELECT
	dg.geo_name AS country,
	rs."year",
	rs.value AS re_generation_pct
FROM
	renewables_project.ren_share rs 
	JOIN renewables_project.dim_geo dg
	ON rs.geo_id = dg.geo_id
WHERE
	rs.value IS NOT NULL
	AND dg.geo_type = 'Country'
	AND rs."indicator" = 'RE Generation (%)'
	AND rs.year = (
	    SELECT MAX(year)
	    FROM renewables_project.ren_share
	    WHERE
	    	value IS NOT NULL
	    	AND indicator = 'RE Generation (%)'
	    	AND geo_id IN (SELECT geo_id FROM renewables_project.dim_geo WHERE geo_type = 'Country')
	)
ORDER BY re_generation_pct DESC
LIMIT 50;


/* ============================================================================
   Query 3: Threshold breakdown: RE generation % among top 50 countries (2022) 
   ============================================================================ */ 
SELECT
  COUNT(*) FILTER (WHERE value >= 60 AND value < 70)   AS ge_60_70_pct,
  COUNT(*) FILTER (WHERE value >= 70 AND value < 80)   AS ge_70_80_pct,
  COUNT(*) FILTER (WHERE value >= 80 AND value < 90)   AS ge_80_90_pct,
  COUNT(*) FILTER (WHERE value >= 90 AND value < 100)  AS ge_90_100_pct,
  COUNT(*) FILTER (WHERE value = 100)                  AS full_100_pct
FROM (
	SELECT
		rs.value 
	FROM
		renewables_project.ren_share rs 
		JOIN renewables_project.dim_geo dg
		ON rs.geo_id = dg.geo_id
	WHERE
		rs.value IS NOT NULL
		AND dg.geo_type = 'Country'
		AND rs."indicator" = 'RE Generation (%)'
		AND rs.year = 2022
	ORDER BY value DESC
	LIMIT 50
) AS top_50;

/* ------------------------------------------------------------------  
 * Insights Summary:
 
   - Among the top 50, RE generation share ranges from 65% to 100%.
   - 6 countries/territories report 100% RE: Nepal, Bhutan, Iceland, Albania, Ethiopia, Paraguay.
   - Distribution:
        - 100%: 6
        - 90–99.9%: 13
        - 80–89.9%: 10
        - 70–79.9%: 18
        - 60–69.9%: 3
   - Median RE share within top 50: 87.6%
   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 2: Installed Capacity & Generation Analysis (MW, GWh) from capacity_generation
   ================================================================================================*/

/* ============================================================================
   SECTION 2A: QA & Data Exploration
   
   Goal: 
   		Explore and validate the contents of the capacity_generation table to ensure
        readiness for analysis.
   ============================================================================ */

-- DE: Sample 5 rows
SELECT * 
FROM renewables_project.capacity_generation cg 
LIMIT 5;

-- DE: Validate geo_type values: only country-level records should be present
SELECT DISTINCT geo_type
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id;

-- DE: Explore available renewable sub-technologies by group
SELECT DISTINCT dt.group_technology, dt.technology, dt.sub_technology 
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id 
--WHERE dt.group_technology = 'Wind energy'
--WHERE dt.group_technology = 'Hydropower'
--WHERE dt.group_technology = 'Solar energy'
ORDER BY dt.group_technology, dt.technology;

-- QA: Validate total row count (39,958 expected)
SELECT COUNT(*) 
FROM renewables_project.capacity_generation;

-- QA: Confirm same row count after geo join (sanity check)
SELECT COUNT(*) 
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id;


-- QA: Cross-check renewable generation % calculation with pre-calculated value in ren_share
-- Ensures capacity_generation data aligns with ren_share logic
SELECT
    dg.geo_name AS country,
    cg.year,
    dt.category,
    dt.sub_technology,
    cg.producer_type,
    cg.generation_gwh,
    
    -- Manually calculated RE % share from capacity_generation
    ROUND(
        SUM(CASE WHEN dt.category = 'Renewable' THEN cg.generation_gwh ELSE 0 END) OVER (PARTITION BY cg.geo_id, cg.year)
        / NULLIF(SUM(cg.generation_gwh) OVER (PARTITION BY cg.geo_id, cg.year), 0) * 100, 2
    ) AS re_generation_pct_calc,

    -- Value from ren_share (pre-calculated)
    rs.value AS re_generation_pct
FROM renewables_project.ren_share rs 
JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
JOIN renewables_project.capacity_generation cg ON rs.geo_id = cg.geo_id AND rs.year = cg.year
JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
WHERE rs.value IS NOT NULL
  AND cg.generation_gwh IS NOT NULL
  AND dg.geo_type = 'Country'
  AND rs.indicator = 'RE Generation (%)'
  AND rs.year = (
    SELECT MAX(year)
    FROM renewables_project.ren_share
    WHERE value IS NOT NULL
      AND indicator = 'RE Generation (%)'
      AND geo_id IN (SELECT geo_id FROM renewables_project.dim_geo WHERE geo_type = 'Country')
  )
GROUP BY cg.geo_id, dg.geo_name, cg.year, dt.category, dt.sub_technology, cg.producer_type, cg.generation_gwh, rs.value
ORDER BY re_generation_pct DESC, country ASC, cg.generation_gwh DESC;

/*
 * Consistency confirmed: capacity_generation data correctly matches calculated RE generation shares from ren_share.
 */



/* ================================================================================================
   SECTION 2B: Analyze Most widely deployed renewable technologies globally
   ================================================================================================ */

/* ============================================================================
   Query 1: Top technologies used by top 50 countries (RE Generation %)
   ============================================================================ */

-- Identify the most commonly used renewable technologies in countries with the highest
-- renewable electricity generation share in 2022.

WITH top_countries AS (
    SELECT rs.geo_id, dg.geo_name AS country, rs."year", rs.value AS re_generation_pct
    FROM renewables_project.ren_share rs 
    JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
    WHERE rs.value IS NOT NULL
      AND dg.geo_type = 'Country'
      AND rs.indicator = 'RE Generation (%)'
      AND rs.year = 2022
    ORDER BY re_generation_pct DESC
    LIMIT 50
)
SELECT
    dt.technology,
    SUM(cg.generation_gwh) AS total_renewable_generation_gwh,
    ROUND(SUM(cg.generation_gwh) * 100.0 / SUM(SUM(cg.generation_gwh)) OVER (), 2) AS pct_of_top50_total
FROM top_countries tc
JOIN renewables_project.capacity_generation cg ON tc.geo_id = cg.geo_id
JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
WHERE cg."year" = tc."year" AND dt.category = 'Renewable'
GROUP BY dt.technology
ORDER BY total_renewable_generation_gwh DESC;

/* ------------------------------------------------------------------
   Insights Summary:
   
   Top 5 renewable technologies used by top 50 countries by highest share of renewable electricity generation:
     - Hydropower: 80.25%
     - Onshore wind: 10.16%
     - Solid biofuels: 4.74%
     - Solar PV: 2.63%
     - Geothermal: 1.22%
   ------------------------------------------------------------------ */


/* ============================================================================
   Query 2: Energy Generation Sources In Top-50 RE-share Countries.
   ============================================================================ */

WITH top_countries AS (
    SELECT rs.geo_id, dg.geo_name AS country, rs."year", rs.value AS re_generation_pct
    FROM renewables_project.ren_share rs 
    JOIN renewables_project.dim_geo dg ON rs.geo_id = dg.geo_id
    WHERE rs.value IS NOT NULL
      AND dg.geo_type = 'Country'
      AND rs.indicator = 'RE Generation (%)'
      AND rs.year = 2022
    ORDER BY re_generation_pct DESC
    LIMIT 50
)
SELECT
    dt.technology,
    SUM(cg.generation_gwh) AS total_generation_gwh
FROM top_countries tc
JOIN renewables_project.capacity_generation cg ON tc.geo_id = cg.geo_id
JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
WHERE cg."year" = tc."year"
GROUP BY dt.technology
ORDER BY total_generation_gwh DESC;

/* ------------------------------------------------------------------ 
   Insights Summary:
   
	- Top 50 countries by RE share still rely heavily on hydro - ~1558.3 TWh (~80% of renewable generation).
   	- Next largest sources: 
   			onshore wind (~197.3 TWh), natural gas (~192.7 TWh), nuclear (~153.7 TWh),
	        solid biofuels (~92 TWh), coal/peat (~74 TWh), solar PV (~51 TWh), and oil (~39.6 TWh).
	- Fossil + nuclear output still exceeds all non-hydro renewables combined.
   ------------------------------------------------------------------ */


/* ============================================================================
   Query 3: Geographic Spread of Renewable Technologies
   ============================================================================ */

-- Examine how widely each renewable technology is adopted globally.
WITH base AS (
    SELECT
        cg.year, dt.technology, dg.sub_region_name, dg.geo_id, dg.geo_name
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
    WHERE dt.category = 'Renewable'
      AND cg.installed_capacity_mw IS NOT NULL AND cg.installed_capacity_mw > 0  
)
SELECT
    year,
    technology,
    COUNT(DISTINCT geo_id) AS number_of_countries,
    COUNT(DISTINCT sub_region_name) AS number_of_subregions
FROM base
GROUP BY year, technology
ORDER BY year DESC, number_of_countries DESC, technology;


/* ============================================================================
   Query 4: Global Adoption Growth by Renewable Technology 2000 vs 2023
   ============================================================================ */

WITH base AS (
    SELECT cg.year, dt.group_technology, dt.technology, dg.geo_id
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
    WHERE dt.category = 'Renewable'
      AND cg.year IN (2000, 2023)
      AND cg.installed_capacity_mw IS NOT NULL
      AND cg.installed_capacity_mw > 0           
)
SELECT
    group_technology,
    technology,
    COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000) AS countries_2000,
    COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023) AS countries_2023,
    COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023) -
    COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000) AS change_count,
    ROUND(
        100.0 * (
            COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023) -
            COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000)
        ) / NULLIF(COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000), 0), 2
    ) AS growth_pct
FROM base
GROUP BY group_technology, technology
ORDER BY countries_2023 DESC, technology;

/* ------------------------------------------------------------------ 
   Insights Summary:
   
	   - Hydropower is nearly saturated globally: present in all 17 subregions since 2000; country count rose slightly (158 -> 163).
	   - Onshore wind (60 -> 156) and solar PV (52 -> 220) achieved full subregional spread by 2012-2013.
	   - Niche/resource-limited techs remain geographically sparse by 2023:
	      - Offshore wind: 3 -> 19 countries, 6/17 subregions
	      - Geothermal: 22 -> 30 countries, 12/17 subregions
	      - CSP: 1 -> 19 countries, 11/17 subregions
	      - Marine: 6 -> 14 countries, 9/17 subregions
	   - Bioenergy is broad but uneven:
	      - Solid biofuels: 86 -> 119 countries, 15/17 subregions
	      - Biogas: 33 -> 107 countries, 15/17 subregions
	      - Waste: 24 -> 48 countries, 11/17 subregions
	      - Liquid biofuels: 2 -> 24 countries, 10/17 subregions
   ------------------------------------------------------------------ */


/* ============================================================================
   Query 5: Regional Deployment Snapshot (2023)
   ============================================================================ */

-- Analyze 2023 renewable capacity deployment by subregion and top technologies.
WITH regional_tech AS (
    SELECT
        dg.sub_region_name AS subregion,
        cg."year",
        dt.technology,
        SUM(cg.installed_capacity_mw) AS ren_capacity_mw
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
        JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id AND dt.category = 'Renewable'
    GROUP BY
        dg.sub_region_name, cg."year", dt.technology
)
SELECT
    subregion,
    "year",
    technology,
    -- Regional Total in a year
    SUM(ren_capacity_mw) OVER (PARTITION BY subregion, "year") AS total_cap_mw_region_year,
    
    -- Regional total per technology in a year
    ren_capacity_mw,
    
     -- % share of each technology in a regional total
    ROUND(
    	ren_capacity_mw / 
    	NULLIF(SUM(ren_capacity_mw) OVER (PARTITION BY subregion, "year"), 0) * 100, 2) AS pct_cap_region_by_tech,
    
    -- Global totals per year
    SUM(ren_capacity_mw) OVER (PARTITION BY "year") AS total_cap_mw_global_year,
    
    -- Region's share of global total (capacity)
    ROUND(
      SUM(ren_capacity_mw) OVER (PARTITION BY subregion, "year") /
      NULLIF(SUM(ren_capacity_mw) OVER (PARTITION BY "year"), 0) * 100, 2
    ) AS pct_of_global_cap_this_region

FROM
    regional_tech
WHERE year = 2023  
-- year = 2000
ORDER BY
   -- "year", pct_of_global_cap_this_region DESC, aubregion, ren_capacity_mw DESC;
    "year" DESC, pct_of_global_cap_this_region DESC, subregion, ren_capacity_mw DESC;

/* ------------------------------------------------------------------ 
   Insights Summary:
   
	-  In 2000, Northern America (21.6%), Latin America and the Caribbean (17.9%), and Eastern Asia (14.1%) led global renewables - each >80% hydro-based.
	-  By 2023, Eastern Asia surged to 42.3% of global capacity (Solar PV 44.8%, Wind 25.3%, Hydro 24.6%).
	-  Northern America dropped to 12.8%, with a more balanced mix: Wind 33.2%, Hydro 31.5%, Solar 29.2%.
	-  Latin America and the Caribbean held 8.9%, still hydro-dominated (58.8%) but with growing Solar (19.2%) and Wind (14.5%).
	-  Key shift: Asia replaced the Americas as the dominant region for renewable deployment.
   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 3: Primary Energy Consumption Analysis from primary_consumption and ren_primary_consumption
   ================================================================================================ */

/* ============================================================================
   SECTION 3A: QA & Data Exploration & Geography Modeling
   
   Goal: 
   		Explore data structure, assess geography coverage, reconcile global totals, and define modeling rules.
   ============================================================================*/

-- DE: Geo type check for total and renewables consumption tables
SELECT DISTINCT geo_type, geo_name, region_name
FROM renewables_project.primary_consumption pc
JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id;

SELECT DISTINCT geo_type
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id;

-- DE: Non-standard geo_type rows (for exclusion from standard regional analysis)
SELECT DISTINCT geo_type, geo_name, sub_region_name 
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id
WHERE dg.geo_type NOT IN ('Country', 'Global', 'Economic_group');

/* 
Note: Region-type records in this dataset are not aggregates of countries but standalone subregion values
(e.g., Eastern Africa, Other Europe). These are included in standardized regional totals.

Excluded from analysis:
  - Economic groups (e.g., OECD, EU)
  - Residual/unallocated rows (e.g., "Other CIS", "Other Middle East")
*/


-- QA: Data coverage check
-- Null counts in total and renewable primary energy tables
SELECT COUNT(*) FROM renewables_project.primary_consumption WHERE year >= 2000 AND value IS NULL;  -- 24
SELECT COUNT(*) FROM renewables_project.ren_primary_consumption WHERE year >= 2000 AND value IS NULL; -- 3,290

-- QA: Year coverage
SELECT MAX(year) FROM renewables_project.primary_consumption;           -- 2023
SELECT MAX(year) FROM renewables_project.ren_primary_consumption;       -- 2023


-- QA: Technology breakdown
SELECT DISTINCT dt.technology
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_technology dt ON rpc.tech_id = dt.tech_id;

/*
Technologies in renewable primary energy data:
  - Biofuels
  - Wind energy
  - Geothermal, Biomass, Other
  - Solar energy
  - Hydropower
  - Nuclear (excluded from renewables analysis)
*/


/* ============================================================================
   QA: GLOBAL TOTAL CHECK - Standardized (Countries and regions) vs Source Global

   Goal: Ensure Tableau visuals use consistent, filter-aware global totals by summing country + region data only.
         Compare this with source-provided 'Global' row (includes residuals like "Other CIS").

   Result: Alignment within ~1–2% across years. Optional: residual add-back to close gap.
   ============================================================================ */

WITH base AS (
  SELECT 'primary' AS metric, pc.year, pc.value, dg.geo_type, dg.geo_name
  FROM renewables_project.primary_consumption pc
  JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
  WHERE pc.year >= 2000

  UNION ALL

  SELECT 'renewables' AS metric, rp.year, rp.value, dg.geo_type, dg.geo_name
  FROM renewables_project.ren_primary_consumption rp
  JOIN renewables_project.dim_geo dg ON rp.geo_id = dg.geo_id
  JOIN renewables_project.dim_technology dt ON rp.tech_id = dt.tech_id
  WHERE rp.year >= 2000 AND dt.technology <> 'Nuclear'
),

standardized AS (
  SELECT metric, year, SUM(value) AS global_standardized_ej
  FROM base
  WHERE geo_type IN ('Country', 'Region')
  GROUP BY metric, year
),

residual_addback AS (
  SELECT metric, year, SUM(value) AS other_residual_ej
  FROM base
  WHERE geo_type = 'Residual/unallocated'
  GROUP BY metric, year
),

source_global AS (
  SELECT metric, year, SUM(value) AS global_source_row_ej
  FROM base
  WHERE geo_type = 'Global'
  GROUP BY metric, year
)

SELECT
  s.metric,
  s.year,
  s.global_standardized_ej,
  COALESCE(r.other_residual_ej, 0) AS other_residual_ej,
  (s.global_standardized_ej + COALESCE(r.other_residual_ej, 0)) AS global_source_aligned_ej,
  sg.global_source_row_ej,
  ROUND(100.0 * ((s.global_standardized_ej + COALESCE(r.other_residual_ej, 0)) - sg.global_source_row_ej)
        / NULLIF(sg.global_source_row_ej, 0), 4) AS summed_vs_source_diff_pct, -- shows if there is difference after residual and standardized are summed.
  ROUND(100.0 * (sg.global_source_row_ej - s.global_standardized_ej)
        / NULLIF(sg.global_source_row_ej, 0), 4) AS standard_vs_source_diff_pct -- shows difference between source global AND standardized global numbers without adding residuals.
FROM standardized s
LEFT JOIN residual_addback r ON r.metric = s.metric AND r.year = s.year
LEFT JOIN source_global sg   ON sg.metric = s.metric AND sg.year = s.year
--ORDER BY s.metric, s.year;
ORDER BY standard_vs_source_diff DESC;

/* ----------------------------------------------------------------------------------------------------------
   GEOGRAPHY MODELING - Implementation Notes 
   (applies to: primary_consumption, ren_primary_consumption)

   Included in Regional Analysis:
     - Countries and standard regions (geo_type IN ('Country', 'Region'))
     - Region-type rows represent reported area-level totals (e.g., "Western Europe", "Eastern Africa") 
       and are NOT aggregates of country-level data.

   Excluded from Regional Analysis:
     - Economic groups (e.g., OECD, EU) — cross-regional aggregates not used in trend comparisons.
     - Residual/unallocated areas (e.g., "Other CIS", "Other Asia Pacific") — unmapped or partial records 
       excluded from standardized regional totals.

   Global Totals Strategy:
     - Global analysis includes rows with geo_type = 'Global' (pre-aggregated totals).
     - Regional and subregional analyses use geo_type IN ('Country', 'Region').
     - Excluding residual/unallocated rows may create a minor difference (~1-2%) between 
       standardized and source-provided global totals, which is acceptable for analytical consistency.

  ---------------------------------------------------------------------------------------------------------- */



/* ================================================================================================
   SECTION 3B: Analyze Global Renewable Share of Primary Energy Consumption and technology mix
   ================================================================================================ */

/* ============================================================================
   Query 1: Global Primary Energy Consumption Trends (2000–2023)
   ============================================================================ */

-- What % of total primary energy consumption is renewable each year?
WITH base AS (
    SELECT
        t.year,
        t.total_primary_consumption_ej,
        r.total_ren_primary_consumption_ej,
        ROUND(100.0 * r.total_ren_primary_consumption_ej / NULLIF(t.total_primary_consumption_ej, 0), 2) AS ren_share_pct
    FROM (
        SELECT
            year,
            value AS total_primary_consumption_ej
        FROM renewables_project.primary_consumption pc
        JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
        WHERE year >= 2000 AND dg.geo_type = 'Global'
    ) t
    JOIN (
        SELECT
            rpc.year,
            SUM(rpc.value) AS total_ren_primary_consumption_ej
        FROM renewables_project.ren_primary_consumption rpc
        JOIN renewables_project.dim_technology dt ON rpc.tech_id = dt.tech_id
        JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id
        WHERE rpc.year >= 2000 AND dt.technology <> 'Nuclear' AND dg.geo_type = 'Global'
        GROUP BY rpc.year
    ) r ON t.year = r.year
)
SELECT
    year,
    total_primary_consumption_ej,
    total_ren_primary_consumption_ej,
    ren_share_pct,
    -- YoY growth in share (percentage points)
    ROUND(ren_share_pct - LAG(ren_share_pct) OVER (ORDER BY year), 2) AS yoy_share_pct_point_change
FROM base
ORDER BY year;

/* ---------------------------------------------------------------
   Insights Summary:

   - Renewables’ share in global primary energy grew from ~7.8% (2000) 
     to 14.6% (2023) - a near doubling in two decades.
   - Growth was slow until 2011, then accelerated steadily; the largest
     yearly increase occurred in 2020 (+1.17 pp).
   - In 2023, renewables supplied ~90 EJ of 620 EJ total primary energy 
     (~1/7 of global demand), signaling major progress yet large 
     remaining dependence on fossil fuels.

   Note: Global values are reliable; some regional data remain incomplete.
---------------------------------------------------------------- */


/* ============================================================================
   Query 2: Evolution of Renewable Primary Energy Mix (2000–2023)
   ============================================================================ */

-- Technology breakdown of renewable primary energy consumption (Global, by year)
SELECT
    rpc.year,
    dt.technology,
    SUM(value) AS ren_primary_consumption_ej,
    ROUND( 
        100.0 * SUM(value) / NULLIF(SUM(SUM(value)) OVER (PARTITION BY year), 0),
        2
    ) AS pct_share_of_year
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_technology dt ON rpc.tech_id = dt.tech_id
JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id
WHERE rpc.year >= 2000 AND dt.technology <> 'Nuclear' AND dg.geo_type = 'Global'
GROUP BY rpc.year, dt.technology
ORDER BY rpc.year, pct_share_of_year DESC;

/* ----------------------------------------------------------------------
   Insights Summary:

   - Hydropower’s dominance declined from 90.7% (2000) to 43.9% (2023).
   - Wind and solar surged: Wind grew from 1.1% -> 24.1%, Solar from 0.04% -> 17.0%.
   - Together, wind + solar now make up over 41% of global renewable primary use.
   - Biofuels (5.3%) and Geothermal/Biomass/Other (9.7%) grew moderately.
   - The mix reflects global shift toward modern renewables, driven by falling 
     costs and supportive policy, especially in the power sector.
---------------------------------------------------------------------- */


/* ============================================================================
   Query 3: Primary Energy Consumption & Renewables by Subregion (2023)
   ============================================================================ */

-- Which regions have the highest renewable share of primary energy?
WITH subregional_total AS (
    SELECT
        dg.region_name,
        dg.sub_region_name AS subregion,
        pc.year,
        SUM(pc.value) AS total_primary_consumption_ej
    FROM renewables_project.primary_consumption pc
    JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
    WHERE pc.year = 2023 AND dg.geo_type IN ('Country', 'Region')
    GROUP BY dg.region_name, dg.sub_region_name, pc.year
),
global AS (
    SELECT year, SUM(total_primary_consumption_ej) AS global_total_ej
    FROM subregional_total GROUP BY year
),
renew AS (
    SELECT
        dg.sub_region_name AS subregion,
        rp.year,
        dt.technology,
        SUM(rp.value) AS ren_primary_consumption_ej
    FROM renewables_project.ren_primary_consumption rp
    JOIN renewables_project.dim_geo dg ON rp.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON rp.tech_id = dt.tech_id
    WHERE rp.year = 2023 AND dt.technology <> 'Nuclear' AND dg.geo_type IN ('Country', 'Region')
    GROUP BY dg.sub_region_name, rp.year, dt.technology
),
renew_total AS (
    SELECT subregion, year, SUM(ren_primary_consumption_ej) AS total_ren_primary_consumption_ej
    FROM renew GROUP BY subregion, year
)
SELECT
    st.subregion,
    ROUND(st.total_primary_consumption_ej, 2) AS total_primary_consumption_ej,
    ROUND(100.0 * st.total_primary_consumption_ej / NULLIF(g.global_total_ej, 0), 2) AS reg_pct_of_global,
    ROUND(100.0 * rt.total_ren_primary_consumption_ej / NULLIF(st.total_primary_consumption_ej, 0), 2) AS ren_share_pct,
    r.technology,
    ROUND(100.0 * r.ren_primary_consumption_ej / NULLIF(rt.total_ren_primary_consumption_ej, 0), 2) AS tech_share_of_renewables
FROM subregional_total st
JOIN global g ON st.year = g.year
JOIN renew_total rt ON st.subregion = rt.subregion AND st.year = rt.year
JOIN renew r ON st.subregion = r.subregion AND st.year = r.year
ORDER BY st.total_primary_consumption_ej DESC, tech_share_of_renewables DESC;
--ORDER BY reg_pct_of_global, tech_share_of_renewables DESC;
--ORDER BY ren_share_pct DESC, tech_share_of_renewables DESC;

/* ------------------------------------------------------------------ 
   Insights Summary:

1. High Energy Use, Low Renewable Share:
   - Eastern Asia (206 EJ, 33.3% of global) -> 14.9% renewables.
   - Northern America (108 EJ, 17.5%) -> 13.9%.
   - Other fossil-heavy high-demand regions: 
     Southern Asia (9.3%) -> 7.9%, 
     Eastern Europe (7.1%) -> 7.5%, 
     Western Asia (5.8%) -> 4.9%.

2. Leaders in Renewable Penetration:
   - Northern Europe: 35.6% renewables (2.3% of global energy), led by hydro (44%), wind (33%), and geothermal/biomass/other (16%).
   - Latin America & Caribbean: 29.7% renewables, mainly hydro (61%) + wind (12%) + diversified mix (~9% each).
   - Other high-share regions:
     - Southern Europe: 23.1%, wind-led (32% of renewables).
     - Western Europe: 21.6%, wind-led (38%).
     - Australia & NZ: 18.4%.

3. Fossil-Heavy, Low-Consumption Holdouts:
   - Central Asia (1.1% of global) and Northern Africa (1.4%) -> only 3–4% renewables.
   - Western Asia and Southern Asia also low despite large energy use.

4. Hydropower vs. Diversification:
   - Hydro is still the dominant renewable in many regions, enabling high shares where resources allow.
   - Wind and solar essential for long-term growth - but even diversified regions may lag if fossil use remains high.
  ------------------------------------------------------------------  */



