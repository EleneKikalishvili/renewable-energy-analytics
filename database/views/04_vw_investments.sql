/* ======================================================================
   File    : 04_investments_core_view.sql
   Purpose : Create a core view for Tableau to analyze and visualize public investment flows in renewable
             and non-renewable energy technologies by region, subregion, country, donor, and custom technology groups.
   Author  : Elene Kikalishvili
   Date    : 2025-07-06
   ====================================================================== */


/* ============================================================================================================================  
   Research Question 4: What role has public finance played in scaling renewables—and is it aligned with the cost-effectiveness
                        and emissions reduction potential of different technologies?
   ============================================================================================================================ */


/*-----------------------------------------------------------------------------------------------------------------
   View: vw_investments_core
   Purpose: Create a flexible, denormalized view for Tableau to support all visualizations and analysis related
            to public investment in the global energy transition, including trends by technology, region, subregion,
            donor, and alignment with cost effectiveness.

   Summary:
      - Provides annual investment amounts by year, region, subregion, country, donor, technology category, and custom groupings.
      - Includes custom technology grouping logic for consistent aggregation and alignment with cost/LCOE data.
      - Enables detailed dashboarding of total, regional, and donor investments, technology splits, and drilldowns to country level.
      - Designed for use with Tableau, allowing calculation of shares, year-over-year trends, and custom group filters directly in BI layer.

   Key columns:
      - year: Calendar year of investment
      - geo_id, geo_type, region, subregion, country: Geographic breakdowns for mapping and summary
      - tech_category: Custom category ("Fossil fuels", "nuclear_and_other", "Renewable") for top-level splits
      - custom_technology_group: Flexible grouping logic for hybrid tech analysis (hydro, wind, solar, etc.)
      - technology: Final technology used for joining with costs/LCOE data and fine-grained analysis
      - donor: Public finance actor/funding source
      - amount_usd_million: Investment amount (USD, millions)
      
   Visualization ideas:
      - Stacked area/line charts: Investment trends by tech, region, or donor over time
      - Vertical dual axis bar chart: Renewable VS Fossil fuel investments over time
      - Treemaps, maps, or heatmaps: Regional investment flows and tech mix by geography
      - Leaderboards: Top donors, top regions, or top countries
      - Combo charts: Investment vs. LCOE cost-effectiveness and donor priorities
      - Drilldowns: From global to region, subregion, country, technology
      - Tooltips: Show technology breakdowns, costs, and other details

----------------------------------------------------------------------------------------------------------------- */



CREATE OR REPLACE VIEW renewables_project.vw_investments_core AS
SELECT
    i.year,
    dg.geo_id,
    dg.geo_type,
    dg.region_name AS region,
    dg.sub_region_name AS subregion,
    dg.geo_name AS country,

    --Custom technology category
    CASE 
    	WHEN dt.category = 'Non-renewable' AND dt.group_technology = 'Fossil fuels' THEN 'Fossil fuels'
    	WHEN dt.category = 'Non-renewable' AND dt.group_technology <> 'Fossil fuels' THEN 'nuclear_and_other'
    	ELSE dt.category::text
    END AS tech_category,

    -- Custom grouped technology logic
    CASE
        WHEN dt.category = 'Renewable' THEN dt.group_technology
        ELSE dt.technology
    END AS custom_technology_group,
    
    -- Custom technology, can be joined with costs data
	CASE 
    	WHEN dt.group_technology IN('Hydropower', 'Bioenergy') THEN dt.group_technology -- i dont need further breakdown for these tech
    	WHEN dt.sub_technology = 'Concentrated solar power' THEN dt.sub_technology  -- I need CSP records separately 
    	ELSE dt.technology
    END AS technology,
    
    pl.donor,
    i.amount_usd_million
FROM renewables_project.investments i
JOIN renewables_project.dim_geo dg ON i.geo_id = dg.geo_id
JOIN renewables_project.project_lookup pl ON pl.project_id = i.project_id
JOIN renewables_project.dim_technology dt ON i.tech_id = dt.tech_id;




