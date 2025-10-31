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



/* ================================================================================================
   SECTION 1: QA & Data Exploration - Public Investments Dataset
   ================================================================================================ */

-- DE: Preview sample records
SELECT * 
FROM renewables_project.investments
LIMIT 5;

-- DE: Check total investment vs IRENA reported dashboard total
SELECT 
    ROUND(SUM(amount_usd_million), 2) AS total_usd_million
FROM renewables_project.investments;

/*
  NOTE:
    During data preparation, exact duplicate rows (identical across all columns) were removed 
    to preserve referential integrity and comply with database constraints. While these rows 
    are included in IRENA’s reported global totals, their removal results in a slightly lower 
    global total (~0.25% lower). After confirming the duplicates were not differentiated by 
    metadata, they were excluded to maintain schema clarity. This does not alter the overall 
    trends or conclusions.
*/


-- DE: Check available geographic and technology classifications
SELECT DISTINCT dg.geo_type, dt.category 
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id;

-- QA: Inspect non-country records (Residual, Unallocated, Economic groups)
SELECT DISTINCT dg.geo_type, dg.geo_name, dt.category 
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE dg.geo_type <> 'Country';


-- QA: Verify if EU records are aggregates or unique investments
SELECT 
    i.year, i.project_id, dt.category, dg.geo_type, dg.geo_name  
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE (dg.geo_type = 'Country' OR dg.geo_type = 'Economic_group') 
  AND dg.region_name = 'Europe'
ORDER BY i.year DESC, i.project_id, dt.category, dg.geo_type, dg.geo_name;


-- QA: Verify if Residual/unallocated records are distinct or aggregated
SELECT 
    i.year, i.project_id, dt.category, dg.region_name, dg.geo_type, dg.geo_name, 
    i.reference_date, i.amount_usd_million
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE dg.geo_type IN ('Country', 'Residual/unallocated')
ORDER BY i.year DESC, dg.region_name, i.project_id, dt.category, dg.geo_type, dg.geo_name;


-- DE: Inspect Residual records
SELECT DISTINCT dg.geo_type, dg.geo_name, dg.region_name, dg.sub_region_name 
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE dg.geo_type = 'Residual/unallocated';


/*
  NOTES: 
    Both renewable and non-renewable energy investments include countries, 
    unspecified locations (Residual/unallocated, Unspecified, Multilateral), 
    and economic group (EU).
    
    Some Residual/unallocated records have sub_region_name assigned, some not. 
   	1 record also doesn't have region_name assigned. 

    - Economic_group data (EU) is not an aggregate of individual EU country entries.
      These can safely be included in global analysis since their project IDs are unique.
    - Regional analysis - includes Country + Residual/unallocated ODA records.
    - Subregional analysis - For consistency, includes country level data only.
    - Global analysis   - includes all records (Country, Residual/unallocated, Multilateral, EU, Unspecified).
*/


-- QA: Regional totals & residual/unallocated share (methodological check for subregional analysis)
SELECT
    g.region_name,
    ROUND(SUM(i.amount_usd_million), 2) AS total_investment_usd_mn,
    ROUND(SUM(i.amount_usd_million) FILTER (WHERE g.geo_type = 'Residual/unallocated'), 2) AS residual_investment_usd_mn,
    ROUND(
        COALESCE(SUM(i.amount_usd_million) FILTER (WHERE g.geo_type = 'Residual/unallocated'), 0)
        / NULLIF(SUM(i.amount_usd_million), 0) * 100
    , 2) AS residual_pct
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
NOTES: 
	In line with IRENA’s official reporting practice, regional public investment totals in this analysis include records classified 
	as "residual/unallocated" - that is, investments assigned to a region but not attributable to a specific country or subregion.
	
	Residual/unallocated records account for only a small share of each region’s total public renewable energy investments:
	
	Africa 2.96% | Americas 1.01% | Asia 0.81% | Europe 0.26% | Oceania 3.38%
	
	This low share (<3.5% in all regions) ensures that subregional trend comparisons are robust and not meaningfully affected by 
	data allocation uncertainty. 
 */


-- QA: Check for potential duplicates by year, geo, and technology
SELECT 
    i.year, dg.geo_type, dg.geo_name, dt.category, 
    COUNT(*) AS record_count
