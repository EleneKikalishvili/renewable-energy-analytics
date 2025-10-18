/* ======================================================================
   File    : rq4_investments_and_costs.sql
   Purpose : Analyze public investments in renewable energy technologies over time, compare against fossil fuel investments,
             and look for potential correlation with renewable electricity costs.
   Author  : Elene Kikalishvili
   Date    : 2025-07-09
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 4: What role has public finance played in scaling renewables - and is it aligned with the 
   						cost-effectiveness and emissions reduction potential of different technologies?
   ============================================================================================================================ */


/*-----------------------------------------------------------------------------------------------------------------
   Important Note:
   
   This project focuses on public investment data from IRENA to analyze how governments and development finance institutions 
   have supported renewable energy over time. Public finance plays a strategic role in enabling early-stage deployment, filling 
   equity gaps in underserved regions, and supporting technologies that may not yet be attractive to private investors. 
   
   While private investments are essential to the clean energy transition, this analysis isolates the public finance layer to 
   explore whether it aligns with technology cost trends, generation potential, and emissions priorities.
   
   A follow-up project could expand this to include total investment flows, but for this study, public investments alone offer
   valuable insights into the policy and development dimensions of the energy transition.
----------------------------------------------------------------------------------------------------------------- */




-- Exploring investments table
SELECT *
FROM renewables_project.investments 
LIMIT 5;

-- Checking investments total and comparing it with IRENA's reported number on dashboard
SELECT sum(ROUND(amount_usd_million, 3))
FROM renewables_project.investments;


/*
  NOTE:
	During data preparation, exact-duplicate rows (identical across all columns) were removed to preserve referential integrity and 
	comply with database constraints that prevent duplication. While these rows are included in IRENA’s global investment totals, 
	their removal results in a slightly lower global total (~0.25% lower). After reviewing the impact and confirming the duplicates were not 
	differentiated by metadata, they were excluded to maintain schema clarity. This decision was made consciously and does not alter the overall 
	trends or conclusions drawn from the data.
 */


SELECT DISTINCT dg.geo_type, dt.category -- checking types of geographc locations and technology category
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id;

SELECT DISTINCT dg.geo_type, dg.geo_name, dt.category -- checking types of geographc locations and technology category
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE dg.geo_type <> 'Country';


-- checking if EU records are aggregates or distinct investments
SELECT i."year", i.project_id, dt.category, dg.geo_type, dg.geo_name  
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE (dg.geo_type = 'Country' OR dg.geo_type = 'Economic_group') AND dg.region_name = 'Europe'
ORDER BY i."year" DESC, i.project_id, dt.category,  dg.geo_type, dg.geo_name;



-- checking if Residual/unallocated records are aggregates or distinct investments
SELECT i."year", i.project_id, dt.category, dg.region_name, dg.geo_type, dg.geo_name, i.reference_date, i.amount_usd_million
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE dg.geo_type = 'Country' OR dg.geo_type = 'Residual/unallocated'
ORDER BY i."year" DESC, dg.region_name, i.project_id, dt.category,  dg.geo_type, dg.geo_name;



/*
	NOTE: 
		Both renewable and non-renewable energy investments data is available for countries, unspecified locations (Residual/unallocated, Unspecified, Multilateral), and economic group (EU).
		Economic_group data which is EU(27 countries) data is not an aggregate of eu countries recorded in the dataset. Investments made in EU economic group can be safely summed for global
		analysis since these records have unique project IDs from countries.
		Regional level analysis will include country data and Residual/unallocated ODA records.
		Multilateral and "Unspecified, developing countries" will be included in global analysis only.
*/


-- Checking technology groups
SELECT DISTINCT dt.category, dt.group_technology 
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id;

/*
 	NOTE: 
 		Renewable technologies: Hydropower, Geothermal energy, Solar energy, Wind energy, Marine energy, Bioenergy, and Multiple renewables
 		Non-renewable technologies: Fossil fuels, Nuclear, Pumped storage and Other non-renewable energy.
 		
 		For my analysis focus will be comparing Renewables VS Fossil fuel investments.
 */





/*
    Where did public finance go?
	What technologies and regions received the most public investment? 
	Identify top-funded technologies.
	Analyze shift in priorities over time.
*/

-- Checking technologies
SELECT DISTINCT dt.*
FROM renewables_project.investments i 
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE category = 'Non-renewable';



