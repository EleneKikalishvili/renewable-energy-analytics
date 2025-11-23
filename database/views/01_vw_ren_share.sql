/* ======================================================================
   File    : 01_ren_share_views.sql
   Purpose : Create core views for Tableau to analyze and visualize trends in renewable energy share globally, regionally, by country, and technology.
   Author  : Elene Kikalishvili
   Date    : 2025-06-21
   ====================================================================== */


/* ============================================================================================================================  
   Research Question 1: How has the share of renewables in global electricity generation, installed capacity and primary energy consumption changed over time?
   ============================================================================================================================ */



/*-----------------------------------------------------------------------------------------------------------------
   View: vw_ren_share_trends
   Purpose: Create a view for Tableau to analyze trends in the share of renewables in global, regional, and country-level
            electricity generation and installed capacity.

   Summary:
     - Coverage: years >= 2000; geo_type in ('Global', 'Country').
     - Measures: RE share of generation (%) and RE share of capacity (%) pivoted to columns.
     - Design: no YoY/cumulative deltas and no ratios in the view (compute in Tableau as needed).
     - Rollups: use [region] and [subregion] columns from countries to build regional trends in Tableau.
     - Enables Tableau dashboards for time-series, bar/line charts, and small-multiple (facet) visualizations.

   Key columns:
     - year
     - geo_id
     - geo_type, region, subregion, country_or_area
     - re_generation_pct
     - re_capacity_pct
     - shortfall_pp  (capacity% - generation%, percentage points; positive = generation lags capacity)

   Data handling:
     - Excludes source Region aggregates by filtering geo_type.
     
   Visualization ideas:
      - Time-series line or area charts for penetration trends (global, regional, or country).
      - Bar/column charts highlighting under- or over-performing regions.
      - Small-multiple charts for regional/country comparisons.
----------------------------------------------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW renewables_project.vw_ren_share_trends AS
WITH filtered AS (
  SELECT
    rs.geo_id,
    dg.geo_type,
    dg.region_name     AS region,
    dg.sub_region_name AS subregion,
    dg.geo_name        AS country_or_area,
    rs.year,
    rs.indicator,
    rs.value::numeric AS value_pct
  FROM renewables_project.ren_share rs
  JOIN renewables_project.dim_geo dg
    ON rs.geo_id = dg.geo_id
  WHERE rs.year >= 2000
    AND dg.geo_type IN ('Global','Country')         -- exclude source Region aggregates and non-standard groups
    AND rs.indicator IN ('RE Generation (%)','RE Capacity (%)')
    AND rs.value IS NOT NULL
),
pivoted AS (
  SELECT
    geo_id,
    geo_type,
    region,
    subregion,
    country_or_area,
    year,
    MAX(CASE WHEN indicator = 'RE Generation (%)' THEN value_pct END) AS re_generation_pct,
    MAX(CASE WHEN indicator = 'RE Capacity (%)'   THEN value_pct END) AS re_capacity_pct
  FROM filtered
  GROUP BY geo_id, geo_type, region, subregion, country_or_area, year
)
SELECT
  year,
  geo_id,
  geo_type,
  region,
  subregion,
  country_or_area,
  re_generation_pct,
  re_capacity_pct,
  CASE
    WHEN re_generation_pct IS NULL OR re_capacity_pct IS NULL THEN NULL
    ELSE (re_capacity_pct - re_generation_pct) -- positive => gen share behind cap share
  END AS shortfall_pp
FROM pivoted;






/*-----------------------------------------------------------------------------------------------------------------
   View: vw_country_ren_capacity_generation_trends
   Purpose: Create a Tableau-ready view of country-level renewable electricity capacity and generation,
            with cumulative % change since each country’s base (first non-null) year for each metric.

   Summary:
      - Provides year-by-year breakdown of installed renewable capacity (MW) and generation (GWh) by country and technology.
      - Calculates each country’s “base year” (first year with non-null data) for both capacity and generation, and measures cumulative % change since then.
      - Enables Tableau analysis of “superstar” countries, technology adoption trajectories, country comparisons across regions, and regional comparisons globally.
      - Supports sorting, highlighting, or filtering by region, subregion, country, and technology.

   Key columns:
      - region, subregion, country
      - geo_id, tech_id
      - technology, year
      - ren_cap_country_mw: Installed renewable capacity (MW)
      - cap_base_year / cap_base_mw: First non-null year/value for capacity (per country/tech)
      - pct_change_since_cap_base_year: % change in capacity since base year
      - ren_gen_country_gwh: Renewable generation (GWh)
      - gen_base_year / gen_base_gwh: First non-null year/value for generation
      - pct_change_since_gen_base_year: % change in generation since base year

   Visualization ideas:
      - Country-level leaderboards and growth curves (“Which countries have grown the fastest in renewables?”)
      - Time-series line or area charts by country or region, coloring by technology.
      - Small-multiple or facet charts to compare countries within a region or subregion.
      - Highlighting first-reporting years for each country to contextualize % change metrics.

----------------------------------------------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW renewables_project.vw_country_ren_capacity_generation_trends AS
WITH base AS (
  SELECT
    dg.region_name      AS region,
    dg.sub_region_name  AS subregion,
    dg.geo_name         AS country,
    cg.geo_id,
    dt.tech_id,
    dt.technology,
    cg.year,
    SUM(cg.installed_capacity_mw) AS ren_cap_country_mw,
    SUM(cg.generation_gwh)        AS ren_gen_country_gwh
  FROM renewables_project.capacity_generation cg
  JOIN renewables_project.dim_geo dg
    ON cg.geo_id = dg.geo_id
  JOIN renewables_project.dim_technology dt
    ON cg.tech_id = dt.tech_id
   AND dt.category = 'Renewable'
  WHERE cg.year >= 2000
    AND dg.geo_type = 'Country'
  GROUP BY dg.region_name, dg.sub_region_name, dg.geo_name, cg.geo_id, dt.tech_id, dt.technology, cg.year
),

-- First non-null capacity year/value per country/tech
cap_base AS (
  SELECT DISTINCT ON (country, technology)
         country, technology, geo_id, tech_id,
         year AS cap_base_year,
         ren_cap_country_mw AS cap_base_mw
  FROM base
  WHERE ren_cap_country_mw IS NOT NULL
  ORDER BY country, technology, year
),

-- First non-null generation year/value per country/tech
gen_base AS (
  SELECT DISTINCT ON (country, technology)
         country, technology, geo_id, tech_id,
         year AS gen_base_year,
         ren_gen_country_gwh AS gen_base_gwh
  FROM base
  WHERE ren_gen_country_gwh IS NOT NULL
  ORDER BY country, technology, year
)
SELECT
  b.region,
  b.subregion,
  b.country,
  b.geo_id,
  b.tech_id,
  b.technology,
  b.year,
  b.ren_cap_country_mw,
  cb.cap_base_year,
  cb.cap_base_mw,
  ROUND( (b.ren_cap_country_mw - cb.cap_base_mw) / NULLIF(cb.cap_base_mw, 0) * 100, 2 ) AS pct_change_since_cap_base_year,
  b.ren_gen_country_gwh,
  gb.gen_base_year,
  gb.gen_base_gwh,
  ROUND( (b.ren_gen_country_gwh - gb.gen_base_gwh) / NULLIF(gb.gen_base_gwh, 0) * 100, 2 ) AS pct_change_since_gen_base_year
FROM base b
LEFT JOIN cap_base cb
  ON b.country = cb.country
 AND b.technology = cb.technology
LEFT JOIN gen_base gb
  ON b.country = gb.country
 AND b.technology = gb.technology;  






/*-----------------------------------------------------------------------------------------------------------------
   View: vw_primary_consumption_core
   Purpose: Create a Tableau-ready core view of primary energy consumption (EJ) and renewable
            consumption by technology at the **country grain**, with region/subregion fields for rollups.

   Summary:
      - Coverage: Years ≥ 2000. Includes **Country** rows and stand-alone **Region “area” rows**
        (not rollups; used by the source where country detail is absent). Excludes **Economic group**
        and **Residual/unallocated** aggregates to preserve standardized geography.
      - Measures: Country/year **total primary consumption (EJ)**, country/year **total renewables (EJ, excl. Nuclear)**,
        and **per-technology renewable consumption (EJ)**.
      - Design: No precomputed percentages or global totals; intended for **filter-aware** FIXED LOD
        calculations in Tableau (e.g., % of global, renewables share, tech share of renewables).
      - Use cases: Global/regional/subregional comparisons, tech mix composition, country drill-downs,
        and tooltip detail without double counting.

   Key columns:
   	  - year
   	  - geo_id, tech_id, row_type
      - region, subregion, country_or_area 
      - country_primary_consumption_ej: country/year total primary energy (EJ)
      - total_ren_ej: country/year total renewables (EJ, excl. Nuclear)
      - technology: renewable technology label (e.g., Hydro, Wind, Solar, Biofuels, GBO)
      - ren_tech_ej: country/year **per-technology** renewables (EJ)

   Visualization ideas:
      - Stacked area or bars: Renewable **tech mix** by region/subregion/year (sum ren_tech_ej).
      - Lines: **Renewables share of primary** over time (SUM(total_ren_ej) / SUM(country_primary_consumption_ej)).
      - Treemaps or bars: **% of global** by region or subregion (use FIXED LOD over year for the denominator).
      - Tooltips: Show country totals alongside per-tech values without duplication (totals on total rows; tech on tech rows).

----------------------------------------------------------------------------------------------------------------- */


