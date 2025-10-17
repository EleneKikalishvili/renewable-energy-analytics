/* ======================================================================
   File    : 01_ren_share_views.sql
   Purpose : Create core energy emissions view for Tableau to analyze and visualize trends globally, regionally, or by country.
   Author  : Elene Kikalishvili
   Date    : 2025-07-18
   ====================================================================== */


/* ============================================================================================================================  
   Research Question 5: Is there a connection between the growth of renewables' share and reductions in CO₂ emissions at the 
   						global and regional levels? are countries consuming more renewables emitting less?
   ============================================================================================================================ */



/*-----------------------------------------------------------------------------------------------------------------
   View: vw_emissions_core
   Purpose: Tableau-ready view of CO2 emissions (MtCO2) by year, and standardized geography, to enable comparison
   			of emissions trends with renewable energy share over time.

   Summary:
     - Coverage: years ≥ 2000
     - Keeps: 'Country', 'Region', and 'Global' rows.
       - 'Global' rows are source-provided true totals that also include residual/unallocated areas
         (e.g., "Other Middle East", "Other Asia Pacific").
       - 'Region' rows represent regional area totals (e.g., "Western Africa", "Other Europe"),
         not aggregations of country data.
     - Excludes: 'Economic group' and 'Residual/unallocated' geo types to avoid double counting.
     - Enables: 
         - global, regional, and country-level trend analysis,
         - joins with renewables-share data for correlation dashboards.

   Key columns:
     - year
     - geo_type (Country | Region | Global)
     - region, subregion, country_or_area
     - emissions_mtco2 (MtCO₂)

   Visualization ideas:
     - Global/regional time-series showing emission trends.
     - Scatter: Renewables share vs emissions (country or regional level).
     - Highlight maps: High-emitters vs renewable adoption.
-----------------------------------------------------------------------------------------------------------------*/

CREATE OR REPLACE VIEW renewables_project.vw_emissions_core AS
SELECT
    ee.geo_id,
    dg.geo_type,
    dg.region_name     AS region,
    dg.sub_region_name AS subregion,
    dg.geo_name        AS country_or_area,
    ee.year,
    ee.value AS emission_mtco2  
FROM renewables_project.energy_emissions ee
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE ee.year >= 2000
  AND dg.geo_type IN ('Country', 'Region', 'Global')     -- in this dataset 'Region' geo_type data are separate records and not aggregates
  AND ee.value IS NOT NULL
ORDER BY year, region, subregion, country_or_area;




