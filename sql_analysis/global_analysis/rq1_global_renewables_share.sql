/* ======================================================================
   File    : rq1_global_renewables_share.sql
   Purpose : Analyze the share of renewables in global electricity generation, capacity, and primary energy consumption over time.
   Author  : Elene Kikalishvili
   Date    : 2025-06-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 1: How has the share of renewables in global electricity generation, installed capacity and primary energy consumption changed over time?
   ============================================================================================================================ */

-- Exploring ren_share
SELECT * 
FROM renewables_project.ren_share 
LIMIT 5;

SELECT DISTINCT dg.geo_type
FROM renewables_project.ren_share rs
LEFT JOIN renewables_project.dim_geo dg 
ON rs.geo_id = dg.geo_id; -- has global, region and country granularity, also has Residual/unallocated geo type

SELECT DISTINCT dg.geo_type, dg.geo_name
FROM renewables_project.ren_share rs
LEFT JOIN renewables_project.dim_geo dg 
ON rs.geo_id = dg.geo_id
WHERE dg.geo_type = 'Residual/unallocated'; 

/*
 *NOTE: Middle East region got classified AS Residual/unallocated, since it isn't standard region name. Countries in this region were assigned standard region names.
 *		Region types are aggregates of countries in this dataset. 'Region' geo type records wont be used for analysis.
 *		Regional analysis will be done using standard region classification - aggregating country data. 
 *		Global analysis will include only 'Global' geo_type.
 */


SELECT DISTINCT rs."indicator"
FROM renewables_project.ren_share rs
LEFT JOIN renewables_project.dim_geo dg 
ON rs.geo_id = dg.geo_id; -- renewables share of both capacity and generation


SELECT DISTINCT dg.geo_name
FROM renewables_project.ren_share rs
LEFT JOIN renewables_project.dim_geo dg 
ON rs.geo_id = dg.geo_id;


-- exploring capacity_generation
SELECT * 
FROM renewables_project.capacity_generation cg 
LIMIT 5;

-- capacity_generation
SELECT distinct dg.geo_type
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_geo dg 
ON cg.geo_id = dg.geo_id;  -- only country level DATA



-- Testing
SELECT count(*) -- 11,184
FROM renewables_project.ren_share;


SELECT count(*) -- 11,184
FROM
	renewables_project.ren_share rs 
	JOIN renewables_project.dim_geo dg
	ON rs.geo_id = dg.geo_id;





-- Analyzing global trends for renewables share in generation and installed capacity
WITH base AS (
	SELECT
		dg.geo_type,
		dg.geo_name,
		rs."year",
		--pivoting
		MAX(CASE WHEN rs."indicator" = 'RE Generation (%)' THEN rs.value END) AS re_generation_pct, -- MAX picks non-NULL value
		MAX(CASE WHEN rs."indicator" = 'RE Capacity (%)' THEN rs.value END) AS re_capacity_pct
	FROM
		renewables_project.ren_share rs 
		JOIN renewables_project.dim_geo dg
			ON rs.geo_id = dg.geo_id
	GROUP BY
		dg.geo_type, dg.geo_name, rs."year"
)

