/* ======================================================================
   File    : 10_insert_lookup_tables.sql
   Purpose : Inserts unique records from staging tables to populate lookup tables. 
   			 These tables are used to store repetitive additional data for fact tables, 
   			 or to provide descriptions for abbreviated indicators.
   Author  : Elene Kikalishvili
   Date    : 2025-05-20
   Depends : 01_create_schema.sql
   ====================================================================== */




-- Inserting data into lookup tables for investments fact table


-- Table 1: Populate finance_lookup table with distinct values

INSERT INTO renewables_project.finance_lookup (finance_group, finance_type)
SELECT DISTINCT
	finance_group,
	finance_type
FROM renewables_project.investments_staging;




-- Table 2: Populate project_lookup table with distinct values

INSERT INTO renewables_project.project_lookup (project, donor, agency)
SELECT DISTINCT
	project,
	donor,
	agency
FROM renewables_project.investments_staging;




-- Table 3: Populate inv_source_lookup table with distinct values

INSERT INTO renewables_project.inv_source_lookup (original_url)
SELECT DISTINCT source
FROM renewables_project.investments_staging;




-- Table 4: Populate indicator_lookup table

-- Manually inserting data into a lookup table for eu_consumption fact table
INSERT INTO renewables_project.indicator_lookup (indicator, full_name, description)
VALUES 
  (
    'FEC_EED',
    'Final Energy Consumption - Energy Efficiency Directive',
    'Data is sourced from the energy balances dataset (nrg_bal_c) provided by Eurostat. The original values are reported in terajoules, kilotonnes of oil equivalent, and gigawatt hours. For consistency and comparability in this project, only terajoule values were retained and converted into exajoules.'
  ),
  (
    'PEC_EED',
    'Primary Energy Consumption - Energy Efficiency Directive',
    'Based on Eurostat’s energy balances (nrg_bal_c), this indicator reflects gross inland energy consumption. The original data is presented in terajoules and was converted into exajoules to align with other global energy datasets used in this project.'
  );




-- Inserting data into a lookup table for eu_price_breakdown fact table


-- Table 5: Populate price_component_lookup table

-- Used distinct price_component values from eu_price_breakdown_staging as a reference to insert all the data
-- Data is sourced from Eurostat's metadata. 
-- Original source link: https://ec.europa.eu/eurostat/cache/metadata/en/nrg_pc_204_sims.htm
INSERT INTO renewables_project.price_component_lookup (price_component, full_name, description)
VALUES
-- 1
  (
    'NRG_SUP',
    'Energy and Supply',
    'Includes generation, aggregation, balancing energy, supplied energy costs, customer services, after-sales management, and other supply costs.'
  ),
  -- 2
  (
    'NETC',
    'Network Cost',
    'Covers transmission and distribution tariffs, losses, after-sales service, system services, meter rental, and metering costs.'
  ),
  -- 3
  (
    'VAT',
    'Value Added Tax (VAT)',
    'Tax defined under Council Directive 2006/112/EC.'
  ),
  -- 4
  (
    'TAX_FEE_LEV_CHRG',
    'Taxes, Fees, Levies, and Charges (Unspecified)',
    'A broad category where specific allocation is unknown or general. No detailed definition is provided in Eurostat metadata.'
  ),
  -- 5
  (
    'TAX_FEE_LEV_CHRG_ALLOW',
    'Allowance-related Taxes, Fees, Levies, and Charges',
    'Similar to TAX_FEE_LEV_CHRG, but applies to adjustments or allowances. Eurostat does not define this explicitly.'
  ),
  -- 6
  (
    'TAX_ENV',
    'Environmental Taxes',
    'Taxes, fees, levies or charges relating to air quality and for other environmental purposes; taxes on emissions of CO2 or other greenhouse gases. This component includes the excise duties.'
  ),
  -- 7
  (
    'TAX_ENV_ALLOW',
    'Environmental Taxes (Allowance-adjusted)',
    'Same as TAX_ENV but includes or reflects policy-related allowances; exact definition not fully clarified by Eurostat.'
  ),
  -- 8
  (
    'OTH',
    'Other Taxes',
    'Includes district heating support, local/regional fiscal charges, island compensation, licence/concession fees, and network infrastructure occupation fees.'
  ),
  -- 9
  (
    'ALLOW_OTH',
    'Other Allowances',
    'A residual or miscellaneous category for costs not fitting predefined categories. Definition not explicitly provided.'
  ),
  -- 10
  (
    'TAX_RNW',
    'Renewable Energy Taxes',
    'Charges related to the promotion of renewable energy sources, energy efficiency, and combined heat and power (CHP).'
  ),
  -- 11
  (
    'TAX_RNW_ALLOW',
    'Renewable Taxes (Allowance-adjusted)',
    'Same as TAX_RNW, adjusted for allowance schemes or subsidies.'
  ),
  -- 12
  (
    'TAX_NUC',
    'Nuclear Taxes',
    'Taxes, fees, levies or charges relating to the nuclear sector, including nuclear decommissioning, inspections and fees for nuclear installations.'
  ),
  -- 13
  (
    'TAX_NUC_ALLOW',
    'Nuclear Taxes (Allowance-adjusted)',
    'Same as TAX_NUC, incorporating adjustments or support schemes.'
  ),
  -- 14
  (
    'TAX_CAP',
    'Capacity Taxes',
    'Taxes, fees, levies or charges relating to capacity payments, energy security and generation adequacy; taxes on coal industry restructuring; taxes on electricity distribution; stranded costs and levies on financing energy regulatory authorities or market and system operators.'
  ),
  -- 15
  (
    'TAX_CAP_ALLOW',
    'Capacity Taxes (Allowance-adjusted)',
    'As TAX_CAP, but adjusted for capacity-related support or exceptions.'
  );












