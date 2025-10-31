/* ======================================================================
   File    : rq2_capacity_and_performance.sql
   Purpose : Analyze global annual trends for each major renewable technology-
             tracking installed capacity (MW), generation (GWh), and weighted average capacity factor (%).
   Author  : Elene Kikalishvili
   Date    : 2025-06-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 2: How have installed capacity and capacity factors for different renewable technologies changed,
   						and what do these trends reveal about technology adoption and performance?
   ============================================================================================================================ */



/* ================================================================================================
   SECTION 1: QA & Data Exploration - Global and Country Level Renewable Capacity & Performance Datasets 
   
   Goal:
     - Explore coverage, indicators, and granularity of global and country-level renewable data.
     - Validate compatibility between fact tables before aggregation and trend analysis.
   ================================================================================================ */

/* ============================================================================
   SECTION 1A: Global Renewable Performance Data (ren_indicators_global)
   ============================================================================ */

-- DE: Preview sample global data
SELECT *
FROM renewables_project.ren_indicators_global
LIMIT 5;

-- QA: Check technology coverage and year range
SELECT 
    dt.technology, dt.sub_technology, 
    MIN(rig.year) AS start_year,
    MAX(rig.year) AS end_year
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt 
  ON rig.tech_id = dt.tech_id
GROUP BY dt.technology, dt.sub_technology
ORDER BY dt.technology;

-- DE: List available indicators and calculation types
SELECT DISTINCT 
    rig.indicator, 
    rig.value_category
FROM renewables_project.ren_indicators_global rig
ORDER BY rig.indicator, rig.value_category;

/* Notes:
   - Technologies: CSP, Geothermal, Hydropower, Offshore Wind, Onshore Wind, Solar PV
   - Years: 2010-2023
   - Indicators: Total installed cost (USD/kW), Capacity factor (%), LCOE (USD/kWh)
   - Calculations: Weighted average, 5th percentile, 95th percentile
   ---------------------------------------------------------------------- */


/* ============================================================================
   SECTION 1B: Country-Level Renewable Performance Data (ren_indicators_country)
   ============================================================================ */

-- DE: Preview sample country-level data
SELECT *
FROM renewables_project.ren_indicators_country
LIMIT 5;

-- QA: Check available technologies, periods, and years
SELECT 
    dt.technology,
    ric.period,
    MIN(ric.year) AS start_year,
    MAX(ric.year) AS end_year
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt 
  ON ric.tech_id = dt.tech_id
GROUP BY dt.technology, ric.period
ORDER BY dt.technology, ric.period;

-- DE: Verify distinct sub-technologies
SELECT DISTINCT dt.sub_technology
FROM renewables_project.dim_technology dt
JOIN renewables_project.ren_indicators_country ric
  ON ric.tech_id = dt.tech_id;

-- DE: List indicators and calculation types
SELECT DISTINCT 
    ric.indicator, 
    ric.value_category
FROM renewables_project.ren_indicators_country ric
ORDER BY ric.indicator, ric.value_category;

/* QA: Check join coverage with capacity_generation
   Purpose: ensure compatible geo_id/tech_id/year combinations
   (exclude Hydro since its data structure differs)
*/
SELECT COUNT(*) AS matching_records
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt 
  ON ric.tech_id = dt.tech_id
JOIN renewables_project.dim_geo dg 
  ON dg.geo_id = ric.geo_id
JOIN renewables_project.capacity_generation cg 
  ON cg.year = ric.year 
 AND cg.tech_id = ric.tech_id 
 AND cg.geo_id = ric.geo_id
WHERE dt.technology <> 'Hydropower'
  AND ric.indicator = 'Capacity factor (%)'
  AND ric.value_category = 'Weighted average'; -- 676

-- QA: Check Hydropower data completeness
SELECT COUNT(DISTINCT ric.geo_id) AS hydro_country_count
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt 
  ON ric.tech_id = dt.tech_id
WHERE dt.technology = 'Hydropower'
  AND ric.country_value IS NOT NULL; -- 3

/* NOTES:
   - Technologies: Hydropower, Offshore Wind, Onshore Wind, Solar PV
   - Data availability:
       - Offshore/Onshore/Solar PV: country-level 2010-2023 (onshore wind since 1984)
       - Hydropower: region-level + limited country data (3 countries)
   - Hydropower split by project size (Large/Small) - may need aggregation.
   - Indicators: LCOE, Capacity factor (%), Installed cost (USD/kW)
   - Calculations: Weighted average, 5th, 95th percentile
   - Limitation: Not enough country-level data for complete CF analysis.
*/


/* ============================================================================
   SECTION 1C: Reference - Technology Mapping in capacity_generation
   ============================================================================ */

-- QA: Map all technologies and sub-technologies present in capacity_generation
SELECT DISTINCT 
    dt.group_technology, 
    dt.technology, 
    dt.sub_technology
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_technology dt 
  ON cg.tech_id = dt.tech_id
ORDER BY dt.group_technology, dt.technology, dt.sub_technology;



/* ================================================================================================
   SECTION 2: Analyze Global Capacity & Performance Trends by Renewable Technology
   
   Goal:
     - Analyze installed capacity (MW), generation (GWh), and capacity factor (%) for major renewables.
     - Evaluate relative changes since 2010 to understand technology adoption and performance improvements.
   ================================================================================================ */

