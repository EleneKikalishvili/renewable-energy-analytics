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



-- Exploring cost data
-- Global
SELECT *
FROM renewables_project.ren_indicators_global
LIMIT 5; 

SELECT DISTINCT indicator
FROM renewables_project.ren_indicators_global; 

-- Fossil Fuel
SELECT *
FROM renewables_project.fossil_cost_range;


SELECT
	tech_id,
	year,
	MAX(CASE WHEN indicator = 'LCOE (USD/kWh)' THEN value END) AS lcoe_usd_per_kwh,
	MAX(CASE WHEN indicator = 'Total installed cost (USD/kW)' THEN value END) AS tot_installed_cost_usd_per_kw
FROM renewables_project.ren_indicators_global 
WHERE 
	value_category = 'Weighted average' AND 
	(indicator::text ILIKE '%cost%' OR indicator::text ILIKE 'LCOE%')
GROUP BY 
	tech_id, year
ORDER BY year;




-- Exploring how renewable technologies' costs have changed since 2010 till 2023
WITH ren_base AS (
	SELECT
	    rig.tech_id,
	    dt.technology,
	    rig.year,
	    MAX(CASE WHEN rig.indicator = 'LCOE (USD/kWh)' THEN rig.value END) AS lcoe,
	    MAX(CASE WHEN rig.indicator = 'Total installed cost (USD/kW)' THEN rig.value END) AS installed_cost
	FROM
	    renewables_project.ren_indicators_global rig
	    JOIN renewables_project.dim_technology dt ON rig.tech_id = dt.tech_id
	WHERE
	    rig.value_category = 'Weighted average'
	    AND (rig.indicator = 'LCOE (USD/kWh)' OR rig.indicator = 'Total installed cost (USD/kW)')
	GROUP BY rig.tech_id, dt.technology, rig.year
),
fossil_costs AS ( 
	SELECT 
		MAX(CASE WHEN cost_band = 'Low band' THEN value END) AS lowest_fossil_cost_usd_per_kwh_2023,
    	MAX(CASE WHEN cost_band = 'High band' THEN value END) AS highest_fossil_cost_usd_per_kwh_2023
    FROM 
    	renewables_project.fossil_cost_range 
),
ren_costs_2010_2023 AS (
	SELECT DISTINCT
	    tech_id,
	    technology,
	    -- 2010 values
	    FIRST_VALUE(lcoe) OVER (PARTITION BY tech_id ORDER BY year) AS lcoe_usd_per_kwh_2010,
	    FIRST_VALUE(installed_cost) OVER (PARTITION BY tech_id ORDER BY year) AS installed_cost_usd_per_kw_2010,
	    -- 2023 values
	    LAST_VALUE(lcoe) OVER (PARTITION BY tech_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lcoe_usd_per_kwh_2023,
	    LAST_VALUE(installed_cost) OVER (PARTITION BY tech_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS installed_cost_usd_per_kw_2023
	FROM ren_base
	WHERE year IN (2010, 2023) --window functions produce same row for 2010 and 2023. So I'd get duplicate rows without DISTINCT
)

SELECT
  c.technology,
  fc.lowest_fossil_cost_usd_per_kwh_2023,
  fc.highest_fossil_cost_usd_per_kwh_2023,
  c.lcoe_usd_per_kwh_2010,
  c.lcoe_usd_per_kwh_2023,
  ROUND((c.lcoe_usd_per_kwh_2023 - c.lcoe_usd_per_kwh_2010) / NULLIF(c.lcoe_usd_per_kwh_2010, 0) * 100, 1) AS rel_change_lcoe_pct,
  c.installed_cost_usd_per_kw_2010,
  c.installed_cost_usd_per_kw_2023,
  ROUND((c.installed_cost_usd_per_kw_2023 - c.installed_cost_usd_per_kw_2010) / NULLIF(c.installed_cost_usd_per_kw_2010, 0) * 100, 1) AS rel_change_installed_cost_pct
FROM ren_costs_2010_2023 c
CROSS JOIN fossil_costs fc
ORDER BY lcoe_usd_per_kwh_2023;
--ORDER BY lcoe_2010;
--ORDER BY rel_change_lcoe_pct ASC;

/*
Insights:
    - Solar PV leads the cost decline: From 2010 to 2023, the global Levelized Cost of Electricity (LCOE) for Solar PV fell by 90.4%, 
      and installed costs dropped by 85.7%—the largest declines among all renewable technologies.
    - Wind and solar thermal also show major cost reductions:
       - Onshore wind: LCOE down 70.6%, installed cost down 48.9%
       - Solar thermal: LCOE down 70.4%, installed cost down 38.1%
       - Offshore wind: LCOE down 63.2%, installed cost down 48.2%
    - Bioenergy saw minimal cost change: LCOE dropped only 15.2%, and installed cost declined by 9.3%.
    - Hydropower and geothermal costs increased:
       - Geothermal: LCOE up 30.8%, installed cost up 52.4%
       - Hydropower: LCOE up 32.3%, installed cost up 92.3%
       
   Ranking and competitiveness in 2023:
    - In 2010, hydropower was the cheapest renewable (LCOE), with solar PV the most expensive (0.46 USD/kWh).
    - By 2023, onshore wind (0.033 USD/kWh) and solar PV (0.044 USD/kWh) became the cheapest renewables, both beating the lowest fossil fuel cost band (0.07 USD/kWh).
    - Hydropower (0.057) remained competitive, also below the lowest fossil cost.
    - Solar thermal (0.12) and offshore wind (0.075) are the most expensive renewables, yet all are still below the highest fossil fuel cost (0.176 USD/kWh), 
      and most are competitive with the low band.
      
   Key takeaway:
    - Rapid cost declines in solar and wind have transformed them from the most expensive to the most affordable renewable options, 
      making them cost-competitive—even cheaper—than fossil fuels in most markets.
    - Hydropower and geothermal now face rising costs, but remain important in the global mix.
    - The cost gap between renewables and fossil fuels has dramatically closed, with renewables now setting the global benchmark for cheap electricity.
*/





-- Extracting all the necessary information and calculations for creating view for Tableau to visualize those insights
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
    -- 2. Adds YoY and cumulative % change since 2010
    SELECT
        cb.*,
        -- YoY changes
        LAG(cb.lcoe_usd_per_kwh) OVER (PARTITION BY cb.tech_id ORDER BY cb.year) AS lcoe_prev,
        LAG(cb.installed_cost_usd_per_kw) OVER (PARTITION BY cb.tech_id ORDER BY cb.year) AS installed_cost_prev,
        ROUND(
            (cb.lcoe_usd_per_kwh - LAG(cb.lcoe_usd_per_kwh) OVER (PARTITION BY cb.tech_id ORDER BY cb.year)) /
            NULLIF(LAG(cb.lcoe_usd_per_kwh) OVER (PARTITION BY cb.tech_id ORDER BY cb.year), 0) * 100, 2
        ) AS rel_yoy_change_lcoe_pct,
        ROUND(
            (cb.installed_cost_usd_per_kw - LAG(cb.installed_cost_usd_per_kw) OVER (PARTITION BY cb.tech_id ORDER BY cb.year)) /
            NULLIF(LAG(cb.installed_cost_usd_per_kw) OVER (PARTITION BY cb.tech_id ORDER BY cb.year), 0) * 100, 2
        ) AS rel_yoy_change_installed_cost_pct,
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
    c.lcoe_prev,
    c.rel_yoy_change_lcoe_pct,
    c.rel_change_since_2010_lcoe_pct,
    c.installed_cost_usd_per_kw,
    c.installed_cost_prev,
    c.rel_yoy_change_installed_cost_pct,
    c.rel_change_since_2010_installed_cost_pct
FROM cost_with_changes c
CROSS JOIN fossil_costs fc
ORDER BY c.technology, c.year;



-- Preparing data for Tableau to analyze and visualize cost trends on regional and country level
-- NOTE: Due to data limitation I will be analyzing only 3 leading technologies Solar PV, Onshore wind, and Offshroe wind

-- Country data 
SELECT dg.geo_name, dt.technology, ric.*
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
--WHERE dt.technology <> 'Hydropower' AND ric."year" = 2010 AND indicator IS NULL -- Checking if there are countries that have no data in 2010.
--WHERE dg.geo_name = 'Australia' AND dt.technology LIKE 'Solar%' AND "indicator" = 'LCOE (USD/kWh)'
WHERE dt.technology <> 'Hydropower' AND ric."year" >= 2010 
ORDER BY dg.geo_name, ric."year", dt.technology


SELECT COUNT(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country; --58

SELECT COUNT(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country
WHERE "year" = 2010; --25

-- NOTE: 33 countries don't have 2010 records. In general some countries are missing 

SELECT COUNT(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dt.technology LIKE 'Offshore%'; --Offshroe wind data is available for 8 countries

SELECT dt.technology, geo_id, year
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dt.technology LIKE 'Offshore%'; -- limited yearly data

SELECT COUNT(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dt.technology LIKE 'Solar%'; --21

SELECT COUNT(DISTINCT geo_id)
FROM renewables_project.ren_indicators_country ric
JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
WHERE dt.technology LIKE 'Onshore%'; --45


SELECT DISTINCT technology, sub_technology
FROM renewables_project.dim_technology



-- NOTE: Regional average calcualtions represent average of countries' reporting data in that year/technology, not true average of all countries in the region.

WITH subregional_tech_avg AS (
    SELECT
        dg.sub_region_name AS subregion,
        ric.year,
        dt.technology,
        AVG(CASE WHEN ric.indicator = 'LCOE (USD/kWh)' THEN ric.country_value END) AS avg_lcoe_subregion,
        -- Calculating number of countries that have lcoe data reported
        COUNT(DISTINCT CASE WHEN ric.indicator = 'LCOE (USD/kWh)' AND ric.country_value IS NOT NULL THEN dg.geo_name END) AS lcoe_country_count,
        AVG(CASE WHEN ric.indicator = 'Total installed cost (USD/kW)' THEN ric.country_value END) AS avg_installed_cost_subregion,
        -- Calculating number of countries that have installed cost data reported
        COUNT(DISTINCT CASE WHEN ric.indicator = 'Total installed cost (USD/kW)' AND ric.country_value IS NOT NULL THEN dg.geo_name END) AS installed_cost_country_count
    FROM renewables_project.ren_indicators_country ric
    JOIN renewables_project.dim_geo dg ON ric.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt ON ric.tech_id = dt.tech_id
    WHERE
        ric.value_category = 'Weighted average'
        AND dt.technology IN ('Solar photovoltaic', 'Onshore wind energy', 'Offshore wind energy')
        AND ric.year >= 2010
    GROUP BY dg.sub_region_name, ric.year, dt.technology
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
    sra.subregion,
    cc.country,
    sra.year,
    sra.technology,
    cc.lcoe_usd_per_kwh,
    sra.avg_lcoe_subregion,
    sra.lcoe_country_count,
    -- LCOE cumulative since 2010 for regions
    ROUND(
        (sra.avg_lcoe_subregion - FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year)) /
        NULLIF(FIRST_VALUE(sra.avg_lcoe_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year), 0) * 100, 2
    ) AS pct_change_since_2010_lcoe_subregion,
    cc.installed_cost_usd_per_kw,
    sra.avg_installed_cost_subregion,
    sra.installed_cost_country_count,
    -- Installed cost cumulative since 2010 for regions
    ROUND(
        (sra.avg_installed_cost_subregion - FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year)) /
        NULLIF(FIRST_VALUE(sra.avg_installed_cost_subregion) OVER (PARTITION BY sra.subregion, sra.technology ORDER BY sra.year), 0) * 100, 2
    ) AS pct_change_since_2010_installed_cost_subregion
FROM subregional_tech_avg sra
LEFT JOIN country_tech_costs cc
    ON sra.subregion = cc.subregion
    AND sra.year = cc.year
    AND sra.technology = cc.technology
--WHERE sra.year = 2023
ORDER BY sra.technology, sra.year DESC, pct_change_since_2010_lcoe_subregion
--ORDER BY sra.technology, sra.avg_lcoe_subregion;
--ORDER BY sra.technology, cc.lcoe_usd_per_kwh;
--ORDER BY sra.technology, cc.lcoe_usd_per_kwh DESC;


/*
Insights from Country-Level LCOE Data (IRENA, 2010–2023)

Note: These insights are based on data from up to 58 countries, across three technologies—solar PV, onshore wind, and offshore wind. Offshore wind data is especially limited (8 countries), and regional averages are calculated only from countries reporting data in each year, not from the full region.

Regional Trends (2023 and Cumulative Change since 2010)
		Offshore Wind:
			- Largest decline in LCOE since 2010 is observed in Western Europe (-71.8%), but this is based on very limited country data.
		Onshore Wind - Largest declines in LCOE:
			- Northern Europe (-70.6%)
			- Australia & New Zealand (-70.4%)
			- Northern America (-67.8%)
			- Southern and Western Europe (-65%)
			- Many regions—including Latin America, South Africa, India, and SE Asia - saw declines above 50%.
		Solar PV - Largest declines in:
			- Australia (-91.9%)
			- Southern Asia (India) (-87.7%)
			- Southern Europe (-87.3%)
			- Northern Europe (UK) (-86.7%)
			- Most regions saw LCOE declines above 50%, except Sub-Saharan Africa (-21.8% in South Africa).
			
		Current (2023) leaders:
			- Cheapest offshore wind: Northern Europe (avg. LCOE $0.054)
			- Cheapest onshore wind: Northern America ($0.037), Northern Europe ($0.038), Australia & NZ ($0.042)
			- Cheapest solar PV: Australia & NZ ($0.038; Australia only), Southern Asia ($0.048; India only), Southern Europe ($0.052)

Country-Level Trends
		Offshore Wind:
			- Cheapest: Denmark ($0.048/kWh), UK ($0.059), Netherlands ($0.061), Germany ($0.063), China ($0.07)
			- Most expensive: Japan ($0.211/kWh)
		Onshore Wind:
			- Cheapest: Brazil ($0.025), China ($0.026), UK ($0.031), Peru ($0.032)
			- Most expensive: Japan ($0.125), Russia ($0.106)
		Solar PV:
			- Cheapest: China ($0.036), Australia ($0.038), Chile ($0.041)
			- Most expensive: Japan ($0.110), Canada ($0.101), Turkey ($0.09), UK ($0.079), South Africa ($0.075)


Analyst Notes
		- These figures highlight where costs have dropped fastest, and which regions/countries are global “cost leaders” in renewables.
		- However, coverage limitations (especially for offshore wind) mean results should be interpreted as “spotlights” rather than a comprehensive world view.
		- This analysis is best used as a supplement to global trends.
 */