FROM renewables_project.investments i
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
GROUP BY i.year, dg.geo_type, dg.geo_name, dt.category
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- DE: Review technology grouping
SELECT DISTINCT dt.category, dt.group_technology 
FROM renewables_project.investments i 
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id;


-- DE: Review Non-renewable technologies
SELECT DISTINCT dt.*
FROM renewables_project.investments i 
JOIN renewables_project.dim_technology dt 
	ON i.tech_id = dt.tech_id
WHERE category = 'Non-renewable';
/*
  Technology Categories:
  -----------------------
  Renewable: Hydropower, Geothermal energy, Solar energy, Wind energy, Marine energy, 
             Bioenergy, Multiple renewables
  Non-Renewable: Fossil fuels, Nuclear, Pumped storage, Other non-renewable energy

  Focus for RQ4 analysis:
  - Compare Renewable vs Fossil Fuel public investments (2010-2023)
  - Examine alignment with cost trends, generation performance, and emissions reduction potential
*/



/* ================================================================================================
   SECTION 2: Global Investment Trends & Comparative Analysis
   ================================================================================================ */

/* ============================================================================
   Query 1: Cumulative Public Investments by Category (2000-2020)
   ============================================================================ */

SELECT
    ROUND(SUM(i.amount_usd_million), 2) AS total_investment_usd_mn,
    ROUND(SUM(CASE WHEN dt.category = 'Renewable' THEN i.amount_usd_million END), 2) AS renewables_investment_usd_mn,
    ROUND(SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million END), 2) AS fossil_fuels_investment_usd_mn,
    ROUND(SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million END), 2) AS nuclear_and_other_investment_usd_mn,
    ROUND(SUM(CASE WHEN dt.category = 'Renewable' THEN i.amount_usd_million END) / NULLIF(SUM(i.amount_usd_million), 0) * 100, 2) AS renewables_pct,
    ROUND(SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million END) / NULLIF(SUM(i.amount_usd_million), 0) * 100, 2) AS fossil_pct,
    ROUND(SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million END) / NULLIF(SUM(i.amount_usd_million), 0) * 100, 2) AS nuclear_and_other_pct
FROM renewables_project.investments i
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE i.year BETWEEN 2000 AND 2020;

/* ------------------------------------------------------------------
  Insights Summary: Public Investment Composition (2000-2020)
  
  - Total public investment: ~$531 B.
  - Renewables: $263.3 B (49.6%) - slightly ahead of fossil fuels $245 B (46.1%).
  - Nuclear + other non-renewables (pumped storage, municipal waste): $22.9 B (4.3%).
  
  -> Indicates near-parity between renewables & fossil fuels, with a modest lead for renewables.
 ------------------------------------------------------------------ */


/* ============================================================================
   Query 2: Annual Totals, Shares, YoY changes, 3-MAs by Category (2000-2020)
   ============================================================================ */

WITH base AS (
    SELECT 
        i.year, 
        SUM(CASE WHEN dt.category = 'Renewable' THEN i.amount_usd_million END) AS renewables,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN i.amount_usd_million END) AS fossil_fuels,
        SUM(CASE WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN i.amount_usd_million END) AS nuclear_and_other
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    WHERE i.year BETWEEN 2000 AND 2020
    GROUP BY i.year
)

