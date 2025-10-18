/* ======================================================================
   File    : Q1_renewables_vs_emissions.sql
   Purpose : 
   Author  : Elene Kikalishvili
   Date    : 2025-09-18
   ====================================================================== */

/* ============================================================================================================================  
   Research Question 1: Is there a connection between the growth of renewables' share and reductions in CO₂ emissions at the global 
   						and regional levels? are countries consuming more renewables emitting less?
   ============================================================================================================================ */


--Exploring emissions data.
SELECT DISTINCT dg.geo_type 
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id; 
/*
 * available geo_type data:
	Economic_group
	Region
	Residual/unallocated
	Country
	Global
 */

SELECT dg.geo_type, dg.geo_name, dg.sub_region_name
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE dg.geo_type IN ('Residual/unallocated', 'Economic_group', 'Region');

SELECT dg.geo_type, dg.geo_name, dg.sub_region_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Residual/unallocated'; -- This type of data can't be used for regional level analysis.

SELECT DISTINCT dg.geo_name
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Country' AND dg.region_name = 'Africa'; -- Includes ONLY 4 countries: South Africa, Egypt, Algeria, and Morocco

SELECT dg.geo_type, dg.geo_name, dg.sub_region_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Region' AND dg.region_name = 'Africa'; -- These are all individual records not country aggregates and will be used for regional and global ananlysis

SELECT dg.geo_type, dg.geo_name, dg.sub_region_name, ee.value
FROM renewables_project.energy_emissions ee 
JOIN renewables_project.dim_geo dg
  ON ee.geo_id = dg.geo_id
WHERE dg.geo_type = 'Region' AND dg.region_name <> 'Africa'; -- all region type records will be used for analysis cause these ARE NOT country pre-aggregates

