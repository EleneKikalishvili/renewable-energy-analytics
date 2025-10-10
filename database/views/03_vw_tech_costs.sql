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
WITH cost_base AS (
    -- 1. Pulls LCOE and installed cost per tech/year in a single row
    SELECT
        rig.tech_id,
        dt.technology,
        rig.year,
        MAX(CASE WHEN rig.indicator = 'LCOE (USD/kWh)' THEN rig.value END) AS lcoe_usd_per_kwh,
        MAX(CASE WHEN rig.indicator = 'Total installed cost (USD/kW)' THEN rig.value END) AS installed_cost_usd_per_kw
    FROM
        renewables_project.ren_indicators_global rig
        JOIN renewables_project.dim_technology dt ON rig.tech_id = dt.tech_id
    WHERE
        rig.value_category = 'Weighted average'
        AND (rig.indicator = 'LCOE (USD/kWh)' OR rig.indicator = 'Total installed cost (USD/kW)')
    GROUP BY rig.tech_id, dt.technology, rig.year
),
cost_with_changes AS (
    -- 2. Adds cumulative % change since 2010
    SELECT
        cb.*,
        -- Cumulative change since 2010
        ROUND(
            (cb.lcoe_usd_per_kwh - FIRST_VALUE(cb.lcoe_usd_per_kwh) OVER (PARTITION BY cb.tech_id ORDER BY cb.year)) /
            NULLIF(FIRST_VALUE(cb.lcoe_usd_per_kwh) OVER (PARTITION BY cb.tech_id ORDER BY cb.year), 0) * 100, 1
        ) AS rel_change_since_2010_lcoe_pct,
        ROUND(
            (cb.installed_cost_usd_per_kw - FIRST_VALUE(cb.installed_cost_usd_per_kw) OVER (PARTITION BY cb.tech_id ORDER BY cb.year)) /
            NULLIF(FIRST_VALUE(cb.installed_cost_usd_per_kw) OVER (PARTITION BY cb.tech_id ORDER BY cb.year), 0) * 100, 1
        ) AS rel_change_since_2010_installed_cost_pct
    FROM cost_base cb
),
fossil_costs AS (
    -- 3. Get 2023 fossil cost band values, to CROSS JOIN
    SELECT
        MAX(CASE WHEN cost_band = 'Low band' THEN value END) AS fossil_cost_low_usd_per_kwh_2023,
        MAX(CASE WHEN cost_band = 'High band' THEN value END) AS fossil_cost_high_usd_per_kwh_2023
    FROM renewables_project.fossil_cost_range
)
SELECT
    c.tech_id,
    c.technology,
    c.year,
    fc.fossil_cost_low_usd_per_kwh_2023,
    fc.fossil_cost_high_usd_per_kwh_2023,
    c.lcoe_usd_per_kwh,
    c.rel_change_since_2010_lcoe_pct,
    c.installed_cost_usd_per_kw,
    c.rel_change_since_2010_installed_cost_pct
FROM cost_with_changes c
CROSS JOIN fossil_costs fc
ORDER BY c.technology, c.year;




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
WITH subregional_tech_avg AS (
    SELECT
    	dg.region_name AS region,
        dg.sub_region_name AS subregion,
        ric.year,
        dt.technology,
        AVG(CASE WHEN ric.indicator = 'LCOE (USD/kWh)' THEN ric.country_value END) AS avg_lcoe_subregion,
        COUNT(DISTINCT CASE WHEN ric.indicator = 'LCOE (USD/kWh)' AND ric.country_value IS NOT NULL THEN dg.geo_name END) AS lcoe_country_count,
        AVG(CASE WHEN ric.indicator = 'Total installed cost (USD/kW)' THEN ric.country_value END) AS avg_installed_cost_subregion,
        COUNT(DISTINCT CASE WHEN ric.indicator = 'Total installed cost (USD/kW)' AND ric.country_value IS NOT NULL THEN dg.geo_name END) AS installed_cost_country_count
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
    WHERE
        ric.value_category = 'Weighted average'
        AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
        AND ric.year >= 2010
    GROUP BY dg.region_name, dg.sub_region_name, ric.year, dt.technology
),
country_tech_costs AS ( 
    SELECT
        dg.sub_region_name AS subregion,
        dg.geo_name AS country,
        ric.year,
        dt.technology,
        MAX(CASE WHEN ric.indicator = 'LCOE (USD/kWh)' THEN ric.country_value END) AS lcoe_usd_per_kwh,
        MAX(CASE WHEN ric.indicator = 'Total installed cost (USD/kW)' THEN ric.country_value END) AS installed_cost_usd_per_kw
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
	WHERE
        ric.value_category = 'Weighted average'
        AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
        AND ric.year >= 2010
    GROUP BY dg.sub_region_name, dg.geo_name, ric.year, dt.technology
)
SELECT 
	sra.region,
    sra.subregion,
    cc.country,
    sra.year,
    sra.technology,
    cc.lcoe_usd_per_kwh,
    sra.avg_lcoe_subregion,
    sra.lcoe_country_count,
    -- Cumulative % change since 2010 for subregion LCOE
    ROUND(
        (sra.avg_lcoe_subregion - FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year)) /
        NULLIF(FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year), 0) * 100, 2
    ) AS pct_change_since_2010_lcoe_subregion,
    cc.installed_cost_usd_per_kw,
    sra.avg_installed_cost_subregion,
    sra.installed_cost_country_count,
    -- Cumulative % change since 2010 for subregion installed cost
    ROUND(
        (sra.avg_installed_cost_subregion - FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year)) /
        NULLIF(FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year), 0) * 100, 2
    ) AS pct_change_since_2010_installed_cost_subregion
FROM subregional_tech_avg sra
LEFT JOIN country_tech_costs cc
    ON sra.subregion = cc.subregion
    AND sra.year = cc.year
    AND sra.technology = cc.technology
ORDER BY sra.technology, sra.subregion, sra.year, cc.country;