SELECT 
    b.year,
    -- Total investment
    ROUND(COALESCE(b.renewables, 0) + COALESCE(b.fossil_fuels, 0) + COALESCE(b.nuclear_and_other, 0), 2) AS total_investment_usd_mn,

    -- Category shares
    ROUND(100 * b.renewables / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS renewables_share_pct,
    ROUND(100 * b.fossil_fuels / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS fossil_fuels_share_pct,
    ROUND(100 * b.nuclear_and_other / NULLIF(b.renewables + b.fossil_fuels + b.nuclear_and_other, 0), 2) AS nuclear_and_other_share_pct,

    -- Year-over-year % change
    ROUND(100 * (b.renewables - LAG(b.renewables) OVER (ORDER BY b.year)) / NULLIF(LAG(b.renewables) OVER (ORDER BY b.year), 0), 2) AS renewables_yoy_pct_change,
    ROUND(100 * (b.fossil_fuels - LAG(b.fossil_fuels) OVER (ORDER BY b.year)) / NULLIF(LAG(b.fossil_fuels) OVER (ORDER BY b.year), 0), 2) AS fossil_fuels_yoy_pct_change,

    -- 3-year moving averages
    ROUND(AVG(b.renewables) OVER (ORDER BY b.year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS renewables_3yr_avg_usd_mn,
    ROUND(AVG(b.fossil_fuels) OVER (ORDER BY b.year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS fossil_fuels_3yr_avg_usd_mn

FROM base b
ORDER BY b.year DESC;

/* ------------------------------------------------------------------
  Insights Summary: Investment Priorities Over Time
  
  - 2000-2020: Renewables $263 B vs Fossil $245 B - renewables slightly lead.
  - 2016 spike: Fossil fuel share surged to 57% before collapsing by >50% in 2017.
  - Since 2017, renewables consistently attracted >60-75% of public finance.
  - By 2020: Renewables ~75% of total public investments, Fossil ~25%.
  - 3-yr moving avg of renewables (>= ~$21B till 2019) exceeded fossil every year since 2012.
  - Investments in both categories declined post-2018 (partly pandemic-driven), but renewables
    investment share remained dominant in public finance priorities.
   ------------------------------------------------------------------*/


/* ============================================================================
   Query 3: Technology-Level Investment Distribution
   ============================================================================ */

-- Top-funded technologies and their share of total public investment (2000-2020)
WITH tech_investments AS (
    SELECT 
        CASE 
            WHEN dt.category = 'Renewable' THEN 'Renewables'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN 'Fossil fuels'
            WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN 'Other Non-renewables'
        END AS category,
        -- Hybrid aggregation: group renewables, show non-renewables by technology
        CASE
            WHEN dt.category = 'Renewable' THEN dt.group_technology
            ELSE dt.technology
        END AS technology_group,
        i.amount_usd_million
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt 
        ON i.tech_id = dt.tech_id
    WHERE i.year BETWEEN 2000 AND 2020
),
tech_total AS (
    SELECT 
        category,
        technology_group,
        ROUND(SUM(amount_usd_million), 1) AS total_investment_usd_mn
    FROM tech_investments
    GROUP BY category, technology_group
)
SELECT 
    category,
    technology_group,
    total_investment_usd_mn,
    ROUND(100 * total_investment_usd_mn / NULLIF(SUM(total_investment_usd_mn) OVER (), 0), 1) AS pct_share_of_total
FROM tech_total
ORDER BY pct_share_of_total DESC;

/* ------------------------------------------------------------------
 * Insights Summary:
    - Hydropower dominated renewable funding ($107.3 B ~20% of total).
    - Within fossil fuels: oil $83.5 B (15.7%), coal & peat 13.9%, natural gas 11.1%.
    - Other significant categories: "Multiple renewables" and wind each ~8.9%; solar ~7.8%.
    - Bioenergy (1.9% - ~$10 M) and geothermal (1.8%) received limited funding; marine energy $.4.1 M total.
    - In "Other non-renewables", nuclear $22.4 B (4.2%) led, while municipal waste and pumped storage together < 0.1%.
    -> Public finance concentrated in legacy hydropower and fossil oil, 
       with smaller shares for emerging renewables despite cost competitiveness improvements.
 * ------------------------------------------------------------------ */


/* ============================================================================
   Query 4: Yearly Investment Shares & Momentum by Technology
   ============================================================================ */

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
        END AS technology_group,
        i.amount_usd_million
    FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt 
      ON i.tech_id = dt.tech_id
    WHERE i.year BETWEEN 2000 AND 2020
),

yearly_totals AS (
    SELECT 
        year,
        category,
        technology_group,
        SUM(amount_usd_million) AS total_investment_usd_mn
    FROM tech_investments
    GROUP BY year, category, technology_group
),

with_pct AS (
    SELECT 
        yt.*,
        -- % share of total investment per year
        ROUND(
          100.0 * yt.total_investment_usd_mn 
          / NULLIF(SUM(yt.total_investment_usd_mn) OVER (PARTITION BY yt.year), 0)
        , 2) AS pct_share_of_year
    FROM yearly_totals yt
),

final AS (
    SELECT 
        year,
        category,
        technology_group,
        ROUND(total_investment_usd_mn, 2) AS total_investment_usd_mn,
        pct_share_of_year,

        -- YoY % change in total investment (within same category+technology_group)
        ROUND(
          100.0 * (
            total_investment_usd_mn 
            - LAG(total_investment_usd_mn) OVER (
                PARTITION BY category, technology_group 
                ORDER BY year
              )
          )
          / NULLIF(LAG(total_investment_usd_mn) OVER (
                PARTITION BY category, technology_group 
                ORDER BY year
              ), 0)
        , 2) AS yoy_investment_pct_change,

        -- YoY change (pp) in share of investment
        ROUND(
          pct_share_of_year 
          - LAG(pct_share_of_year) OVER (
                PARTITION BY category, technology_group 
                ORDER BY year
            )
        , 2) AS yoy_share_pct_change
    FROM with_pct
)

SELECT *
FROM final
-- Examples:
-- WHERE category = 'Fossil fuels'
-- WHERE technology_group = 'Hydropower'
WHERE category = 'Renewables' AND technology_group <> 'Hydropower'
ORDER BY year, total_investment_usd_mn DESC;

/* ------------------------------------------------------------------
  Insights Summary (2000-2020):
   - Hydropower led renewable funding early, but its share trended down after ~2013,
     with a one-off surge in 2017 (+232% YoY) and a sharp pullback in 2018 (~-60% YoY).
     
   - "Multiple renewables" dominated many years, indicating programmatic or multi-tech
     financing; In 2000 it's share amounted to 30% of total investments. 
     Since then till 2010 % share of multi-tech investments and other non-hydro renewables' 
     investments remained low almost always under 10%.
     "Multiple renewables" share rose again in 2018-2020, peaking ~27% in 2020.
     
   - Wind consistently reached double-digit shares across 2010-2015 and 2017, topping ~16% in 2014.
   - Solar spiked to ~17% in 2016 (~$10.4B) and exceeded 20% in 2020. 
   - From 2017-2020, solar averaged ~13% and wind ~10% of total public investment.
   
   - Bioenergy & geothermal remained marginal (low absolute $ and minimal YoY share gains).
   
   - Fossil funding was fragmented early (large "fossil n.e.s." share), with natural gas
     generally leading; post-2014, fossil $ and share declined. In 2020, gas retained ~19%,
     coal fell to ~2.5%, oil ~0.7%.
   - Nuclear remained the main "other non-renewable", typically <10% and flat over time.
   ------------------------------------------------------------------ */



/* =====================================================================================================
   SECTION 3: Subregional Investment Trends & Comparative Analysis
   ===================================================================================================== */

/* ============================================================================
   Query 1: Subregional Investment Mix & Global Contribution (2000-2020)
   ============================================================================ */

WITH all_investments AS (
    SELECT 
        dg.sub_region_name,
        dt.category,
        dt.group_technology,
        i.amount_usd_million
    FROM renewables_project.investments i
    JOIN renewables_project.dim_geo dg 
      ON i.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt 
      ON i.tech_id = dt.tech_id
    WHERE dg.sub_region_name IS NOT NULL
      AND dg.geo_type NOT IN ('Unspecified', 'Multilateral', 'Residual/unallocated', 'Economic_group')  -- subregional = countries only
),

subregion_total AS (
    SELECT
        sub_region_name,
        SUM(amount_usd_million) AS reg_total_investment
    FROM all_investments
    GROUP BY sub_region_name
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
    FROM all_investments
    GROUP BY sub_region_name
)

SELECT
    s.sub_region_name,
    ROUND(s.reg_total_investment / 1000.0, 1) AS reg_total_investment_bn,
    ROUND(100.0 * s.reg_total_investment / NULLIF(gt.world_total_investment, 0), 1) AS pct_of_world_total,
    ROUND(100.0 * tb.renewables       / NULLIF(s.reg_total_investment, 0), 1) AS renewables_pct,
    ROUND(100.0 * tb.fossil_fuels     / NULLIF(s.reg_total_investment, 0), 1) AS fossil_fuels_pct,
    ROUND(100.0 * tb.nuclear_and_other/ NULLIF(s.reg_total_investment, 0), 1) AS nuclear_other_pct
FROM subregion_total s
JOIN global_total gt ON TRUE
JOIN tech_by_subregion tb 
  ON s.sub_region_name = tb.sub_region_name
--ORDER BY fossil_fuels_pct DESC, s.sub_region_name;
  ORDER BY pct_of_world_total DESC, s.sub_region_name

/* ------------------------------------------------------------------
  Insights Summary - Subregional Investment Mix (2000-2020)
   - Largest recipients: 
       - Latin America & Caribbean: ~$140B (~27% of total); ~59% renewables, ~41% fossil.
       - Sub-Saharan Africa: ~$81B (~16%); ~60% renewables.
       - Southern Asia: ~$73B (~14%); ~43% renewables, ~45% fossil, ~12% nuclear and other non-renewable.
       - South-Eastern Asia: ~$55B (~11%); ~62% fossil, ~37% renewables.
       - Eastern Europe: ~$46B (~9%); ~87% fossil, ~12% renewables.
       
   - Least funded: Oceania subregions (Melanesia/Polynesia/Micronesia) ~$1.1B total, mostly renewables.
   
   - Very small totals: North America ~$0.7B (~0.1% of total), ~99% renewables.
   
   - Small shares but renewable-heavy: Western Europe (~1.6% of total, ~98% renewables); Eastern Asia (~1.3% of total, ~75% renewables).
   
   - Fossil-leaning subregions: Eastern Europe ($46B total, ~87% fossil), Central Asia ($19B total, ~83% fossil), South-Eastern Asia ($55B total, ~62% fossil);
     notable mixed shares: Northern Africa ($26B total, ~48% fossil), Western Asia ($29.6B total, ~47% fossil, ~11% nuclear and other non-renewable).
   ------------------------------------------------------------------ */


/* ============================================================================
   Query 2: Top Subregions for Renewable Investments & Leading Tech (2000-2020)
   ============================================================================ */
  
WITH base AS (
    SELECT 
        i.amount_usd_million,
        dg.region_name,
        dg.sub_region_name,
        CASE 
            WHEN dt.group_technology IN ('Hydropower', 'Bioenergy') THEN dt.group_technology
            ELSE dt.technology                             -- e.g., 'Solar energy', 'Wind energy', 'Geothermal energy', 'Marine energy'
        END AS technology
    FROM renewables_project.investments i
    JOIN renewables_project.dim_geo dg 
      ON i.geo_id = dg.geo_id
    JOIN renewables_project.dim_technology dt 
      ON i.tech_id = dt.tech_id
    WHERE dg.sub_region_name IS NOT NULL
      AND dg.geo_type NOT IN ('Unspecified', 'Multilateral', 'Residual/unallocated', 'Economic_group')
      AND dt.category = 'Renewable'
      AND i.year BETWEEN 2000 AND 2020
),

subregion_totals AS (
    SELECT
        sub_region_name,
        SUM(amount_usd_million) AS reg_total_investment
    FROM base
    GROUP BY sub_region_name
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
    FROM base
    GROUP BY sub_region_name, technology
)

SELECT
    s.sub_region_name,
    ROUND(s.reg_total_investment / 1000.0, 3) AS reg_total_investment_bn,
    ROUND(100.0 * s.reg_total_investment / NULLIF(gt.world_total_investment, 0), 2) AS pct_of_world_total,
    tbs.technology,
    ROUND(tbs.tech_investment / 1000.0, 5) AS tech_investment_bn,
    ROUND(100.0 * tbs.tech_investment / NULLIF(s.reg_total_investment, 0), 5) AS pct_of_subregion_total
FROM subregion_totals s
JOIN global_total gt ON TRUE
JOIN tech_by_subregion tbs 
  ON s.sub_region_name = tbs.sub_region_name
ORDER BY pct_of_world_total DESC, s.sub_region_name, pct_of_subregion_total DESC;

/* ------------------------------------------------------------------
   Insights Summary: 2000-2020, Renewables by Subregion
  
   Headline:
   - Latin America & Caribbean (LAC) led global renewable public finance (~33%, ~$82B), with Hydropower nearly half (~46%).
  
   Top subregions & focus:
   - LAC: Hydro dominant (~$38B, ~46%); Onshore wind (~20%); Solar PV (~12%);  "Multiple renewables " (~11%).
   - Sub-Saharan Africa: ~19% of global renewables (~$49B); Hydro ~66% (~$32B); Solar PV ~12%;  "Multiple renewables " ~10%.
   - Southern Asia: ~12% (~$31B); Hydro ~45%; Solar PV ~23%;  "Multiple renewables " ~23%.
   - South-eastern Asia: ~8% (~$20.5B); Hydro ~63%; Geothermal ~16%;  "Multiple renewables " ~10%; Solar PV ~8%.
   - Northern Africa: ~5% (~$13.4B); Solar PV leads (~43%); Wind ~19%;  "Multiple renewables " ~19%; Hydro ~15%.
   - Northern Europe: ~5% (~$13.2B); Offshore wind is the anchor (~56%); Bioenergy ~18%; Onshore wind ~13%.
  
   Patterns:
   - Hydro is the primary public-finance vehicle across most developing subregions.
   - Offshore wind concentration is unique to Northern Europe.
   -  "Multiple renewables " stays material (programmatic/multi-tech funds) in several regions.
   ------------------------------------------------------------------ */


/* ============================================================================
   Query 3: Donor league table: totals & mix (2000-2020)
   ============================================================================ */

-- QA: how many donors per project_id?
SELECT project_id, COUNT(DISTINCT donor) AS donors_per_project
FROM renewables_project.project_lookup
GROUP BY project_id
HAVING COUNT(DISTINCT donor) > 1
ORDER BY donors_per_project DESC; -- 0


WITH base AS (
    SELECT
        i.year,
        COALESCE(NULLIF(TRIM(pl.donor), ''), 'Unspecified') AS donor,
        dt.category,
        dt.group_technology,
        i.amount_usd_million::numeric AS amount_usd_mn
    FROM renewables_project.investments i
    JOIN renewables_project.project_lookup pl
      ON pl.project_id = i.project_id
    JOIN renewables_project.dim_technology dt
      ON dt.tech_id = i.tech_id
),
totals AS (
    -- Global total across all donors (for % of total)
    SELECT SUM(amount_usd_mn) AS world_total_mn
    FROM base
),
donor_totals AS (
    -- Total per donor (all technologies)
    SELECT donor,
           SUM(amount_usd_mn) AS donor_total_mn
    FROM base
    GROUP BY donor
),
donor_by_cat AS (
    -- Split donor totals by high-level buckets
    SELECT
        donor,
        SUM(CASE WHEN category = 'Renewable'
                 THEN amount_usd_mn ELSE 0 END) AS renewables_mn,
        SUM(CASE WHEN category = 'Non-renewable'
                  AND group_technology = 'Fossil fuels'
                 THEN amount_usd_mn ELSE 0 END) AS fossil_fuels_mn,
        SUM(CASE WHEN category = 'Non-renewable'
                  AND (group_technology <> 'Fossil fuels' OR group_technology IS NULL)
                 THEN amount_usd_mn ELSE 0 END) AS nuclear_other_mn
    FROM base
    GROUP BY donor
)
SELECT
    RANK() OVER (ORDER BY dt.donor_total_mn DESC) AS donor_rank,
    dt.donor,
    ROUND(dt.donor_total_mn / 1000.0, 3) AS donor_total_bn_usd,
    ROUND(100.0 * dt.donor_total_mn / NULLIF(t.world_total_mn, 0), 1) AS pct_of_total,

    -- Levels in $bn (for readability)
    ROUND(dc.renewables_mn   / 1000.0, 3) AS renewables_bn_usd,
    ROUND(dc.fossil_fuels_mn / 1000.0, 3) AS fossil_fuels_bn_usd,
    ROUND(dc.nuclear_other_mn/ 1000.0, 3) AS nuclear_and_other_bn_usd,

    -- Donor mix (% of that donor’s total)
    ROUND(100.0 * dc.renewables_mn    / NULLIF(dt.donor_total_mn, 0), 1) AS renewables_share_pct,
    ROUND(100.0 * dc.fossil_fuels_mn  / NULLIF(dt.donor_total_mn, 0), 1) AS fossil_fuels_share_pct,
    ROUND(100.0 * dc.nuclear_other_mn / NULLIF(dt.donor_total_mn, 0), 1) AS nuclear_and_other_share_pct

FROM totals t
JOIN donor_totals dt
  ON 1=1
JOIN donor_by_cat dc
  ON dc.donor = dt.donor
ORDER BY donor_total_bn_usd DESC, donor;

/* ------------------------------------------------------------------

Insights Summary: Top Public Energy Donors (2000-2020)

	- Concentration: ~70% of public energy finance came from the top five donors.
			#1 China (~44% of global total): ~$161B fossil, ~$55B renewables, ~$17B nuclear/other.
			#2 Brazil (~10%): renewables-heavy mix (~$43B renewables vs ~$10B fossil).
			#3 Japan (~6%): ~$21B fossil, ~$13B renewables.
			#4 EU Institutions (~6%): ~$27B renewables, ~$3.5B fossil, ~$1B nuclear/other.
			#5 IBRD/World Bank (~4%): ~$11.7B renewables, ~$10B fossil.

	- Others (ADB, IFC, Germany, USA, etc.) each contribute ~2-3.5% of the global total.
	
	Takeaway: A small set of state/multilateral funders shapes most public capital flows.
	
------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 4: QA & Data Exploration - Investments vs. Costs Correlation Prep
   ================================================================================================ */

-- DE: Preview sample cost records (technology-level LCOE and installed costs)
SELECT *
FROM renewables_project.vw_technology_cost_trends
LIMIT 5;

-- QA: Check technology coverage and available year range
SELECT 
    MIN(year) AS start_year,
    MAX(year) AS end_year,
    COUNT(DISTINCT technology) AS n_technologies
FROM renewables_project.vw_technology_cost_trends;

-- DE: List available technologies in the cost view
SELECT DISTINCT technology
FROM renewables_project.vw_technology_cost_trends
ORDER BY technology;
/*
 Available technologies (expected):
   - Bioenergy
   - Geothermal energy
   - Hydropower
   - Offshore wind energy
   - Onshore wind energy
   - Solar photovoltaic
   - Concentrated solar power
 Years: 2010-2023
*/


-- DE: Preview distinct renewable technologies and sub-technologies
SELECT DISTINCT dt.technology, dt.sub_technology
FROM renewables_project.investments i 
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
WHERE dt.category = 'Renewable'
ORDER BY dt.technology, dt.sub_technology;
/*
 Available technologies (expected):
   - Offshore wind energy
   - Onshore wind energy
   - Wind energy  (investments in wind aggregated. No specific tech info available)
   - Solar photovoltaic (sub-types: Off-grid and On-grid)
   - Solar thermal energy  (sub-types: CSP and Solar thermal)
   - Multiple renewables
   - Biogas
   - Solid biofuels
   - Liquid biofuels
   - Bioenergy
   - Renewable hydropower
   - Renewable municipal waste
   - Geothermal energy
   - Marine energy
 Years: 2000-2020
*/


-- DE: Inspect all renewable technology mappings
SELECT DISTINCT dt.*
FROM renewables_project.dim_technology dt
WHERE dt.category = 'Renewable'
ORDER BY dt.group_technology, dt.technology, dt.sub_technology;

-- QA: Verify hydropower hierarchy and naming consistency
SELECT DISTINCT dt.group_technology, dt.technology, dt.sub_technology
FROM renewables_project.dim_technology dt
WHERE dt.group_technology = 'Hydropower'; -- 3 sub-types: Agg. hydropower, Mixed Hydro Plants, Renewable hydropower


-- QA: Determine overlapping analysis window (intersection of datasets)
SELECT 
  GREATEST(
    (SELECT MIN(year) FROM renewables_project.vw_technology_cost_trends),
    (SELECT MIN(year) FROM renewables_project.investments)
  ) AS corr_start_year,
  LEAST(
    (SELECT MAX(year) FROM renewables_project.vw_technology_cost_trends),
    (SELECT MAX(year) FROM renewables_project.investments)
  ) AS corr_end_year;
-- Expected correlation window: 2010-2020


-- QA: Check technology overlap between cost and investment datasets
SELECT DISTINCT 
  c.technology AS in_costs,
  i.technology AS in_investments
FROM (
    SELECT DISTINCT technology FROM renewables_project.vw_technology_cost_trends
) c
FULL JOIN (
    SELECT DISTINCT dt.technology FROM renewables_project.investments i
    JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id
    WHERE dt.category = 'Renewable'
) i ON c.technology = i.technology
ORDER BY in_costs NULLS LAST, in_investments NULLS LAST;

/* ------------------------------------------------------------------ 
   NOTES: Data Alignment Considerations for Investments-Costs Correlation

   1. Hydropower
      - Investments data includes only "Renewable hydropower".
      - Costs data reports an aggregated "Hydropower" category, potentially including mixed-hydro plants.
      - These are treated as comparable for analysis purposes since both represent total hydropower generation.

   2. Bioenergy
      - Costs data reports a single "Bioenergy" category.
      - Investments data records multiple subtypes separately:
            - Biogas
            - Solid biofuels
            - Liquid biofuels
            - Renewable municipal waste
      - For consistency, all bioenergy-related investments are aggregated under one "Bioenergy" group
        when comparing with cost trends.

   3. Solar Thermal / CSP
      - Costs data includes only "Concentrated Solar Power (CSP)" for electricity generation.
      - Investments data contains two subtypes:
            - CSP - used for power generation.
            - Solar thermal energy - potentially includes non-electric "Concentrated Solar Thermal (CST)" systems 
              used mainly for industrial or heating applications.
      - Because the dataset does not specify use case, records labeled simply as 
        "Solar thermal energy" are assumed to represent CST and are excluded from correlation analysis.

   Summary:
      - Aligned technologies used for comparison:
        Solar PV, Onshore Wind, Offshore Wind, Hydropower, Geothermal, Bioenergy, CSP
        
      - Excluded categories:
        CST-type Solar Thermal, Multiple Renewables, Marine Energy, Wind (unspecified)
   ------------------------------------------------------------------ */



/* ================================================================================================
   SECTION 5: Analysis - Alignment Between Public Investment and Cost Declines
   ================================================================================================ */

/* ============================================================================
   Query 1: Did the most-funded renewable technologies also experience the 
            largest declines in LCOE?
   ============================================================================ */
WITH tech_investments AS (
    -- Aggregate 2010-2020 public investments by comparable technology
    SELECT 
        CASE 
            WHEN dt.group_technology IN ('Hydropower', 'Bioenergy') THEN dt.group_technology
            WHEN dt.sub_technology = 'Concentrated solar power' THEN 'Concentrated solar power'
            WHEN dt.sub_technology = 'Solar thermal energy' THEN NULL  -- Exclude CST-type records
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
    -- Sum total public investment per technology
    SELECT 
        technology,
        ROUND(SUM(tech_investment), 2) AS total_investment_mn_2010_2020
    FROM tech_investments
    WHERE technology IS NOT NULL 
    GROUP BY technology
),
latest_lcoe AS (
    -- Retrieve 2020 LCOE level and relative change since 2010
    SELECT DISTINCT ON (technology)
        technology,
        ROUND(rel_change_since_2010_lcoe_pct, 1) AS lcoe_change_pct_since_2010,
        ROUND(lcoe_usd_per_kwh, 3) AS lcoe_usd_per_kwh_2020
    FROM renewables_project.vw_technology_cost_trends
    WHERE year = 2020
    ORDER BY technology, year DESC
)

SELECT 
    i.technology,
    i.total_investment_mn_2010_2020,
    l.lcoe_change_pct_since_2010,
    l.lcoe_usd_per_kwh_2020
FROM investment_totals i
JOIN latest_lcoe l 
    ON i.technology = l.technology
ORDER BY i.total_investment_mn_2010_2020 DESC;

/* ------------------------------------------------------------------
   Insights Summary: Public Investment vs. LCOE Trends (2010-2020)
   
   1. Alignment with Cost-Effective Technologies
      - Public finance has generally been well-aligned with cost-effective 
        renewable technologies.
      - Solar PV and Onshore Wind received major funding and achieved global
        LCOE reductions of ~-87% and ~-64%, becoming the cheapest renewables
        by 2020 and further strengthening cost leadership by 2023.

   2. Hydropower - High Funding, Rising Costs
      - Hydropower attracted the largest share of public investment but saw
        its LCOE rise by ~18%.
      - This likely reflects aging assets, rising costs of new sites, and regulatory
        constraints rather than inefficiency in funding.
      - Post-2013, public funding gradually shifted away from hydropower toward
        solar and wind-technologies offering faster deployment and learning rates.

   3. Selectivity and Exceptions
      - Technologies with slower cost improvements or limited scalability
        received less public finance:
          - Bioenergy - small cost decline.
          - Geothermal - modest LCOE increase.
      - CSP (Concentrated Solar Power) is a notable outlier:
          - Received only ~$2.3 B in public investment.
          - Achieved a ~69% LCOE reduction, likely driven by private innovation.
          - Remained the most expensive renewable in 2020 ($0.122/kWh) and 2023.

   4. Reflection
      - Even focusing solely on public investments, results show strong policy
        alignment with market cost trends.
      - Public capital has increasingly favored scalable, rapidly declining
        technologies-especially Solar PV and Wind.
      - Outliers such as CSP highlight where private innovation supplements
        targeted public support.

   ------------------------------------------------------------------ */