-- Calculating cummulative total investments in 2000 - 2020 period
SELECT
	ROUND(SUM(i.amount_usd_million), 3) AS total_investment_usd_mn,
    ROUND(SUM(CASE
	    		WHEN dt.category = 'Renewable' THEN i.amount_usd_million 
	    	  END), 3) AS renewables_investment_usd_mn,
    ROUND(SUM(CASE 
	    		WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million 
	    	  END), 3) AS fossil_fuels_investment_usd_mn,
    ROUND(SUM(CASE 
	    		WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million 
    		  END), 3) AS nuclear_and_other_investment_usd_mn, -- Includes, nuclear, pumped storage, and non-renewable municipal waste
    ROUND(SUM(CASE 
	    		WHEN dt.category = 'Renewable' THEN i.amount_usd_million 
    		  END) / SUM(i.amount_usd_million) * 100, 2) AS renewables_pct,
    ROUND(SUM(CASE 
	    		WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million 
	    	  END) / SUM(i.amount_usd_million) * 100, 2) AS fossil_pct,
    ROUND(SUM(CASE 
	    		WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million 
	    	  END) / SUM(i.amount_usd_million) * 100, 2) AS nuclear_and_other_pct
FROM renewables_project.investments i
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id;

/*
  NOTE: 
	Between 2000 and 2020, a total of $263.3 billion (49.6%) in public investment was directed toward renewable energy technologies, 
	closely followed by $245.0 billion (46.1%) for fossil fuels. Investments in nuclear and other non-renewable technologies 
	(including pumped storage and municipal waste) totaled just $22.9 billion (4.3%). This demonstrates a near-parity between public 
	funding for renewables and fossil fuels over the last two decades, with renewables slightly leading.
 */





-- Exploring trends over years
WITH base AS (
    SELECT 
        i."year", 
        SUM(CASE WHEN dt.category = 'Renewable' THEN i.amount_usd_million END) AS renewables,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million END) AS fossil_fuels,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million END) AS nuclear_and_other
    FROM renewables_project.investments i 
    JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    GROUP BY i."year"
)