WITH tech_level AS (
    -- Detailed technologies (onshore/offshore wind, solar PV, CSP, geothermal)
    SELECT
        cg.year,
        dt.technology,
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM(cg.generation_gwh)        AS generation_gwh
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt 
        ON cg.tech_id = dt.tech_id
    WHERE dt.technology IN (
        'Onshore wind energy',
        'Offshore wind energy',
        'Solar photovoltaic',
        'Solar thermal energy', -- capacity_generation data only has CSP
        'Geothermal energy'
    )
    GROUP BY cg.year, dt.technology
),

group_level AS (
    -- Group technologies (Hydropower, Bioenergy)
    SELECT
        cg.year,
        dt.group_technology AS technology,
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM(cg.generation_gwh)        AS generation_gwh
    FROM renewables_project.capacity_generation cg
    JOIN renewables_project.dim_technology dt 
        ON cg.tech_id = dt.tech_id
    WHERE dt.group_technology IN ('Hydropower', 'Bioenergy')
    GROUP BY cg.year, dt.group_technology
),

combined AS (
    SELECT * FROM tech_level
    UNION ALL
    SELECT * FROM group_level
),

-- Get start and end values for CAGR
tech_trends AS (
    SELECT
        technology,
        MAX(CASE WHEN year = 2010 THEN installed_capacity_mw END) AS start_capacity,
        MAX(CASE WHEN year = 2023 THEN installed_capacity_mw END) AS end_capacity,
        MAX(CASE WHEN year = 2010 THEN generation_gwh END) AS start_generation,
        MAX(CASE WHEN year = 2022 THEN generation_gwh END) AS end_generation
    FROM combined
    GROUP BY technology
)

SELECT
    c.year,
    dt.group_technology,
    CASE 
        WHEN dt.technology = 'Solar thermal energy' THEN 'CSP'
        ELSE dt.technology
    END AS technology,
    c.installed_capacity_mw,
    c.generation_gwh,
    ROUND(rig.value, 2) AS capacity_factor_pct,

    -- Relative change since 2010 (for trend visualization)
    ROUND(
        (c.installed_capacity_mw - FIRST_VALUE(c.installed_capacity_mw)
            OVER (PARTITION BY c.technology ORDER BY c.year))
        / NULLIF(FIRST_VALUE(c.installed_capacity_mw)
            OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100, 1
    ) AS rel_change_since_2010_installed_cap,

    ROUND(
        (c.generation_gwh - FIRST_VALUE(c.generation_gwh)
            OVER (PARTITION BY c.technology ORDER BY c.year))
        / NULLIF(FIRST_VALUE(c.generation_gwh)
            OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100, 1
    ) AS rel_change_since_2010_generation,

    ROUND(
        (rig.value - FIRST_VALUE(rig.value)
            OVER (PARTITION BY c.technology ORDER BY c.year))
        / NULLIF(FIRST_VALUE(rig.value)
            OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100, 1
    ) AS rel_change_since_2010_cap_factor,
    
    ROUND(rig.value - FIRST_VALUE(rig.value) OVER (PARTITION BY c.technology ORDER BY c.year), 1) AS pp_change_cap_factor,

    -- CAGR calculations
    ROUND(
        (POWER(tt.end_capacity / NULLIF(tt.start_capacity, 0), 1.0 / (2023 - 2010)) - 1) * 100, 2
    ) AS capacity_cagr_pct,

    ROUND(
        (POWER(tt.end_generation / NULLIF(tt.start_generation, 0), 1.0 / (2022 - 2010)) - 1) * 100, 2
    ) AS generation_cagr_pct

FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt 
    ON rig.tech_id = dt.tech_id
JOIN combined c 
    ON dt.technology = c.technology
   AND c.year = rig.year
JOIN tech_trends tt
    ON tt.technology = c.technology
WHERE rig.indicator = 'Capacity factor (%)'
  AND rig.value_category = 'Weighted average'
ORDER BY c.technology, c.year;
-- Alternative sort options for quick analysis:
-- ORDER BY c.year, rel_change_since_2010_generation DESC;
-- ORDER BY c.year, rel_change_since_2010_cap_factor DESC;
-- ORDER BY c.year, c.installed_capacity_mw DESC;
-- ORDER BY c.year, rel_change_since_2010_installed_cap DESC, technology;
-- ORDER BY c.year, capacity_factor_pct DESC;


/* ------------------------------------------------------------------
   Insights Summary:
   
     Installed Capacity Growth:
	   - Solar PV is the clear global leader, expanding installed capacity by 3,404% (35x) since 2010.
	   - Offshore wind increased 24x, while hydropower grew just by 37% (1.37x).
	   - Hydropower remained the largest installed renewable source until 2022, but by 2023, Solar PV 
	     overtook hydropower to become #1 worldwide.
	   
     Capacity Factor Trends:
	   - Geothermal, bioenergy, and hydropower have consistently high capacity factors, but showed limited improvement.
	   - Solar and wind technologies saw significant gains.
	   - In 2023, Solar thermal energy led with a 79% increase in capacity factor since 2010, followed by
	     onshore wind (+32%), hydropower (+21%), and Solar PV (+17%).
	   
     Electricity Generation:
	   - Solar PV generated almost 40x more electricity in 2022 than in 2010, leading all renewables.
	   - Offshore wind output increased 21x, solar thermal nearly 8x, and onshore wind about 6x.
	   
     Overall:
	   - Solar energy is the top performer among renewables in growth of capacity, output, and capacity factor.
	   - Hydropower still provides the largest global base, but solar and wind are driving the fastest change.
   ------------------------------------------------------------------ */

 