CREATE OR REPLACE VIEW renewables_project.vw_primary_consumption_core AS
WITH country_total AS (
  SELECT dg.region_name, dg.sub_region_name, dg.geo_name, dg.geo_type, pc.geo_id,
         pc.year, pc.value AS country_primary_consumption_ej
  FROM renewables_project.primary_consumption pc
  JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
  WHERE pc.year >= 2000
    AND dg.geo_type IN ('Country','Region')
    AND pc.value IS NOT NULL
),
country_ren_tech AS (
  SELECT dg.region_name, dg.sub_region_name, dg.geo_name, dg.geo_type, rp.geo_id,
         rp.year, dt.technology, dt.tech_id, rp.value AS ren_tech_ej
  FROM renewables_project.ren_primary_consumption rp
  JOIN renewables_project.dim_geo dg ON rp.geo_id = dg.geo_id
  JOIN renewables_project.dim_technology dt ON rp.tech_id = dt.tech_id
  WHERE rp.year >= 2000
    AND dg.geo_type IN ('Country','Region')
    AND rp.value IS NOT NULL
    AND dt.technology <> 'Nuclear'
),
ren_totals AS (
  SELECT region_name, sub_region_name, geo_name, year,
         SUM(ren_tech_ej) AS total_ren_ej
  FROM country_ren_tech
  GROUP BY region_name, sub_region_name, geo_name, year
)

-- 1) TOTAL row per country-year (no technology)
SELECT
  ct.year,
  ct.region_name     AS region,
  ct.sub_region_name AS subregion,
  ct.geo_name        AS country_or_area,
  ct.geo_type,
  ct.geo_id,
  'TOTAL'::text      AS row_type,
  ct.country_primary_consumption_ej,
  rt.total_ren_ej,
  NULL::text         AS technology,
  NULL::integer       AS tech_id,
  NULL::numeric      AS ren_tech_ej
FROM country_total ct
LEFT JOIN ren_totals rt
  ON ct.region_name=rt.region_name
 AND ct.geo_name=rt.geo_name
 AND ct.year=rt.year

UNION ALL

-- 2) TECHNOLOGY rows per country-year-tech (totals are NULL here)
SELECT
  r.year,
  r.region_name      AS region,
  r.sub_region_name  AS subregion,
  r.geo_name         AS country_or_area,
  r.geo_type,
  r.geo_id,
  'TECH'::text       AS row_type,
  NULL::numeric      AS country_primary_consumption_ej,
  NULL::numeric      AS total_ren_ej,
  r.technology,
  r.tech_id,
  r.ren_tech_ej
FROM country_ren_tech r;


























    
    
    