SELECT
	geo_type,
	geo_name,
	"year",
	re_generation_pct,
	LAG(re_generation_pct) OVER (ORDER BY year) AS prev_gen_pct,
	-- Calculating absolute % point change for renewables generation
	ROUND(re_generation_pct - LAG(re_generation_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year), 2) AS abs_yoy_generation_change,
	-- Calculating relative change in % for renewables generation
	ROUND(
		(re_generation_pct - LAG(re_generation_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year)) /
		NULLIF(LAG(re_generation_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year), 0) * 100, 2
	) AS rel_yoy_generation_pct_change,
	re_capacity_pct,
	LAG(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year) AS prev_cap_pct,
	-- Calculating absolute % point change for renewables installed capacity
	ROUND(re_capacity_pct - LAG(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year), 2) AS abs_yoy_capacity_change,
	-- Calculating relative change in % for renewables installed capacity
	ROUND(
		(re_capacity_pct - LAG(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year)) /
		NULLIF(LAG(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year), 0) * 100, 2
	) AS rel_yoy_capacity_pct_change,
	-- Relative change in RE generation share since 2000 (%)
	ROUND(
	  (re_generation_pct - FIRST_VALUE(re_generation_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) /
	  NULLIF(FIRST_VALUE(re_generation_pct) OVER (PARTITION BY geo_type ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) * 100,
	  2
	) AS rel_change_since_2000_generation_pct,
	-- Relative change in RE capacity share since 2000 (%)
	ROUND(
	  (re_capacity_pct - FIRST_VALUE(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) /
	  NULLIF(FIRST_VALUE(re_capacity_pct) OVER (PARTITION BY geo_type, geo_name ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) * 100,
	  2
	) AS rel_change_since_2000_capacity_pct,
	ROUND(re_generation_pct / NULLIF(re_capacity_pct, 0), 2) AS effectiveness_ratio
FROM base
WHERE geo_type = 'Global'
ORDER BY year;




-- Global renewables share in generation and capacity (percent), with YoY and since-2000 deltas
WITH base AS (
  SELECT
    rs.year,
    MAX(CASE WHEN rs.indicator = 'RE Generation (%)' THEN rs.value END) AS re_generation_pct,
    MAX(CASE WHEN rs.indicator = 'RE Capacity (%)'   THEN rs.value END) AS re_capacity_pct
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
    /*
    -- YoY change (percentage points)
    (re_generation_pct - LAG(re_generation_pct) OVER (ORDER BY year)) AS abs_yoy_gen_pp,
    (re_capacity_pct - LAG(re_capacity_pct) OVER (ORDER BY year))       AS abs_yoy_cap_pp,
    -- YoY relative change (%)
    100.0 * (re_generation_pct - LAG(re_generation_pct) OVER (ORDER BY year))
           / NULLIF(LAG(re_generation_pct) OVER (ORDER BY year), 0)     AS rel_yoy_gen_pct,
    100.0 * (re_capacity_pct - LAG(re_capacity_pct) OVER (ORDER BY year))
           / NULLIF(LAG(re_capacity_pct) OVER (ORDER BY year), 0)       AS rel_yoy_cap_pct,
    
     */
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



/* ----------------------------------------------------------------------------------------------------------------
   Insights — Global renewables share (2000–2023)

   - Renewables’ share of electricity generation rose from 18.3% (2000) to 29.1% (2022): +10.8 pp (~+59% relative).
   - Renewables’ share of installed capacity doubled from 21.4% (2000) to 43.0% (2023): +21.6 pp (101% relative).
   - Capacity is outpacing generation: the gap (generation% − capacity%) widened from −3.1 pp (2000) to −11.2 pp (2022),
     reflecting the rapid build-out of solar/wind (lower average capacity factors) and integration needs (grid/storage).
   - Data note: 2023 value for generation share is not reported in the source extract; 2022 is the latest non-null.

---------------------------------------------------------------------------------------------------------------- */




-- Find top 50 countries by renewable generation share in 2022
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

-- Count countries by threshold in 2022 
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


/* ---------------------------------------------------------------
   Insights — Top 50 countries by RE share of generation (2022)

   - Among the top 50, renewables supply between 63% and 100% of electricity.
   - 6 entries report 100% RE generation: South Georgia & the South Sandwich Islands, Nepal, Paraguay,
     Bhutan, Ethiopia, and Albania (note: SGSSI is a small territory).
   - Top-50 distribution (share of electricity from renewables):
   			-    full 100%: 6 countries/territories
		    -    90–<100%: 15 
		    -    80–<90%: 9
		    -    70–<80%: 15
		    -    60–<70%: 5
		    -    Lowest within top-50: Lithuania (63.29%)
     
   - Median RE share within the top 50 is ~86%;
---------------------------------------------------------------- */




-- Checking geo_type in capacity_generation table
SELECT DISTINCT geo_type
FROM renewables_project.capacity_generation cg 
JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id;
-- Only country records


-- Exploring which renewable technologies these top contries use by joining capacity_generation table with ren_share and checking if % share calculation is same in both tables.
-- This can be done without joining on ren_share, but I need to check for consistency.
SELECT
	dg.geo_name AS country,
	cg."year",
	dt.category,
--	dt.technology,
	dt.sub_technology,
	cg.producer_type,
	cg.generation_gwh,
	ROUND(
		SUM(CASE WHEN dt.category = 'Renewable' THEN cg.generation_gwh ELSE 0 END) OVER (PARTITION BY cg.geo_id, cg."year")
		/
		NULLIF(SUM(cg.generation_gwh) OVER (PARTITION BY cg.geo_id, cg."year"), 0) * 100, 2
	) AS re_generation_pct_calc,
	-- pre-calculated from ren_share
	rs.value AS re_generation_pct
	
FROM
	renewables_project.ren_share rs 
	JOIN renewables_project.dim_geo dg
	ON rs.geo_id = dg.geo_id
	JOIN renewables_project.capacity_generation cg 
	ON rs.geo_id = cg.geo_id AND rs."year" = cg."year"
	JOIN renewables_project.dim_technology dt 
	ON cg.tech_id = dt.tech_id
	
WHERE
	rs.value IS NOT NULL
	AND cg.generation_gwh IS NOT NULL
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
GROUP BY cg.geo_id, dg.geo_name, cg."year", dt.category, dt.sub_technology, cg.producer_type, cg.generation_gwh, rs.value
ORDER BY re_generation_pct DESC, country ASC, cg.generation_gwh DESC;

-- Data is Consistent!



-- Overall top technologies used by renewable champions
WITH top_countries AS (
	SELECT
		rs.geo_id,
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
		AND rs.year = 2022
	ORDER BY re_generation_pct DESC
	LIMIT 50
)
SELECT
  dt.technology,
  SUM(cg.generation_gwh) AS total_renewable_generation_gwh,
  ROUND(
  	SUM(cg.generation_gwh) * 100.0 / SUM(SUM(cg.generation_gwh)) OVER (), 2
  ) AS pct_of_top50_total
FROM
  top_countries tc
  JOIN renewables_project.capacity_generation cg ON tc.geo_id = cg.geo_id
  JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
WHERE
  cg."year" = tc."year"
  AND dt.category = 'Renewable'
GROUP BY dt.technology
ORDER BY total_renewable_generation_gwh DESC;


/* ---------------------------------------------------------------
   Insights — Top 5 renewable technologies used by top 50 countries by highest share of renewable electricity generation:
   		- Renewable hydropower (80.05%), 
   		- Onshore wind energy (10.19%), 
   		- Solid biofuels (4.76%), 
   		- Solar photovoltaic (2.77%),
   		- Geothermal energy (1.24%)
---------------------------------------------------------------- */




-- List including non-renewable tech used by top 50 countries in renewable electricity generation.
WITH top_countries AS (
	SELECT
		rs.geo_id,
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
		AND rs.year = 2022
	ORDER BY re_generation_pct DESC
	LIMIT 50
)
SELECT
  dt.sub_technology,
  SUM(cg.generation_gwh) AS total_generation_gwh
FROM
  top_countries tc
  JOIN renewables_project.capacity_generation cg ON tc.geo_id = cg.geo_id
  JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
WHERE
  cg."year" = tc."year"
GROUP BY dt.sub_technology
ORDER BY total_generation_gwh DESC;

/* ---------------------------------------------------------------
   Insights: 
   		 -    After hydro, the largest slices are onshore wind (~197 TWh), natural gas (~190 TWh), nuclear (~154 TWh), coal & peat (~71 TWh), and solar PV (~53 TWh).
   		 -    Fossil + nuclear together are larger than all non-hydro renewables combined (wind + solar + bioenergy + geothermal).
   		 -    So these "renewable-share champions" are mostly hydro systems; outside hydro, they still rely substantially on gas/nuclear/coal.
   		 
---------------------------------------------------------------- */





-- Geographic spread of renewable technologies (distinct countries & subregions per year)
WITH base AS (
  SELECT
    cg.year,
    dt.technology,
    dg.sub_region_name,
    dg.geo_id,       
    dg.geo_name
  FROM renewables_project.capacity_generation cg
  JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
  JOIN renewables_project.dim_geo dg        ON cg.geo_id = dg.geo_id
  WHERE dt.category = 'Renewable'
   -- AND dg.geo_type = 'Country'       --this dataset already has only country geo_type records      
    AND cg.installed_capacity_mw IS NOT NULL
    AND cg.installed_capacity_mw > 0  

)
SELECT
  year,
  technology,
  COUNT(DISTINCT geo_id)          AS number_of_countries,
  COUNT(DISTINCT sub_region_name) AS number_of_subregions
FROM base
GROUP BY year, technology
ORDER BY year DESC, number_of_countries DESC, technology;



-- Countries adopting each renewable technology: 2000 vs 2023
-- Counts distinct countries with >0 MW installed capacity 

WITH base AS (
  SELECT
    cg.year,
    dt.group_technology,
    dt.technology AS technology, 
    dg.geo_id
  FROM renewables_project.capacity_generation cg
  JOIN renewables_project.dim_technology dt ON cg.tech_id = dt.tech_id
  JOIN renewables_project.dim_geo        dg ON cg.geo_id = dg.geo_id
  WHERE dt.category = 'Renewable'
   -- AND dg.geo_type = 'Country'
    AND cg.year IN (2000, 2023)
    AND cg.installed_capacity_mw IS NOT NULL
    AND cg.installed_capacity_mw > 0           
)
SELECT
	group_technology,
	technology,
	COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000) AS countries_2000,
	COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023) AS countries_2023,
	( COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023)
	  - COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000) ) AS change_count,
	ROUND(
	    100.0 * (
	      (COUNT(DISTINCT geo_id) FILTER (WHERE year = 2023))
	      - (COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000))
	    ) / NULLIF((COUNT(DISTINCT geo_id) FILTER (WHERE year = 2000)), 0)
	, 2) AS growth_pct
