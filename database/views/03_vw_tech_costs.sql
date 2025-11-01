/* ======================================================================
   File    : 03_tech_costs_view.sql
   Purpose : Create a core view for Tableau to analyze and visualize trends in Levelized Cost of Energy (LCOE) and
             installed costs for renewable technologies, with fossil fuel cost bands for benchmarking.
   Author  : Elene Kikalishvili
   Date    : 2025-06-24
   ====================================================================== */


/* ============================================================================================================================  
   Research Question 3: Which renewable technologies have experienced the largest declines in Levelized Cost of Energy (LCOE) and installed costs?
   ============================================================================================================================ */


/*-----------------------------------------------------------------------------------------------------------------
   View: vw_technology_cost_trends
   Purpose: Create a view for Tableau to analyze trends in the Levelized Cost of Energy (LCOE) and installed costs
            for each renewable technology over time, benchmarked against fossil fuel cost bands.

   Summary:
      - Delivers annual LCOE and installed cost metrics for every major renewable technology, 2010–2023.
      - Adds both year-over-year and cumulative % change (since 2010) for LCOE and installed cost—enabling
        rapid identification of the fastest cost declines.
      - Includes static 2023 fossil fuel high/low cost bands as a visual benchmark for renewable costs.
      - Designed for Tableau dashboards comparing technology cost trends, highlighting cost parity with fossil fuels.

   Key columns:
      - tech_id, technology, year
      - lcoe_usd_per_kwh: LCOE per technology/year (USD/kWh)
      - installed_cost_usd_per_kw: Installed cost per technology/year (USD/kW)
      - rel_change_since_2010_lcoe_pct, rel_change_since_2010_installed_cost_pct: Cumulative % change since 2010
      - fossil_cost_low_usd_per_kwh_2023, fossil_cost_high_usd_per_kwh_2023: 2023 fossil fuel LCOE cost bands

   Visualization ideas:
      - Line or area charts: Cost declines by technology, with fossil benchmarks.
      - Bar charts: 2010 vs 2023 cost comparison for each technology.
      - Tooltips: Show absolute, YoY, and cumulative changes to contextualize each cost trend.

----------------------------------------------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW renewables_project.vw_technology_cost_trends AS
WITH rig_costs AS (
  -- Pull LCOE and installed cost per tech/year in a single row
  SELECT
      rig.tech_id,
      dt.group_technology,
      CASE
  	  	WHEN dt.technology = 'Solar thermal energy' THEN 'Concentrated solar power'::VARCHAR(50)
  	  	ELSE dt.technology
      END AS technology,
      rig.year,
      MAX(CASE WHEN rig.indicator = 'LCOE (USD/kWh)'                THEN rig.value::numeric END) AS lcoe_usd_per_kwh,
      MAX(CASE WHEN rig.indicator = 'Total installed cost (USD/kW)' THEN rig.value::numeric END) AS installed_cost_usd_per_kw
  FROM renewables_project.ren_indicators_global rig
  JOIN renewables_project.dim_technology dt
    ON rig.tech_id = dt.tech_id
  WHERE rig.value_category = 'Weighted average'
    AND dt.category = 'Renewable'
    AND rig.indicator IN ('LCOE (USD/kWh)','Total installed cost (USD/kW)')
  GROUP BY rig.tech_id, dt.group_technology, dt.technology, rig.year
),
base_2010 AS (
  -- One 2010 baseline row per tech (for deltas)
  SELECT tech_id,
         MAX(lcoe_usd_per_kwh)        AS base_lcoe_2010,
         MAX(installed_cost_usd_per_kw) AS base_inst_cost_2010
  FROM rig_costs
  WHERE year = 2010
  GROUP BY tech_id
),
fossil_2023 AS (
  -- Pin 2023 fossil LCOE cost band (low/high)
  SELECT
    MAX(CASE WHEN cost_band = 'Low band'  THEN value::numeric END) AS fossil_cost_low_usd_per_kwh_2023,
    MAX(CASE WHEN cost_band = 'High band' THEN value::numeric END) AS fossil_cost_high_usd_per_kwh_2023
  FROM renewables_project.fossil_cost_range
)
SELECT
  c.tech_id,
  c.group_technology,
  c.technology,
  c.year,
  f.fossil_cost_low_usd_per_kwh_2023,
  f.fossil_cost_high_usd_per_kwh_2023,
  c.lcoe_usd_per_kwh,
  -- LCOE cumulative change since 2010
  CASE
    WHEN b.base_lcoe_2010 IS NULL OR b.base_lcoe_2010 = 0 THEN NULL
    ELSE ROUND( (c.lcoe_usd_per_kwh - b.base_lcoe_2010) / b.base_lcoe_2010 * 100, 1)
  END AS rel_change_since_2010_lcoe_pct,
  c.installed_cost_usd_per_kw,
  -- Installed costs cumulative change since 2010
  CASE
    WHEN b.base_inst_cost_2010 IS NULL OR b.base_inst_cost_2010 = 0 THEN NULL
    ELSE ROUND( (c.installed_cost_usd_per_kw - b.base_inst_cost_2010) / b.base_inst_cost_2010 * 100, 1)
  END AS rel_change_since_2010_installed_cost_pct
FROM rig_costs c
LEFT JOIN base_2010 b
  ON c.tech_id = b.tech_id
CROSS JOIN fossil_2023 f;






/* -----------------------------------------------------------------------------------------------------------------
   View: vw_country_subregion_renewable_costs
   Purpose: Create a view for Tableau to analyze and visualize Levelized Cost of Energy (LCOE) and Installed Cost
            trends for Solar PV, Onshore wind, and Offshore wind (2010–2023) at the sub-regional and country levels.
   Summary:
      - Delivers yearly country-level LCOE and installed cost, with subregion-level averages for each technology.
      - Includes country counts per subregion-year for both LCOE and installed cost (to flag thin data).
      - Cumulative % change since 2010 for regional metrics is included (country-level % change can be added if needed).
      - Enables dashboards comparing country performance within subregions, identifying regional leaders/laggards.
      
   Key columns:
      - subregion, country, year, technology
      - lcoe_usd_per_kwh (country-level), avg_lcoe_subregion (subregion average)
      - lcoe_country_count (countries reporting LCOE), installed_cost_country_count
      - installed_cost_usd_per_kw (country-level), avg_installed_cost_subregion (subregion average)
      - pct_change_since_2010_lcoe_subregion / pct_change_since_2010_installed_cost_subregion
      
   Visualization ideas:
      - Slope or area charts: Cost decline trajectories for regions/countries over time.
      - Scatter or bar charts: Compare latest (2023) LCOE or installed cost across regions/countries.
      - Heatmaps: Highlight top/bottom performers or rapid cost declines.
      - Interactive dashboards: Allow users to pick region or country and see historical and cumulative change.
      - Small-multiple or map views of country costs, color-coded by tech
      - Highlight subregions with the most/least cost decline
      - Tooltips show country count for data quality context
   ----------------------------------------------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW renewables_project.vw_country_subregion_renewable_costs AS
WITH base AS (
    SELECT
        dg.region_name       AS region,
        dg.sub_region_name   AS subregion,
        dg.geo_id,
        dg.geo_name          AS country,
        ric.year,
        dt.technology,
        ric.indicator,
        ric.country_value::numeric AS value
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg        ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
    WHERE ric.value_category = 'Weighted average'
      AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
      AND ric.year >= 2010
),
country_pivot AS (
    SELECT
        region,
        subregion,
        geo_id,
        country,
        year,
        technology,
        MAX(value) FILTER (WHERE indicator = 'LCOE (USD/kWh)')               AS lcoe_usd_per_kwh,
        MAX(value) FILTER (WHERE indicator = 'Total installed cost (USD/kW)') AS installed_cost_usd_per_kw
    FROM base
    GROUP BY region, subregion, geo_id, country, year, technology
),
subregion_stats AS (
    SELECT
        region,
        subregion,
        year,
        technology,
        AVG(lcoe_usd_per_kwh)               AS avg_lcoe_subregion,
        COUNT(DISTINCT CASE WHEN lcoe_usd_per_kwh IS NOT NULL THEN geo_id END) AS lcoe_country_count,
        AVG(installed_cost_usd_per_kw)      AS avg_installed_cost_subregion,
        COUNT(DISTINCT CASE WHEN installed_cost_usd_per_kw IS NOT NULL THEN geo_id END) AS installed_cost_country_count
    FROM country_pivot
    GROUP BY region, subregion, year, technology
)
SELECT
    ss.region,
    ss.subregion,
    cp.country,
    ss.year,
    ss.technology,
    -- country-level values (nullable if missing)
    cp.lcoe_usd_per_kwh,
    cp.installed_cost_usd_per_kw,
    -- subregion-level aggregates
    ss.avg_lcoe_subregion,
    ss.lcoe_country_count,
    ss.avg_installed_cost_subregion,
    ss.installed_cost_country_count,
    -- Cumulative % change since 2010 for subregion LCOE
    ROUND(
        (ss.avg_lcoe_subregion - FIRST_VALUE(ss.avg_lcoe_subregion) OVER (PARTITION BY ss.subregion, ss.technology ORDER BY ss.year)) /
        NULLIF(FIRST_VALUE(ss.avg_lcoe_subregion) OVER (PARTITION BY ss.subregion, ss.technology ORDER BY ss.year), 0) * 100, 2
    ) AS pct_change_since_2010_lcoe_subregion,
     -- Cumulative % change since 2010 for subregion installed cost
    ROUND(
        (ss.avg_installed_cost_subregion - FIRST_VALUE(ss.avg_installed_cost_subregion) OVER (PARTITION BY ss.subregion, ss.technology ORDER BY ss.year)) /
        NULLIF(FIRST_VALUE(ss.avg_installed_cost_subregion) OVER (PARTITION BY ss.subregion, ss.technology ORDER BY ss.year), 0) * 100, 2
    ) AS pct_change_since_2010_installed_cost_subregion
FROM subregion_stats ss
LEFT JOIN country_pivot cp
       ON ss.region    = cp.region
      AND ss.subregion = cp.subregion
      AND ss.year      = cp.year
      AND ss.technology= cp.technology;




