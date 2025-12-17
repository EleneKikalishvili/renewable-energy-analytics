/* ======================================================================
   File    : 02_tech_performance_view.sql
   Purpose : Create views for Tableau to analyze and visualize trends in installed capacity, generation, and capacity factor
             for each renewable technology, globally, with cumulative % changes since baseline.
   Author  : Elene Kikalishvili
   Date    : 2025-06-21
   ====================================================================== */


/* ============================================================================================================================  
   Research Question 2: How have installed capacity and capacity factors for different renewable technologies changed, 
   						and what do these trends reveal about technology adoption and performance?
   ============================================================================================================================ */


/*-----------------------------------------------------------------------------------------------------------------
   View: vw_technology_performance_global
   Purpose: Create a view for Tableau to analyze global annual trends for each major renewable technology—
            tracking installed capacity (MW), generation (GWh), and weighted average capacity factor (%),
            plus cumulative % change since 2010 for each metric.

   Summary:
      - Provides year-by-year, technology-level global metrics for deployment (installed capacity), output (generation),
        and performance (capacity factor), allowing robust comparison of renewables’ growth and utilization.
      - Calculates cumulative relative change since 2010 for each metric—essential for identifying “breakout” technologies.
      - Useful for time-series, combination bar/line, and technology benchmarking dashboards in Tableau.

   Key columns:
      - tech_id: Technology key (for joining, tooltip, or lookup in Tableau)
      - group_technology: Technology group (e.g., Hydropower, Bioenergy)
      - technology: Specific technology (e.g., Solar PV, Onshore wind energy)
      - year
      - installed_capacity_mw: Total global installed capacity (MW)
      - generation_gwh: Total global generation (GWh)
      - capacity_factor_pct: Weighted average capacity factor (%)
      - rel_change_since_2010_installed_cap: Cumulative % change in installed capacity since 2010
      - rel_change_since_2010_generation: Cumulative % change in generation since 2010
      - rel_change_since_2010_cap_factor: Cumulative % change in capacity factor since 2010

   Visualization ideas:
      - Combo bar/line charts for each technology’s capacity, generation, and capacity factor trends.
      - Small multiples for side-by-side tech performance or “breakout” leaders.
      - Slope or area charts to highlight pace and relative growth of technologies.
   ----------------------------------------------------------------------------------------------------------------- */


/* Indicators table unlike capacity_generation table has data only for high level Bioenergy and Hydropower technologies, 
   for that reason detailed technology data that exists in both tables will be extracted separately from capacity_generation table
   and will be unioned with grouped Bionergy and hydropower capacity/generation data calculated separately.
*/

CREATE OR REPLACE VIEW renewables_project.vw_technology_performance_global AS
WITH tech_level AS (
    -- For detailed technologies (onshore wind, offshore wind, solar PV, solar thermal)
    SELECT
        cg.year,
        CASE
  	  		WHEN dt.technology = 'Solar thermal energy' THEN 'Concentrated solar power'::VARCHAR(50)
  	  		ELSE dt.technology
        END AS technology,
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM (cg.generation_gwh) AS generation_gwh
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    WHERE
        dt.technology IN ('Onshore wind energy', 'Offshore wind energy', 'Solar photovoltaic', 'Solar thermal energy', 'Geothermal energy') 
    GROUP BY cg.year, dt.technology
),
group_level AS (
    -- For grouped technologies (Bioenergy, and Hydropower)
    SELECT
        cg.year,
        dt.group_technology AS technology, -- Label as technology for union
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM(cg.generation_gwh) AS generation_gwh
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    WHERE
        dt.group_technology IN ('Hydropower','Bioenergy')  -- Pumped storage is excluded from Hydropower calculation
    GROUP BY cg.year, dt.group_technology
),

combined AS (
    SELECT * FROM tech_level
    UNION ALL
    SELECT * FROM group_level
)
SELECT
	dt.tech_id,
    c.year,
    dt.group_technology,
    c.technology,
    c.installed_capacity_mw,
    c.generation_gwh,
    ROUND(rig.value, 2)  AS capacity_factor_pct, -- Weighted Average
    ROUND(
    (c.installed_capacity_mw - FIRST_VALUE(c.installed_capacity_mw) OVER (PARTITION BY c.technology ORDER BY c.year))
    / NULLIF(FIRST_VALUE(c.installed_capacity_mw) OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100
	, 1) AS rel_change_since_2010_installed_cap,
	ROUND(
    (c.generation_gwh - FIRST_VALUE(c.generation_gwh) OVER (PARTITION BY c.technology ORDER BY c.year))
    / NULLIF(FIRST_VALUE(c.generation_gwh) OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100
	, 1) AS rel_change_since_2010_generation,
	ROUND(
    (rig.value - FIRST_VALUE(rig.value) OVER (PARTITION BY c.technology ORDER BY c.year))
    / NULLIF(FIRST_VALUE(rig.value) OVER (PARTITION BY c.technology ORDER BY c.year), 0) * 100
	, 1) AS rel_change_since_2010_cap_factor
FROM
	renewables_project.ren_indicators_global rig
	JOIN renewables_project.dim_technology dt ON rig.tech_id = dt.tech_id 
	JOIN combined c ON dt.technology = c.technology 
        AND c.year = rig.year
        AND rig.indicator = 'Capacity factor (%)'
        AND rig.value_category = 'Weighted average'
ORDER BY c.year, c.technology;