FROM base
GROUP BY group_technology, technology
ORDER BY countries_2023 DESC, technology;

/* ---------------------------------------------------------------
 
  Diffusion of renewable technologies (presence by geography)

  - Hydropower reached global breadth early. Country coverage rose only slightly from 158 -> 163 between 2000 and 2023 
    (+5 countries, ~+3% growth in coverage), indicating near-saturation. It has been present in all 17 subregions since 2000.

  - PV and onshore wind completed their subregional spread in the 2010s:
      - Onshore wind: all 17 subregions by 2012; countries 60 -> 156 (+96; ~+160%).
      - Solar PV:     all 17 subregions by 2013; countries 62 -> 220 (+158; ~+255%).

  - Resource/site-limited tech expanded but remain niche in global coverage by 2023:
      - Offshore wind (coastline/wind regime): in 6/17 subregions; 3 -> 18 countries.
      - Geothermal (tectonic resource):        in 12/17 subregions; 22 -> 32 countries.
      - Solar thermal (CSP):                   in 12/17 subregions; 1 -> 21 countries.
      - Marine:                                in 9/17 subregions; 6 -> 15 countries.

  - Bioenergy (solid biofuels, biogas) is widely present but not universal—coverage tracks feedstock and waste systems:
      - Solid biofuels: 			87 -> 118 countries; 15/17 subregions.
      - Biogas:         			31 -> 106 countries; 15/17 subregions.
      - Renewable municipal waste:  24 -> 47 countries; 11/17 subregions.
      - Liquid biofuels: 			2 -> 23 countries; 10/17 subregions.
      
  Note: Counts reflect countries with reported capacity. Presence ≠ scale; these figures show where a tech exists, not how big it is.

---------------------------------------------------------------- */




