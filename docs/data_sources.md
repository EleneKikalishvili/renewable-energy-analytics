# Data Sources

This project integrates multiple public datasets from leading international organizations.  
All datasets were transformed and cleaned before import into PostgreSQL.  
Transformation and cleaning details are provided in [data_preparation.md](data_preparation.md).  
All cleaned, SQL-ready CSV files derived from these sources are stored in [clean_data](/data/clean_data/) folder.  

**Note:** Data used in this project was accessed in **March and April 2025**. Some sources may have since released updates, but this analysis is based on the 2024 editions to maintain consistency across datasets.

---
<br>

## 1. Energy Institute – Statistical Review of World Energy (2024)

**Source:** [Energy Institute Statistical Review of World Energy 2024](https://www.energyinst.org/statistical-review)  
**License:** Publicly available for non-commercial research and educational use.  
**Accessed:** March 2025  
**Format:** Excel workbook (`Statistical Review of World Energy Data.xlsx`)  

The Energy Institute (EI) Statistical Review provides comprehensive global and regional energy data.  
Three datasets were extracted and cleaned from the original Excel file for this project:

| CSV File | Description | Key Metrics | Coverage |
|-----------|--------------|--------------|-----------|
| `ei_energy_carbon_dioxide_emissions.csv` | Country-level CO₂ emissions from energy use. | Emissions (MtCO₂), by fuel type and region. | 1965–2023 |
| `ei_primary_energy_consumption.csv` | Total primary energy consumption by country and region | Energy consumption (Exajoules). | 2000–2023 |
| `ei_primary_energy_consumption_renewables.csv` | Renewable energy consumption by technology and country. | Energy consumption (Exajoules) for solar, wind, hydro, etc. | 2000–2023 |

---
<br>

## 2. Eurostat – European Energy Statistics

**Source:**  [Access Eurostat Data Browser](https://ec.europa.eu/eurostat/databrowser/explore/all/envir?lang=en&subtheme=nrg&display=list&sort=category)  
View Individual datasets and data codes here:
- Electricity prices:  
  - [For Household Consumers (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table?lang=en&category=nrg.nrg_price.nrg_pc)
  - [For Non-Household Consumers (nrg_pc_205)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_205/default/table?lang=en&category=nrg.nrg_price.nrg_pc)
- Electricity Price Components:
  - [For Household Consumers (nrg_pc_204_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204_c/default/table?lang=en&category=nrg.nrg_price.nrg_pc)
  - [For Non-Household Consumers (nrg_pc_205_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_205_c/default/table?lang=en&category=nrg.nrg_price.nrg_pc)
- Energy Balances:
  - [Complete Energy Balances](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table?lang=en&category=nrg.nrg_quant.nrg_quanta.nrg_bal)  

**License:** Eurostat open data license (free for reuse with attribution).  
**Accessed:** April 2025  
**Format:** Individual Excel files (`.xlsx`) downloaded from Eurostat Data Browser  

Eurostat provides detailed official statistics on energy consumption, prices, and components across EU Member States.  
Three datasets were cleaned and transformed for integration into the PostgreSQL database.  

| CSV File | Description | Key Metrics | Coverage |
|-----------|--------------|--------------|-----------|
| `eurostat_electricity_prices.csv` | Electricity prices for household and non-household consumers by consumption band. | EUR/kWh | 2007–2023 |
| `eurostat_electricity_price_components.csv` | Price breakdown into energy, network, taxes, and levies components. | EUR/kWh by component | 2017–2023 |
| `eurostat_energy_balances.csv` | Primary and final energy consumption by country. | Energy consumption (Terajoules) | 1990–2023 |

---
<br>

## 3. International Renewable Energy Agency (IRENA)

**Sources:**  
- [Renewable Power Generation Costs](https://www.irena.org/Data/View-data-by-topic/Costs/Global-Trends)  
- [Public Energy Investments](https://www.irena.org/Data/View-data-by-topic/Finance-and-Investment/Renewable-Energy-Finance-Flows)  
- [Capacity and Generation](https://www.irena.org/Data/View-data-by-topic/Capacity-and-Generation/Country-Rankings)  
- [Renewable Energy Share of Electricity Capacity and Generation](https://pxweb.irena.org/pxweb/en/IRENASTAT/IRENASTAT__Power%20Capacity%20and%20Generation/RE-SHARE_2025_H2_PX.px/)  

**License:** Publicly available for research and educational use (with attribution).  
**Accessed:** March 2025  
**Format:** Individual Excel files (`.xlsx`) downloaded from IRENA Data Portal.  

IRENA provides detailed global and country-level statistics on renewable energy investment, installed capacity, generation, and technology costs.  
Six datasets were cleaned and transformed for integration into the PostgreSQL database.  

| CSV File | Description | Key Metrics | Coverage |
|-----------|--------------|--------------|-----------|
| `irena_fossil_cost_range.csv` | Global low–high cost range for fossil fuel power generation. | USD/kWh | 2023 |
| `irena_renewable_costs_country.csv` | Country-level renewable energy generation costs by technology. | LCOE (USD/kWh), Installed cost (USD/kW), Capacity factor (%) | 2010–2023 |
| `irena_renewable_costs_global.csv` | Global weighted-average renewable generation and installed costs by technology. | LCOE (USD/kWh), Installed cost (USD/kW), Capacity factor (%) | 2010–2023 |
| `irena_public_energy_investments.csv` | Public financial commitments by donor and recipient country, disaggregated by energy type. | USD million | 2000–2020 |
| `irena_renewable_capacity_generation.csv` | Installed renewable capacity (MW) and generation (GWh) by country and technology. | MW, GWh | 2000–2023 |
| `irena_renewables_share.csv` | Share of renewables in total electricity capacity and generation by country or region. | % share | 2000–2023 |

---
<br>

## 4. DataHub – ISO Country and Regional Codes

**Source:**  [DataHub: ISO Country and Region Codes](https://datahub.io/core/country-codes)  
**License:** Open Data Commons Public Domain Dedication and License (PDDL).  
**Accessed:** April 2025  
**Format:** CSV file (`country-codes.csv`)  

The DataHub dataset provides standardized ISO and UN-based geographic codes used for harmonizing country and regional identifiers across multiple datasets.  
This dataset served as the foundation for constructing the `dim_geo` table in PostgreSQL and aligning all country and region references throughout the project.  

| CSV File | Description | Key Metrics | Coverage |
|-----------|--------------|--------------|-----------|
| `datahub_country_codes_mapping.csv` | Reference of ISO country codes and UN region/subregion names and codes | ISO2, ISO3, numeric codes, UN region/subregion names | Global |

---