SELECT 
    b."year",

   /* -- Investment amounts
    ROUND(b.renewables, 3) AS renewables_investment_usd_mn,
    ROUND(b.fossil_fuels, 3) AS fossil_fuels_investment_usd_mn,
    ROUND(b.nuclear_and_other, 3) AS nuclear_and_other_investment_usd_mn, */

    -- Total investment
    ROUND(COALESCE(b.renewables, 0) + COALESCE(b.fossil_fuels, 0) + COALESCE(b.nuclear_and_other, 0), 3) AS total_investment_usd_mn,

    -- Share of each category
    ROUND(100 * b.renewables / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS renewables_share_pct,
    ROUND(100 * b.fossil_fuels / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS fossil_fuels_share_pct,
    ROUND(100 * b.nuclear_and_other / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS nuclear_and_other_share_pct,

    -- Year-over-year % change in renewables
    ROUND(100 * (b.renewables - LAG(b.renewables) OVER (ORDER BY b."year")) / NULLIF(LAG(b.renewables) OVER (ORDER BY b."year"), 0), 2) AS renewables_yoy_pct_change,
    -- Year-over-year % change in fossil fuels
    ROUND(100 * (b.fossil_fuels - LAG(b.fossil_fuels) OVER (ORDER BY b."year")) / NULLIF(LAG(b.fossil_fuels) OVER (ORDER BY b."year"), 0), 2) AS fossil_fuels_yoy_pct_change,
    
    -- 3 year moving averages
    ROUND(AVG(b.renewables) OVER (ORDER BY b."year" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 3) AS renewables_3yr_avg_usd_mn,
    ROUND(AVG(b.fossil_fuels) OVER (ORDER BY b."year" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 3) AS fossil_fuels_3yr_avg_usd_mn

FROM base b
ORDER BY b."year" DESC;


/*
 Insights: Investment Priorities Over Time
	
	Between 2000 and 2020, global public investment in renewables reached $263.3B, narrowly surpassing fossil fuels at $244.9B. Since 2017, 
	renewables have consistently attracted more funding, even as overall investment volumes declined. Fossil fuel investment spiked dramatically in 2016 
	(reaching 57% of the total), then collapsed by over 50% in 2017, while renewables grew. By 2020, renewables accounted for over 75% of all public energy 
	investments - more than three times the share of fossil fuels - as fossil investment volumes dropped by nearly two-thirds compared to 2019.

	The 3-year moving average for renewables stabilized in the $21–23B range from 2016 to 2018, before falling to $13.5B by 2020. In contrast, fossil fuel 
	investment’s 3-year average plunged to just $7.8B by 2020, down from over $20B just a few years prior.
	
	Notably, the 3-year moving average for renewable energy investment has exceeded that for fossil fuels every year since 2012, 
	highlighting the persistent shift in public finance priorities well before annual investment volumes reflected the same trend.

	These shifts highlight a long-term realignment of public finance priorities, with renewables overtaking legacy energy systems, particularly after 2016. 
	Temporary dips in investment since 2018 appear cyclical rather than structural, with the pandemic in 2020 accelerating the divergence between renewables and fossil fuels.
 */




-- Top funded technologies and shift over time
WITH tech_investments AS (
    SELECT 
        CASE 
            WHEN dt.category = 'Renewable' THEN 'Renewables'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN 'Fossil fuels'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN 'Other Non-renewables'
        END AS category,
                -- Hybrid aggregation: group renewables, show non-renewables by tech
        CASE
            WHEN dt.category = 'Renewable' THEN dt.group_technology
            ELSE dt.technology
        END AS tech_group_custom,
        i.amount_usd_million
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt 
        ON i.tech_id = dt.tech_id
),
tech_total AS (
    SELECT 
        category,
        tech_group_custom,
        ROUND(SUM(amount_usd_million), 1) AS total_investment_usd_mn
    FROM tech_investments
    GROUP BY category, tech_group_custom
)
SELECT 
    category,
    tech_group_custom,
    total_investment_usd_mn,
    ROUND(100 * total_investment_usd_mn / SUM(total_investment_usd_mn) OVER (), 1) AS pct_share_of_total
FROM tech_total
-- ORDER BY category, total_investment_usd_mn DESC;
ORDER BY pct_share_of_total DESC;

/*
 Notes:

 	Between 2000 and 2020, hydropower was the largest recipient of public investment among all renewable technologies, attracting $107.3 billion - 
 	accounting for 20.2% of all public energy investments.
 	
	Within fossil fuels, oil received the most public funding ($83.5 billion, 15.7%), followed by coal & peat (13.9%), and natural gas (11.1%).
	
	Other significant categories included “multiple renewables” (8.9% - covering commitments that support several renewable technologies simultaneously),
	wind (8.9%), and solar (7.8%). Unspecified fossil fuel investments (“fossil fuels n.e.s.”) accounted for 5.4%.
	
	Other renewable categories like Bioenergy and Geothermal received 1.9% and 1.8% of total funding, and marine energy received the least -
	just 4.1 million in 20 years.
	
	In the ‘other non-renewables’ category, nuclear energy led with $22.4 billion (4.2%). While municipal waste and pumped storage both received very small
	share - 316.5 ad 181.2 million respectively - that is close to 0 share of total investments.
	
	
 */


WITH tech_investments AS (
    SELECT 
        i.year,

        CASE 
            WHEN dt.category = 'Renewable' THEN 'Renewables'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN 'Fossil fuels'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN 'Other Non-renewables'
        END AS category,

        -- Hybrid: grouped renewables, detailed non-renewables
        CASE
            WHEN dt.category = 'Renewable' THEN dt.group_technology
            ELSE dt.technology
        END AS tech_group_custom,

        i.amount_usd_million
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt 
        ON i.tech_id = dt.tech_id
    ORDER BY "year" 
),
yearly_totals AS (
    SELECT 
        year,
        category,
        tech_group_custom,
        SUM(amount_usd_million) AS total_investment_usd_mn
    FROM tech_investments
    GROUP BY year, category, tech_group_custom
),
with_pct AS (
    SELECT 
        *,
        -- % share of total investment per year
        ROUND(100 * total_investment_usd_mn / 
              SUM(total_investment_usd_mn) OVER (PARTITION BY year), 2) AS pct_share_of_year
    FROM yearly_totals
),
final AS (
    SELECT 
        year,
        category,
        tech_group_custom,
        total_investment_usd_mn,
        pct_share_of_year,

        -- YoY % change in total investment
        ROUND(100 * (total_investment_usd_mn - LAG(total_investment_usd_mn) OVER (
            PARTITION BY tech_group_custom ORDER BY year
        )) / NULLIF(LAG(total_investment_usd_mn) OVER (
            PARTITION BY tech_group_custom ORDER BY year
        ), 0), 2) AS yoy_investment_pct_change,
        -- YoY % change in share of investment
        ROUND(pct_share_of_year - LAG(pct_share_of_year) OVER (
            PARTITION BY tech_group_custom ORDER BY year
        ), 2) AS yoy_share_pct_change

    FROM with_pct
)
SELECT *
FROM FINAL
--WHERE category = 'Fossil fuels'
--WHERE tech_group_custom = 'Hydropower'
WHERE  category = 'Renewables' AND tech_group_custom <> 'Hydropower'
ORDER BY year, total_investment_usd_mn DESC;



/*
 Insights:
 	Public Investment Trends in Renewable and Non-Renewable Technologies (2000–2020)
 	Summary of Findings
	    1. Renewable hydropower has consistently received the highest share of public investment, particularly in the early 2000s, 
	       but its % change is investments and share has gradually declined since 2013 with one exception in 2017 when investment grew by 232.5% compared to previous year
	       and dropped again next year by 60%.
	       Through years 2000-2010 share of hydropower's investments per year averaged 27.3%, while after 2010 - 19.3%. 
	       Though, there is no steady funding cycles and patterns, it can be said that hydropower remained priority but lost dominance over time. 
	     		    
    	2. In 2000, public investment in solar, wind, and other non-hydro renewables was minimal, with less than 1% allocated to each individually. 
    	   The majority of early public funding - 30% - flowed into multi-technology programs (‘multiple renewables’). 
    	   Since then up until 2010, each renewables' (excl. Hydropower) % share of yearly total investments remained low almost always under 10%
    	   with exception in 2005 - "Multiple renewables" share of total was 12.8% - and more often under 5%. 
    	   Ivestments in multi-technology programs dominated almost every year, reflecting a phase of technology-neutral exploration.
    	   In 2010s, solar and wind emerged as clear policy and investment priorities:
		      - Particularly Wind energy consistantly received over 10% share of investments in years 2010-2015 and 2017, and was a dominant investment choice
		        in renewables' category, with highest share in 2014 - 16.4%. 
		      - In 2016 Solar energy spiked receiving 10,417.2 million in investments - 16.7% of total
		      - since 2017 till 2020 on average wind received 10% of investments each year, and solar on average 13% of total each year.
		      - Solar spiked again in 2020 over 20% share in investments.
		   "Multiple renewables" continued consistent funding and stayed dominant most of the time - signaling multi-tech, programmatic, or flexible finance mechanisms. 
		   Especially in 2016-2020 period, % share of yearly investments in "Multiple renewables" has been increasing, In 2018-2020 this category was again dominant in 
		   renewables' investments and reached highest % share in 2020 - 27%.
		   
		   Bioenergy and geothermal technologies received minor shares, with small absolute investments and minimal year-over-year share growth - suggesting lower policy priority or less commercial maturity.
		        
	    3. Fossil fuels as a category saw significant public funding in the early periods, especially:
	    	- In 2000 -2006 period Fossil fuels n.e.s. (unspecified fossil fuel programs, exploration, blended energy) category consistantly received largest share in investments and dominated, 
	    	  with 2004 exception when Natural gas took lead. This makes it harder to pinpoint tech-specific trends in early years.
	    	- Natural gas was largest invested fossil tech during that period, followed by coal and peat, and oil.
		    - Oil spiked in 2007 and 2009 receiving largest investment share of 47.7% and quickly dropped to 0.45% in 2010
		    - till 2015 there was no one dominant fossil tech.
		    - After 2014, funding for fossil fuels declined both in absolute terms and share of public investment.
		    - In 2017 till 2019 coal and peat was a dominant investment choice followed by Natural gas, but in 2020 Natural gas retained it's stable share - 18.7% (81.2% and 15.2% from previous years), 
		      while coal dropped significantly to 2.5%, and oil almost vanished - 0.74%.

	    4. Nuclear remained the dominant “other non-renewable” throughout all years, though its investment share remained below 10% and did not grow substantially over time.
	    
 */



-- checking lcoe data
SELECT *
FROM renewables_project.vw_technology_cost_trends

SELECT DISTINCT technology
FROM renewables_project.vw_technology_cost_trends
/*
 Available tech:
		Bioenergy
		Geothermal energy
		Hydropower
		Offshore wind energy
		Onshore wind energy
		Solar photovoltaic
		Solar thermal energy
years: 2010-2023
 */

-- checking technology in investments table
SELECT DISTINCT dt.technology 
FROM renewables_project.investments i 
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE dt.category = 'Renewable';

/*
 Available tech:
		Offshore wind energy
		Solar thermal energy
		Multiple renewables
		Biogas
		Wind energy  --investments in wind aggregated. No specific tech info available
		Geothermal energy
		Solid biofuels
		Renewable hydropower
		Bioenergy
		Liquid biofuels
		Renewable municipal waste
		Onshore wind energy
		Marine energy
		Solar photovoltaic
years: 2000-2020
 */


SELECT DISTINCT dt.* 
FROM renewables_project.dim_technology dt 
WHERE dt.category = 'Renewable'
ORDER BY group_technology;

-- Checking hydropower records in technology table
SELECT DISTINCT dt.* 
FROM renewables_project.dim_technology dt 
WHERE group_technology = 'Hydropower';

/*
 	NOTE: investments data has only "Renewable hydropower" records while costs data does not specify and has been defined as "Agg. hydropower", 
 	potentially including Mixed Hydro Plants.
 	The comparison assumes these categories are still valid to compare and analyze.
 */


/*
 2. Is public investment aligned with cost-effectiveness?
	Did the most-funded technologies also experience the biggest LCOE declines?
*/

-- Costs data only has CSP data and not Solar thermal data in general

WITH tech_investments AS (
    SELECT 
    	CASE 
    		WHEN dt.group_technology IN('Hydropower', 'Bioenergy') THEN dt.group_technology
    		WHEN dt.sub_technology = 'Solar thermal energy' THEN NULL  -- I need CSP records only 
    		ELSE dt.technology
    	END AS technology,
        i.amount_usd_million AS tech_investment
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt 
        ON i.tech_id = dt.tech_id
    WHERE dt.category = 'Renewable'
      AND i.year BETWEEN 2010 AND 2020
),
investment_totals AS (
	SELECT 
		technology,
		SUM(tech_investment) AS total_investment_usd_mn
	FROM tech_investments
	WHERE technology IS NOT NULL 
	GROUP BY technology 
),
latest_lcoe AS (
    SELECT DISTINCT ON (technology)
        technology,
        rel_change_since_2010_lcoe_pct,
        lcoe_usd_per_kwh
    FROM renewables_project.vw_technology_cost_trends
    WHERE year = 2020 
)
SELECT 
	CASE 
		WHEN i.technology = 'Solar thermal energy' THEN 'Concentrated solar power'
		ELSE i.technology
	END technology,
    i.total_investment_usd_mn,
    l.rel_change_since_2010_lcoe_pct,
    l.lcoe_usd_per_kwh
FROM investment_totals i
JOIN latest_lcoe l ON i.technology = l.technology 
ORDER BY i.total_investment_usd_mn DESC; 



/*

Insights: Public Investment vs. LCOE Trends (2010–2020)

Strategic Alignment with Cost-Effective Technologies
------------------------------------------------------------
Public investment has generally been well-aligned with cost-effective renewable technologies:
- Solar PV and onshore wind received substantial public funding and achieved LCOE declines of –87% and –64%, respectively.
- By 2020, these were among the cheapest renewable technologies, and by 2023, they had further solidified their cost leadership.
- This indicates that public finance has played a catalytic role in scaling the most cost-responsive solutions.


Hydropower: High Funding, Rising Costs
------------------------------------------------------------
- Hydropower received the largest share of cumulative public investment (2000–2020), yet its LCOE increased by 18%.
- This likely reflects: aging infrastructure, rising costs of new sites, and regulatory/sustainability burdens.
- These investments may have focused more on regional access and infrastructure than on cost efficiency.

- Although hydropower led in total investment, public funding has declined steadily since 2013 (except for a spike in 2017).
- In contrast, solar and wind show a clear upward trajectory, indicating a shift in public funding priorities:
    - From legacy technologies like hydro to scalable, fast-declining options like solar PV and wind.
    
    
Selectivity and Exceptions in Public Funding
------------------------------------------------------------
Technologies with limited scalability, complex deployment needs, or slower cost improvements received less funding:
- Bioenergy saw minimal cost reduction.
- Geothermal experienced a slight LCOE increase.
- Solar Thermal is a notable exception:
    - Received just $2.3 billion but achieved a 69% LCOE reduction.
    - Likely driven by private innovation or niche deployments.
    - Despite progress, it remained the most expensive renewable in 2020 ($0.122/kWh) and 2023.
    

2020 vs. 2023: Cheapest Renewable Technologies by Global LCOE Median
------------------------------------------------------------

  2020:
    1. Onshore Wind   - $0.040
    2. Hydropower     - $0.050
    3. Solar PV       - $0.060
    4. Geothermal     - $0.062
    5. Bioenergy      - $0.080
    6. Offshore Wind  - $0.090
    7. Solar Thermal  - $0.122

  2023:
    - Solar PV became the cheapest at $0.044.
    - Hydropower rose to $0.057, dropping to 3rd place.
    - Ranking otherwise remained stable.

Final Reflection
------------------------------------------------------------
This analysis focuses solely on public investment. Despite excluding private finance, it offers valuable insight into 
how governments and institutions have prioritized funding. The strong alignment with LCOE declines in technologies 
like solar PV and wind highlights the effectiveness of public capital. At the same time, exceptions such as solar 
thermal demonstrate the important role of market forces and private innovation in the energy transition.
*/




SELECT DISTINCT dg.geo_type, dg.geo_name, dg.region_name, dg.sub_region_name -- checking types of geographc locations and technology category
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE dg.geo_type = 'Residual/unallocated';

SELECT DISTINCT sub_region_name
FROM renewables_project.dim_geo;


SELECT DISTINCT dg.geo_type, dg.region_name -- checking types of geographc locations
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg 
	ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
ORDER BY dg.region_name;





-- Total investment per region (excluding Multilateral/Unspecified)
SELECT
    g.region_name,
    SUM(i.amount_usd_million) AS total_investment,
    SUM(i.amount_usd_million) FILTER (
        WHERE g.geo_type = 'Residual/unallocated'
    ) AS residual_investment,
    ROUND(
        COALESCE(
            SUM(i.amount_usd_million) FILTER (
                WHERE g.geo_type = 'Residual/unallocated'
            ), 0
        )
        /
        NULLIF(SUM(i.amount_usd_million), 0)
        * 100, 2
    ) AS residual_pct
FROM
    renewables_project.investments i
    JOIN renewables_project.dim_geo g ON i.geo_id = g.geo_id
WHERE
    g.region_name IS NOT NULL
    AND g.geo_type NOT IN ('Multilateral', 'Unspecified')
GROUP BY
    g.region_name
ORDER BY
    g.region_name;


/*
Notes for README
Treatment of Residual/Unallocated Investment Records

In line with IRENA’s official reporting practice, regional public investment totals in this analysis include records classified as “residual/unallocated”—that is, 
investments assigned to a region but not attributable to a specific country or subregion.

Residual/unallocated records account for only a small share of each region’s total public renewable energy investments:

Region	Residual/Unallocated (%)
Africa	2.96%
Americas	1.01%
Asia	0.81%
Europe	0.26%
Oceania	3.38%

This low share (<3.5% in all regions) ensures that regional trend comparisons are robust and not meaningfully affected by data allocation uncertainty. 
For subregional and country-level analyses, only fully assigned records are used; “multilateral” and “unspecified” investments are excluded from 
regional totals and reported separately.
 */


/*
 3. Are public funds flowing to low-income or underserved regions?
*/

--Comapring renewable investments VS Fosil fuel investments on subregional level
WITH all_investments AS (
	SELECT 
		dg.sub_region_name,
		dt.category,
		dt.group_technology,
		amount_usd_million
	FROM
        renewables_project.investments i
        JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
        JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    WHERE
        dg.sub_region_name IS NOT NULL
        AND dg.geo_type NOT IN ('Unspecified', 'Multilateral')
),
subregion_total AS (
    SELECT
    	sub_region_name,
        SUM(amount_usd_million) AS reg_total_investment
    FROM
        all_investments
    GROUP BY
        sub_region_name
),
global_total AS (
    SELECT SUM(reg_total_investment) AS world_total_investment
    FROM subregion_total
),
tech_by_subregion AS (
    SELECT
        sub_region_name,
        SUM(CASE WHEN category = 'Renewable' THEN amount_usd_million END) AS renewables,
        SUM(CASE WHEN category = 'Non-renewable' AND group_technology = 'Fossil fuels' THEN amount_usd_million END) AS fossil_fuels,
        SUM(CASE WHEN category = 'Non-renewable' AND group_technology <> 'Fossil fuels' THEN amount_usd_million END) AS nuclear_and_other
    FROM
        all_investments
    GROUP BY
        sub_region_name
)
SELECT
    s.sub_region_name,
    ROUND(s.reg_total_investment / 1000, 1) AS reg_total_investment_bn,
    ROUND(100.0 * s.reg_total_investment / gt.world_total_investment, 1) AS pct_of_world_total,
    ROUND(100.0 * tb.renewables / s.reg_total_investment, 1) AS renewables_pct,
    ROUND(100.0 * tb.fossil_fuels / s.reg_total_investment, 1) AS Fossil_fuels_pct,
    ROUND(100.0 * tb.nuclear_and_other / s.reg_total_investment, 1) AS nuclear_other_pct
FROM
    subregion_total s
    JOIN global_total gt ON 1=1
    JOIN tech_by_subregion tb ON s.sub_region_name = tb.sub_region_name
ORDER BY
    s.reg_total_investment DESC, s.sub_region_name;


/*
 Insights (2000–2020):
 Top 5 largely invested regions:
 	Largest share - 141 billion USD - 26.9% of total public investments went to Latin America and the Caribbean region - of which 59.4% was renewables and 40.5% fossil fuels.
 	Sub-Saharan Africa recieved 84.3 billion total investments amounting 16% of total - of which 61.3% went to renewables.
 	Southern Asia received 13.9% of total investments - 72.8 billion - of which 42.8% was renewables, 45% fossil fuels, and 12.2% nuclear and other non-renewable investments.
 	South-eastern Asia received 55 billion - 10.5% of total. Majority of which (62.2%) went into fossil fuels.
 	Eastern Europe received 46.1 billion - 8.8% - of which 86.8% was for fossil fuels and only 11.6% went to renewables.
 	
 Least invested regions:
	 Oceania region - Melanesia, Polynesia, Micronesia - only received 1.1 billion USD in total. Majority of the investments went to renewables. 
	 In Melanesia subregion 96.3% were renewable investments, in Polynesia - 80% and in Micronesia - 73.6%.
	 
	 North America also received very small amount of public investments - 0.7 billion - which amounts to roughly 0.1% of total. Though 99% of it was in renewables and rest in "Nuclear and other" category.
	 
	 Eastern Asia and Western Europe also received small share of total investments - 1.3% and 1.6% of total respectively. Majority of which was in renewables - In Western Europe 98%, and In Eastern Asia - 75%.
 
 Regions where investments went mostly into fossil fuels:
 	Eastern Europe where 46.1 billion USD was invested in energy - 9% of total - received 86.8% of it in fossil fuels.
 	Central Asia where 19.2 billion (3.7%) of public investments were made, received 82.9% of it in fossil fuels.
 	South-eastern Asia another largely invested region, received 62.2% in fossil fuels.
 */





-- Which regions have received largest investments in renewables and what are top invested technologies in those regions
WITH base AS (
	SELECT 
		i.amount_usd_million,
		dg.region_name,
		dg.sub_region_name,
		CASE 
    		WHEN dt.group_technology IN('Hydropower', 'Bioenergy') THEN dt.group_technology
    		ELSE dt.technology
    	END AS technology
	FROM
        renewables_project.investments i
        JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
        JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    WHERE
        dg.sub_region_name IS NOT NULL
        AND dg.geo_type NOT IN ('Unspecified', 'Multilateral')
        AND dt.category = 'Renewable'
),
subregion_totals AS (
    SELECT
    	sub_region_name,
        SUM(amount_usd_million) AS reg_total_investment
    FROM
        base
    GROUP BY
        sub_region_name
),
global_total AS (
    SELECT SUM(reg_total_investment) AS world_total_investment
    FROM subregion_totals
),
tech_by_subregion AS (
    SELECT
        sub_region_name,
        technology,
        SUM(amount_usd_million) AS tech_investment
    FROM
        base
    GROUP BY
        sub_region_name, technology
)
SELECT
    s.sub_region_name,
    ROUND(s.reg_total_investment/1000, 3) AS reg_total_investment_bn,
    ROUND(100.0 * s.reg_total_investment / gt.world_total_investment, 2) AS pct_of_world_total,
    tb.technology,
    ROUND(tb.tech_investment, 3) AS tech_investment_bn,
    ROUND(100.0 * tb.tech_investment / s.reg_total_investment, 2) AS pct_of_subregion_total
FROM
    subregion_totals s
    JOIN global_total gt ON 1=1
    JOIN tech_by_subregion tb ON s.sub_region_name = tb.sub_region_name
ORDER BY
    s.reg_total_investment DESC, s.sub_region_name, tb.tech_investment DESC;


/*
 Insights (2000–2020):
 	Latin America and the Caribbean receieved largest 32.54% of renewable public investments of which Hydropower had largest share of 45.5% - 38 billion USD.
 	Onshore wind energy got 20% of it - 16.9 billion, 12% of investments went to "multiple renewables" amounted to 10 billion. 
 	11.5% of those was invested to Solar PV - 9.6 billion. Rest went to Bionergy (5.9%), geothermal (3.4%), unspecified wind investments accounted for 1.3% - 1.08 billion,
 	Offshore wind received 0.17 billion from region's renewable investments, Solar thermal - 2.6 million, and marine energy 0.08 million.
 	
 	Sub-Sharan Africa received 20% of renewable investments around the world. Hydropower was a dominant technology here too receiving 62.2% of regional investments - 32 billion,
 	"Multiple renewables" catgeory is second largest renewable investment in this region too amounting almost 14% of regional investments - 7 billion. Followed by Solar PV 12.5% - 6.5 billion,
 	rest of it went to Geothermal - 2.5 billion, Onshore wind - 1.5 billion, Solar thermal, Bioenergy and Marine energy.
 	
 	We see similar investment distribution in Southern Asia that received 12% of all renewable invetsments. Hydropower having 44.5% of it, 22.6% went to "Multiple renewables",
 	Soalr PV receiving 22.5%. Onshore wind almost 5% share, 4.2% went to unspecified wind energy technologies, and rest received less than 1% - Bioenergy, Geothermal, Solar thermal and marine energies.
 	
 	Next in the list comes South-eastern Asia that received almost 8% share of global total renewable investments, Hydropower taking 63% of it, and Geothermal -15.8%, 
 	followed by "Multiple renewables" category almost 10%, and Solar PV - 7.5%.
 	
 	North africa received very small share of renewable investments that is 5.2%. 42% of it went to Solar PV - 5.7 billion, Wind energy investments received 19.4% of it,
 	"Multiple renewables" category - 18.6%, and Hydropower - 14.6%. very small share of this regional investments went to  Onshore wind, Geothermal, solar thermal and bioenergy and marine energy.
 	
 	Interesting to see in Northern Europe that received 5% of global renewable investments, Offshore wind recieved 55.6% of it - 7.3 billion. followed by bioenergy - 17.5% and Onshore wind 13%.
 	Hydropower only got 338.9 million almost 9% of it. Geothermal, "Multiple renewables", Solar PV, and Marine energy received the rest.
 	
 	In summary, Latin America and the Caribbean received the largest share (32.5%, $83.7B) of global renewable public investments, with hydropower accounting for nearly half (45.5%, $38B) of 
 	the region’s total. Onshore wind (20%), “multiple renewables” programs (12%), and solar PV (11.5%) were also significant, while all other technologies made up less than 6% each.

    Northern Europe stands out for its focus on offshore wind, which received over half (55.6%) of all renewable investment in the region, while bioenergy (17.5%) and onshore wind (13%) 
    also attracted substantial funding.
 	
 */






-- Biggest donors
WITH total_investments AS ( 
    SELECT SUM(amount_usd_million) AS total_mn
    FROM renewables_project.investments
),
donor_investments AS ( 
    SELECT 
        pl.donor,
        SUM(i.amount_usd_million) AS donor_total_mn
    FROM renewables_project.investments i
    JOIN renewables_project.project_lookup pl ON pl.project_id = i.project_id
    GROUP BY pl.donor
),
categories AS ( 
    SELECT 
        pl.donor,
        SUM(CASE WHEN dt.category = 'Renewable' THEN i.amount_usd_million ELSE 0 END) / 1000 AS renewables_bn,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million ELSE 0 END) / 1000 AS fossil_fuels_bn,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million ELSE 0 END) / 1000 AS nuclear_and_other_bn
    FROM renewables_project.investments i
    JOIN renewables_project.project_lookup pl ON pl.project_id = i.project_id
    JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    GROUP BY pl.donor
)
SELECT 
    RANK() OVER (ORDER BY don.donor_total_mn DESC) AS donor_rank,
    don.donor,
    ROUND(cat.renewables_bn, 3) AS renewables_bn_usd,
    ROUND(cat.fossil_fuels_bn, 3) AS fossil_fuels_bn_usd,
    ROUND(COALESCE(cat.nuclear_and_other_bn,0), 3) AS nuclear_and_other_bn_usd,
    ROUND(don.donor_total_mn / 1000, 3) AS donor_total_bn_usd,
    ROUND(100.0 * don.donor_total_mn / tot.total_mn, 1) AS pct_of_total
FROM
    total_investments tot
    JOIN donor_investments don ON 1=1
    JOIN categories cat ON don.donor = cat.donor
ORDER BY pct_of_total DESC;

/* 
 
 Top Public Energy Donors (2000–2020)

The five largest public donors together accounted for over 70% of all public energy investments worldwide:
    1.    China was by far the largest single donor, providing 43.8% of all tracked public investments - $161.2 billion to fossil fuels, $54.6 billion to renewables,
    	  and $16.7 billion to nuclear and other technologies.
    2.    Brazil contributed 10% of the global total, with the vast majority ($43.4 billion) invested in renewables and $9.8 billion in fossil fuels.
    3.    Japan ranked third (6.4%), investing $21.4 billion in fossil fuels and $12.6 billion in renewables.
    4.    EU Institutions made up 6% of the total ($27.2 billion for renewables, $3.5 billion for fossil fuels, $1.1 billion for nuclear and other).
    5.    The International Bank for Reconstruction and Development (World Bank Group) held a 4.1% share ($11.7 billion renewables, $10 billion fossil fuels).

Multilateral development banks (e.g., Asian Development Bank, International Finance Corporation) and major economies such as Germany and the United States round out the top ten donors,
each contributing 2 - 3.5% of total public investments.

The data highlights the dominant role of state and multilateral finance in shaping the global energy transition - with a handful of donors responsible for the vast majority of tracked public capital allocations.
 
 */


