-- Analyzing which regions are deploying most renewables, their % share of global renewable deployement and top technologies that they have installed.

WITH regional_tech AS (
    SELECT
        dg.sub_region_name AS region,
        cg."year",
        dt.technology,
        SUM(cg.generation_gwh) AS ren_generation_gwh,
        SUM(cg.installed_capacity_mw) AS ren_capacity_mw
    FROM
        renewables_project.capacity_generation cg
        JOIN renewables_project.dim_geo dg ON cg.geo_id = dg.geo_id
        JOIN renewables_project.dim_technology dt 
            ON cg.tech_id = dt.tech_id 
            AND dt.category = 'Renewable'
    GROUP BY
        dg.sub_region_name, cg."year", dt.technology
)
SELECT
    region,
    "year",
    technology,
    
    -- Capacity breakdown
    -- Regional Total in a year
    SUM(ren_capacity_mw) OVER (PARTITION BY region, "year") AS total_cap_mw_region_year,
    
    -- Regional total per technology in a year
    ren_capacity_mw,
    
     -- % share of each technology in a regional total
    ROUND(ren_capacity_mw / NULLIF(SUM(ren_capacity_mw) OVER (PARTITION BY region, "year"), 0) * 100, 2) AS pct_cap_region_by_tech,
    
    -- Global totals per year
    SUM(ren_capacity_mw) OVER (PARTITION BY "year") AS total_cap_mw_global_year,
    
    -- Region's share of global total (capacity)
    ROUND(
      SUM(ren_capacity_mw) OVER (PARTITION BY region, "year") /
      NULLIF(SUM(ren_capacity_mw) OVER (PARTITION BY "year"), 0) * 100, 2
    ) AS pct_of_global_cap_this_region,

    -- Generation breakdown
    -- Regional Total in a year
    SUM(ren_generation_gwh) OVER (PARTITION BY region, "year") AS total_gen_gwh_region_year,
    
    -- Regional total per technology in a year
    ren_generation_gwh,
    
    -- % share of each technology in a regional total
    ROUND(ren_generation_gwh / NULLIF(SUM(ren_generation_gwh) OVER (PARTITION BY region, "year"), 0) * 100, 2) AS pct_gen_region_by_tech,
    
    -- Global totals per year
    SUM(ren_generation_gwh) OVER (PARTITION BY "year") AS total_gen_gwh_global_year,
    
    -- Region's share of global total (generation)
    ROUND(
      SUM(ren_generation_gwh) OVER (PARTITION BY region, "year") /
      NULLIF(SUM(ren_generation_gwh) OVER (PARTITION BY "year"), 0) * 100, 2
    ) AS pct_of_global_gen_this_region

