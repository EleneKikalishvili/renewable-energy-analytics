/* ======================================================================
   File    : rq2_capacity_and_performance.sql
   Purpose : Analyze global annual trends for each major renewable technology—
             tracking installed capacity (MW), generation (GWh), and weighted average capacity factor (%).
   Author  : Elene Kikalishvili
   Date    : 2025-06-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 2: How have installed capacity and capacity factors for different renewable technologies changed,
   						and what do these trends reveal about technology adoption and performance?
   ============================================================================================================================ */


-- Exploring datasets
-- Global level data
SELECT *
FROM renewables_project.ren_indicators_global
LIMIT 5; 

SELECT DISTINCT dt.technology, min(year), max(year)
FROM renewables_project.ren_indicators_global rig
JOIN renewables_project.dim_technology dt 
ON rig.tech_id = dt.tech_id
GROUP BY dt.technology;

SELECT DISTINCT indicator, value_category 
FROM renewables_project.ren_indicators_global;

/*
	NOTES: 
		- Available technologies: CSP, Geothermal, Hydropower, Offshore wind, Onshore wind, Solar PV
		- Years: 2010 - 2023
		- indicators: Total installed cost (USD/kW), Capacity factor (%), LCOE (USD/kWh)
		- Calculations: Weighted average, 5th percentile, 95th percentile
*/

-- Country level data
SELECT *
FROM renewables_project.ren_indicators_country
LIMIT 5;

SELECT DISTINCT tech_id, "period", min(year), max(year)
FROM renewables_project.ren_indicators_country
GROUP BY tech_id, period;

SELECT DISTINCT sub_technology
FROM renewables_project.dim_technology;

SELECT DISTINCT indicator, value_category 
FROM renewables_project.ren_indicators_global;

SELECT COUNT(*)
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt 
ON ric.tech_id = dt.tech_id AND  ric."indicator" = 'Capacity factor (%)' AND ric.value_category = 'Weighted average'
JOIN renewables_project.dim_geo dg 
ON dg.geo_id = ric.geo_id
JOIN renewables_project.capacity_generation cg 
ON cg."year" = ric."year" AND cg.tech_id = ric.tech_id AND cg.geo_id = ric.geo_id
WHERE technology <> 'Hydropower';

SELECT count(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt 
ON ric.tech_id = dt.tech_id
WHERE dt.technology = 'Hydropower' AND ric.country_value IS NOT NULL;


/*
	NOTES: 
		- Available technologies: Hydropower, Offshore wind, Onshore wind, Solar PV
		- Country level data available for Offshore wind, Onshore wind, Solar PV
		- Hydropower has regional data, and country level data for 3 countries.
		- Hydropower data is divided by Large and Small projects. Probably will need to aggregate.
		- Years: No year data for hydro, only periods ( 2010-2015, 2016-2023). The rest 2010-2023. Onshore wind data is available since 1984.
		- indicators: Total installed cost (USD/kW), Capacity factor (%), LCOE (USD/kWh)
		- Calculations: Weighted average, 5th percentile, 95th percentile'
		- Not enough data to do country-level capacity factor analysis.
*/


-- for reference
SELECT DISTINCT dt.group_technology, dt.technology, dt.sub_technology 
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_technology dt 
ON cg.tech_id = dt.tech_id
ORDER  BY dt.sub_technology 
WHERE dt.

-- Capacity factor vs Installed capacity over time
-- Global indicators table only has aggregated technology data for weighted average capacity factor,
-- so I need to aggregate all bioenergy data on group level, and others on technology level  to join with global indicators table.

WITH tech_level AS (
    -- For detailed technologies (onshore wind, offshore wind, solar PV, solar thermal)
    SELECT
        cg.year,
        dt.technology,
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM (cg.generation_gwh) AS generation_gwh
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    WHERE
    	-- Pumped storage is excluded from Hydropower calculation
        dt.technology IN ('Onshore wind energy', 'Offshore wind energy', 'Solar photovoltaic', 'Solar thermal energy', 'Geothermal energy') 
    GROUP BY cg.year, dt.technology
),
group_level AS (
    -- For group technologies (Bioenergy)
    SELECT
        cg.year,
        dt.group_technology AS technology, -- Label as technology for union
        SUM(cg.installed_capacity_mw) AS installed_capacity_mw,
        SUM(cg.generation_gwh) AS generation_gwh
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
    WHERE
        dt.group_technology IN ('Hydropower','Bioenergy')
    GROUP BY cg.year, dt.group_technology
),

combined AS (
    SELECT * FROM tech_level
    UNION ALL
    SELECT * FROM group_level
)
SELECT
	dt.tech_id, -- tech_id for aggregated technologies
    c.year,
    dt.group_technology,
    c.technology,
    c.installed_capacity_mw,
    c.generation_gwh,
    ROUND(rig.value, 0) AS capacity_factor_pct, -- Weighted Average
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
ORDER BY c.year, rel_change_since_2010_generation DESC;
--ORDER BY c.year, rel_change_since_2010_cap_factor DESC;
--ORDER BY c.year, c.installed_capacity_mw DESC;
--ORDER BY c.year, rel_change_since_2010_installed_cap DESC, c.technology;
--ORDER BY c.technology, c.year;
--ORDER BY c.year, capacity_factor_pct DESC;


/*
Key Insights: Trends in Renewable Technology Performance (2010–2023)
    •    Installed Capacity Growth:
    •    Solar PV is the clear global leader, expanding installed capacity by 3,404% (35x) since 2010.
    •    Offshore wind increased 23x, while hydropower grew just 37%.
    •    Hydropower remained the largest installed renewable source until 2022, but by 2023, Solar PV overtook hydropower to become #1 worldwide.
    •    Capacity Factor Trends:
    •    Geothermal, bioenergy, and hydropower have consistently high capacity factors, but showed limited improvement.
    •    Solar and wind technologies saw significant gains.
    •    In 2023, Solar thermal energy led with a 79% increase in capacity factor since 2010, followed by offshore wind (+32%), hydropower (+21%), and Solar PV (+17%).
    •    Electricity Generation:
    •    Solar PV generated almost 40x more electricity in 2023 than in 2010, leading all renewables.
    •    Offshore wind output increased 21x, solar thermal nearly 8x, and onshore wind about 6x.
    •    Overall:
    •    Solar energy is the top performer among renewables in growth of capacity, output, and capacity factor.
    •    Hydropower still provides the largest global base, but solar and wind are driving the fastest change.
*/
 
