FROM
    regional_tech
ORDER BY
   -- "year", pct_of_global_cap_this_region DESC, region, ren_capacity_mw DESC;
    "year" DESC, pct_of_global_cap_this_region DESC, region, ren_capacity_mw DESC;
   -- "year" DESC, pct_of_global_gen_this_region DESC, region, ren_generation_gwh DESC;

/*	
Regional Leadership in Renewable Energy: 2000 vs 2023

In 2000:
    -    Northern America led the world in renewable capacity, accounting for 21.2% of global installed renewables.
	     Technology mix:
	        Renewable Hydropower: 84.0% of regional total
	        Mixed Hydro Plants: 7.0%
	        Solid Biofuels: 3.7%
    -    Latin America and the Caribbean contributed 17.3% of the global total, with a technology mix:
	        Renewable Hydropower: 95.5%
	        Solid Biofuels: 3.4%
	        Geothermal: 1.0%
    -    Eastern Asia was third, providing 14.4% of global renewables.
	        Renewable Hydropower: 96.7%
	        Solid Biofuels: 1.5%
	        Renewable Municipal Waste: 0.6%

By 2023:
    -    Eastern Asia became the new global leader, with a 42.3% share of worldwide renewable installed capacity.
         Solar PV and onshore wind surged, with solar PV alone now representing nearly half the region’s capacity(44.9%),
         followed by Onshore wind(25.25%), and Hydropower(24.57%).
    -    Northern America dropped to second(12.8%), but with a more balanced mix of:
    	 onshore wind(33.4%), hydropower(31.3%), and solar PV(29.1%).
    -    Latin America and the Caribbean moved to third (8.8%), still dominated by hydropower(59%), 
         but with growing solar PV(19%) and onshore wind(14.5%) shares.

Key Takeaways:
    -    In 2000, hydropower dominated every leading region’s renewables mix (over 80–95%).
    -    By 2023, solar and wind have rapidly overtaken hydropower in Eastern Asia and significantly diversified Northern America’s mix.
    -    The global "center of gravity" for renewable deployment has decisively shifted from the Americas to Asia in the last two decades.
*/







-- Analyzing Primary Energy Consumption

-- Checking geo data
SELECT DISTINCT geo_type, geo_name, region_name
FROM renewables_project.primary_consumption pc
    JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id


SELECT DISTINCT geo_type
FROM renewables_project.primary_consumption pc
    JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
    
SELECT DISTINCT geo_type, geo_name, sub_region_name 
FROM renewables_project.ren_primary_consumption rpc
    JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id
    
 SELECT distinct dg.geo_type, dg.geo_name
 FROM renewables_project.primary_consumption pc
 JOIN renewables_project.dim_geo dg ON pc.geo_id = dg.geo_id
 WHERE year >= 2000 AND dg.geo_type NOT IN ('Country', 'Global', 'Economic_group');
    
 /*
    Region
	Economic_group
	Global
	Country
	Residual/unallocated
  */

    

 /* Checking data:
    Global: standardized (countries only) vs source Global, with an optional residual add-back (Other CIS)
 */
WITH base AS (
  -- Harmonize both facts into one table with a 'metric' tag
  SELECT 'primary' AS metric, pc.year, pc.value, dg.geo_type, dg.geo_name
  FROM renewables_project.primary_consumption pc
  JOIN renewables_project.dim_geo dg ON dg.geo_id = pc.geo_id
  WHERE pc.year >= 2000

  UNION ALL
  SELECT 'renewables' AS metric, rp.year, rp.value, dg.geo_type, dg.geo_name
  FROM renewables_project.ren_primary_consumption rp
  JOIN renewables_project.dim_geo dg ON dg.geo_id = rp.geo_id
  JOIN renewables_project.dim_technology dt ON dt.tech_id = rp.tech_id
  WHERE rp.year >= 2000 AND dt.technology <> 'Nuclear'
),
standardized AS (
  -- Sum of the rows you actually analyze in Tableau (country and area)
  SELECT metric, year, SUM(value) AS global_standardized_ej
  FROM base
  WHERE geo_type IN ('Country', 'Region')
  GROUP BY metric, year
),
residual_addback AS (
  -- Optional: add tiny residuals that source Global includes but you exclude (e.g., "Other CIS")
  SELECT metric, year, SUM(value) AS other_residual_ej
  FROM base
  WHERE geo_type = 'Residual/unallocated'
  GROUP BY metric, year
),
source_global AS (
  -- Source "Global" rows for comparison
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
  (s.global_standardized_ej + COALESCE(r.other_residual_ej, 0)) - sg.global_source_row_ej AS diff_ej,
  ROUND(100.0 * ((s.global_standardized_ej + COALESCE(r.other_residual_ej, 0)) - sg.global_source_row_ej)
        / NULLIF(sg.global_source_row_ej, 0), 4) AS diff_pct,
  ROUND(100.0 * (sg.global_source_row_ej - s.global_standardized_ej)
        / NULLIF(sg.global_source_row_ej, 0), 4) AS standard_vs_source_diff
FROM standardized s
LEFT JOIN residual_addback r
  ON r.metric = s.metric AND r.year = s.year
LEFT JOIN source_global sg
  ON sg.metric = s.metric AND sg.year = s.year
--ORDER BY s.metric, s.year;
ORDER BY standard_vs_source_diff DESC;



/*
  GEOGRAPHY & TOTALS — MODELING NOTES (applies to primary_consumption and ren_primary_consumption)

  1) Scope we analyze
     - I analyze standardized geographies: Country rows and "Region" area rows that the source reports when some countries aren’t itemized
       (e.g., Istern Africa, Other Europe). These "Region" rows are NOT rollups of countries; they are stand-alone area records that
       complement countries. They have standard UN region/subregion assignments.

  2) What I exclude from standard region/subregion charts
     - Economic groups (e.g., OECD, Non-OECD, European Union): labeled geo_type = 'Economic group'. These aggregates cross or duplicate
       countries and are excluded from regional/subregional rollups.
     - Residual/unallocated buckets (e.g., 'Other Middle East', 'Other Asia Pacific', 'USSR', 'Other CIS'): labeled geo_type = 'Residual/unallocated'.
       These cannot be mapped cleanly to standard regions; they are excluded from regional/subregional rollups.

  3) Global totals — which number I use where
     - Dashboards/Tableau: I compute Global from the SAME standardized rows I visualize (sum of countries + included area rows). This keeps
       denominators filter-aware and avoids drift.
     - Source 'Global' (provided by the dataset) is used only for QA/reconciliation. It includes small residual economic-group items
       (e.g., 'Other CIS') that I exclude from standardized geography.
     - Reconciliation result (2000-2023): Renewables difference ≈ 1.50%-2.02% (max 2.0239% in 2003); Primary difference ≈ 0.93%-1.11%
       (min 0.9327%, max 1.1106%). Adding back the residual ('Other CIS' etc. ) to standardized Global perfectly aligns with the source Global.
  4) Implementation guardrails
     - Filter analyses to geo_type IN ('Country','Region') for standardized geography; exclude 'Economic group' and 'Residual/unallocated'.
     - Leave missing country/tech values as NULL (do not zero-fill). SUM ignores NULLs; compute shares with NULL-safe denominators.

  TL;DR
     - Regions/subregions = Country + area rows only; economic groups and residuals are excluded.
     - Global in visuals = standardized sum (filter-aware). Source Global is documented separately via a small reconciliation check.
*/



    
    

 SELECT COUNT(year)
 FROM renewables_project.primary_consumption
 WHERE year >= 2000 AND value IS NULL; -- 24
 
 SELECT MAX(year)
 FROM renewables_project.primary_consumption; -- 2023



 SELECT COUNT(year)
 FROM renewables_project.ren_primary_consumption
 WHERE year >= 2000 AND value IS null; -- 3,290 records
 
 SELECT MAX(year)
 FROM renewables_project.ren_primary_consumption; -- 2023
 
 
SELECT DISTINCT dt.technology
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_technology dt ON rpc.tech_id = dt.tech_id;
 
/*
tehcnology data:
	Biofuels
	Wind energy
	Geothermal, Biomass, Other
	Solar energy
	Hydropower
	Nuclear
NOTE: Nuclear will not be included in renewables' calculations
 */



-- What % of total primary energy consumption is renewable each year? Also show renewable technology breakdown
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
    ) r 
    	ON t.year = r.year
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


/*
  Global Renewable Share in Primary Energy Consumption (2000–2023)

Between 2000 and 2007, the share of renewables in global primary energy consumption remained relatively flat, fluctuating between 7.3% and 7.8%, 
and only crossing 8% in 2008. Growth was slow from 2000 to 2011, with the share reaching just 9% by 2011.

Since 2011, the trend shifted to more sustained and accelerated growth: renewables’ share rose from 8.98% in 2011 to 14.56% in 2023. 
The largest single-year jump occurred in 2020, when renewables’ share increased by 1.17 percentage points. In 2023, renewables contributed 
90.2 exajoules—out of a total global primary energy use of 619.6 exajoules.

This acceleration marks a new phase in the energy transition, but renewables still supply just over 1/7th of global primary energy - a reminder 
that while progress is real, much remains to be done.

Note: Data coverage is robust for major economies and global aggregates, but some regional and country-level values remain incomplete. 
Global annual totals are presented for comparability.
 */




-- Technology breakdown: global, by year
SELECT
    rpc.year,
    dt.technology,
    SUM(value) AS ren_primary_consumption_ej,
    ROUND( 
    	100.0 * SUM(value)
    	/ NULLIF(SUM(SUM(value)) OVER (PARTITION BY year), 0),
    	2
    ) AS pct_share_of_year
FROM renewables_project.ren_primary_consumption rpc
JOIN renewables_project.dim_technology dt ON rpc.tech_id = dt.tech_id
JOIN renewables_project.dim_geo dg ON rpc.geo_id = dg.geo_id
WHERE rpc."year" >= 2000 AND dt.technology <> 'Nuclear' AND dg.geo_type = 'Global'
GROUP BY rpc.year, dt.technology
ORDER BY rpc.year, pct_share_of_year DESC;


/*
   Insights: Evolution of Renewable Primary Energy Mix (2000–2023)

	Hydropower has long dominated global renewable primary energy consumption, but its share is steadily declining as wind and solar scale up. 
	In 2000, hydropower accounted for over 90% of all renewable primary energy use. By 2023, that share had fallen to just under 44%.
	
	Wind and solar energy have experienced the most rapid growth. Wind’s share grew from about 1% in 2000 to over 24% in 2023, while solar rose 
	from nearly zero to 17% in the same period. Together, wind and solar now represent more than 41% of renewable primary energy consumption, 
	compared to just 1% at the turn of the century.
	
	Biofuels and "Geothermal, Biomass, Other" have also seen moderate increases, now making up about 5% and 10% of the mix, respectively, 
	but remain much smaller contributors than hydro, wind, or solar.
	
	This shift in the renewable energy mix reflects the rapid global deployment of modern renewables, especially in the power sector, driven 
	by falling costs and supportive policy. Hydropower remains the single largest contributor, but the era of wind and solar now shapes 
	the trajectory of global renewable energy growth.
	
	Data Highlights
	    - Hydropower: 90.7% (2000) -> 44.0% (2023)
	    - Wind energy: 1.1% (2000) -> 24.1% (2023)
	    - Solar energy: 0.04% (2000) -> 17.0% (2023)
	    - Biofuels: 1.5% (2000) -> 5.2% (2023)
	    - Geothermal, Biomass, Other: 6.6% (2000) -> 9.7% (2023)
 */




-- Which regions have the highest renewable share of primary energy?
-- NOTE: In this analysis 'Other CIS' and 'USSR' are not included in regional and global calculations, but it does not affect the validity of the analysis.

WITH subregional_total AS (
    SELECT
        dg.region_name,
        dg.sub_region_name AS subregion,
        pc.year,
        SUM(pc.value) AS total_primary_consumption_ej
    FROM renewables_project.primary_consumption pc
    JOIN renewables_project.dim_geo dg 
        ON pc.geo_id = dg.geo_id
    WHERE pc.year = 2023
      AND dg.geo_type IN ('Country', 'Region')
    GROUP BY dg.region_name, dg.sub_region_name, pc.year
),
global AS (
    SELECT 
        year,
        SUM(total_primary_consumption_ej) AS global_total_ej
    FROM subregional_total 
    GROUP BY year
),
renew AS (
    SELECT
        dg.sub_region_name AS subregion,
        rp.year,
        dt.technology,
        SUM(rp.value) AS ren_primary_consumption_ej
    FROM renewables_project.ren_primary_consumption rp
    JOIN renewables_project.dim_geo dg 
        ON rp.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt 
        ON rp.tech_id = dt.tech_id
    WHERE rp.year = 2023
      AND dt.technology <> 'Nuclear'
      AND dg.geo_type IN ('Country', 'Region')
    GROUP BY dg.sub_region_name, rp.year, dt.technology
),
renew_total AS (
    SELECT
        subregion,
        year,
        SUM(ren_primary_consumption_ej) AS total_ren_primary_consumption_ej
    FROM renew
    GROUP BY subregion, year
)
SELECT
   -- st.region_name,
    st.subregion,
    --st.year,
    ROUND(st.total_primary_consumption_ej, 2) AS total_primary_consumption_ej,
    ROUND(100.0 * st.total_primary_consumption_ej / NULLIF(g.global_total_ej, 0), 2) AS reg_pct_of_global,
   -- ROUND(rt.total_ren_primary_consumption_ej, 2) AS total_ren_primary_consumption_ej,
    ROUND(100.0 * rt.total_ren_primary_consumption_ej / NULLIF(st.total_primary_consumption_ej, 0), 2) AS ren_share_pct,
    r.technology,
   -- ROUND(r.ren_primary_consumption_ej, 2) AS ren_primary_consumption_ej,
    ROUND(100.0 * r.ren_primary_consumption_ej / NULLIF(rt.total_ren_primary_consumption_ej, 0), 2) AS tech_share_of_renewables
FROM subregional_total st
JOIN global g 
    ON st.year = g.year
JOIN renew_total rt 
    ON st.subregion = rt.subregion AND st.year = rt.year
JOIN renew r 
    ON st.subregion = r.subregion AND st.year = r.year
ORDER BY st.total_primary_consumption_ej DESC, tech_share_of_renewables DESC;
--ORDER BY reg_pct_of_global, tech_share_of_renewables DESC;
--ORDER BY ren_share_pct DESC, tech_share_of_renewables DESC;


/*
  	Primary Energy Consumption & Renewable Share by Subregion (2023):
    1.  High Consumption - Low Renewable Share
        The largest energy consumers in 2023 were Eastern Asia 206.01 EJ (33.29% of global primary energy) and Northern America 108.23 EJ (17.49%).
        However, these regions lag in renewable integration — Eastern Asia’s renewable share was only 14.86%, and Northern America’s was 13.93%, very close to global average (~14.6%).
        This means that areas where energy demand is highest, are not leading the transition towards renewables.
        
        Other high-demand but low renewable-share standouts:
         - Southern Asia: 57.29 EJ (9.26% of global) -> 7.88% renewables
		 - Eastern Europe: 43.79 EJ (7.08% of global) -> 7.51% renewables
 		 - Western Asia: 35.69 EJ (5.77% of global) -> 4.90% renewables
        
    2.  Renewable penetration Leaders
        Northern Europe stands out with 35.63% of primary energy use from renewables - the highest share globally, while total consumption was only 2.34% of global. 
        This reflects strong policy support, abundant hydro resources (Norway, Iceland) - source of 43.94% renewable primary energy, and also highly utilized wind energy (32.65%), 
        'Geothermal, Biomass, Other' contributed 15.96% of it, while Solar and Biofuels hold small share, 4.2% and 3.25%.
        
        'Latin America and the Caribbean' follows with 29.69% primary energy consumption from renewable sources, driven by hydro (61.07%), wind(12.35%). 
        Biofuels, Solar and 'Geothermal, Biomass, Other' almost equally contributed ~9% of the demand.
        
        Southern Europe: 2.33% of global, 23.06% of it were renewables. Well diversified renewable sources, Wind energy beign the most utilized - 32.23% of renewables.
        Western Europe: 4.6% of global, 21.58% of it renewables. Also well diversified renewable sources and wind energy sharing 37.69% of it.
		Australia & New Zealand: 1.11% of global, 18.39% - renewables. Small base, solid penetration.
        
    3.  Fossil-Heavy Holdouts
    	The most fossil dependant regions are also the least energy consumers - Central Asia (1.08% of total primary consumption) and Northern Africa (1.44%) - only 3-4% 
    	of consumed primary energy comes from renewables.
    	Followed by:
		Western Asia: 35.69 EJ (5.77%) -> 4.90% renewables.
		Southern Asia: 57.29 EJ (9.26%) -> 7.88% renewables.
    	
    4.	Hydropower Dependence vs. Technology Diversification
    	In many subregions, hydropower remains the leading renewable source. Data shows that hydro-dominant systems can achieve high renewable shares of primary energy 
    	where resource endowment is strong. However, hydropower is a mature and often site-constrained technology and is vulnerable to hydrological variability. 
    	Renewable diversification - notably into wind and solar supported by grid flexibility and storage - becomes essential to sustain growth in the renewable share once hydro 
    	potential is largely utilized. 
    	Note that diversification isn’t automatically linked to a high share: some diversified subregions still have low renewable shares because total fossil use remains 
    	large.
 */






