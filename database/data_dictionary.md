# Data Dictionary

**Author:** Elene Kikalishvili  
**Date:** 2025-06-01  

This file describes every table and column in the `renewables_project` schema. Use this to understand the database structure, key relationships, and purpose of each field.


<br>


 ## How to Extract Current Table/Column Metadata (Optional)

To generate a list of all tables, columns, data types, and nullability in this database, run the following query in PostgreSQL:

```sql
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'renewables_project'
ORDER BY table_name, ordinal_position;
```


<br>


## Notes

- **Primary key (PK):** Uniquely identifies records in a table.
- **Foreign key (FK):** References a key in another table (format: `FK to table.column`).
- **Enum:** Field has a restricted set of possible values. See the Description or Notes for allowed values.  
  The same ENUM type may be used in multiple tables. In some cases, only the subset of values actually used in this table are listed.


<br>


## **Fact Tables**


### **Table:** primary_consumption

**Purpose:**  
Stores yearly primary energy consumption by country and economic groups, measured in exajoules (EJ), supporting global and regional trend analysis.  

**Constraint:** `UNIQUE (geo_id, year)`  


| Column Name    | Data Type       | Nullable | Description                                         	| Notes                                 |
|----------------|-----------------|----------|-------------------------------------------------------|---------------------------------------|
| consumption_id | integer         | No       | Unique record identifier                            	| **Primary key (PK)**                  |
| source_id      | integer         | No       | Reference to data source                            	| FK to `dim_source.source_id`          |
| geo_id         | integer         | No       | Reference to geographic entity (country/region/area)	| FK to `dim_geo.geo_id`                |
| year           | integer         | No       | Reporting year (YYYY)                               	|                                       |
| unit           | enum            | No       | Unit of measurement ("Exajoules")                   	| ENUM: `energy_unit`                   |
| value          | numeric         | Yes      | Energy consumption (EJ)                             	| Nullable                              |

#### **Geo Type Behavior - `primary_consumption`**

- **Country** - Represents individual country records.  
- **Region** - Represents reported area-level totals (e.g., *Other Northern Africa*, *Other Caribbean*); these are not aggregates of countries.  
- **Global** - Pre-aggregated global totals used in global-level analysis and validation.  
- **Economic_group** - Aggregates that span multiple regions (e.g., *OECD*, *EU*); excluded from analysis.  
- **Residual/unallocated** - Covers unmapped areas (e.g., *Other CIS*, *Other Asia Pacific*); excluded from analysis.  

**Global Totals Strategy:**  
Global analysis includes all records with `geo_type = 'Global'`.  
Regional and subregional analyses include `geo_type IN ('Country', 'Region')`.  
Residual/unallocated rows are excluded from standardized totals, but the difference between standardized and source-provided global values is minimal (~1-2%).


<br>


### **Table:** ren_primary_consumption  

**Purpose:**  
Stores yearly primary energy consumption by country and economic groups, nuclear and renewable energy technologies, measured in exajoules (EJ), enabling analysis of technology-level renewable energy trends.  

**Constraint:** `UNIQUE (geo_id, technology, year)`  


| Column Name        | Data Type        | Nullable | Description                                             | Notes                                |
|--------------------|------------------|----------|---------------------------------------------------------|--------------------------------------|
| ren_consumption_id | integer          | No       | Unique record identifier                                | **Primary key (PK)**                 |
| source_id          | integer          | No       | Reference to data source                                | FK to `dim_source.source_id`         |
| geo_id             | integer          | No       | Reference to geographic entity (country/region/area)    | FK to `dim_geo.geo_id`               |
| tech_id            | integer          | No       | Reference to renewable or nuclear technology            | FK to `dim_technology.tech_id`       |
| year               | integer          | No       | Reporting year (YYYY)                                   |                                      |
| unit               | enum             | No       | Unit of measurement ("Exajoules")                       | ENUM: `energy_unit`                  |
| value              | numeric          | Yes      | Energy consumption (EJ)                                 | Nullable                             |

#### **Geo Type Behavior - `ren_primary_consumption`**

- **Country** - Represents individual country records by technology.  
- **Region** - Represents area-level totals (e.g., *Eastern Africa*, *Other Europe*); these are standalone regional entries, not country aggregates.  
- **Global** - Represents total global consumption for each technology; used in global analysis.  
- **Economic_group** - Aggregated data across multiple regions (e.g., *EU*, *OECD*); excluded from analysis.  
- **Residual/unallocated** - Represents unmapped or non-standard areas (e.g., *Other Middle East*, *Other Asia Pacific*); excluded from analysis.  

**Global Totals Strategy:**  
Global analysis uses `geo_type = 'Global'`.  
Regional and subregional analyses include `geo_type IN ('Country', 'Region')`.  
Residual/unallocated and economic group records are excluded from trend comparisons.  
Minor differences (~1-2%) between standardized and source-provided global totals are due to residual exclusions.


<br>


### **Table:** capacity_generation  

**Purpose:**  
Stores electricity generation and installed capacity by country, renewable technology, and producer type (on-grid/off-grid), supporting trend and comparative analysis.  

**Constraint:** `UNIQUE (geo_id, tech_id, producer_type, year)`  


| Column Name           | Data Type    | Nullable | Description                                                       	| Notes                              |
|-----------------------|--------------|----------|---------------------------------------------------------------------|------------------------------------|
| cap_gen_id            | integer      | No       | Unique record identifier                             			        	| **Primary key (PK)**               |
| source_id             | integer      | No       | Reference to data source                           			          	| FK to `dim_source.source_id`       |
| geo_id                | integer      | No       | Reference to geographic entity (country/region/area)      		    	| FK to `dim_geo.geo_id`             |
| tech_id               | integer      | No       | Reference to renewable technology                                 	| FK to `dim_technology.tech_id`     |
| producer_type         | enum         | No       | Type of producer: "On-grid electricity" or "Off-grid electricity"	  | ENUM: `grid_type`                  |
| year                  | integer      | No       | Reporting year (YYYY)                               			         	|                                    |
| generation_gwh        | numeric      | Yes      | Electricity generated, in gigawatt-hours (GWh)     			           	| Nullable                           |
| installed_capacity_mw | numeric      | Yes      | Installed capacity, in megawatts (MW)               			         	| Nullable                           |

#### **Geo Type Behavior - `capacity_generation`**

 **Country** - Contains only individual country-level records; no pre-aggregated regional or global totals are included.  

**Usage Notes:**  
This table represents country-level electricity generation and capacity data for renewable and non-renewable technologies.  
For regional or global analyses, aggregate country data as needed using joins with `dim_geo`.


<br>


### **Table:** ren_share  

**Purpose:**  
Stores percentage-based indicators (e.g., share of generation or capacity) for renewable energy by country and region, enabling comparative and trend analysis.  

**Constraint:** `UNIQUE (geo_id, indicator, year)`  


| Column Name    | Data Type   | Nullable | Description                                                            | Notes                                |
|----------------|-------------|----------|------------------------------------------------------------------------|--------------------------------------|
| ren_share_id   | integer     | No       | Unique record identifier                                               | **Primary key (PK)**                 |
| source_id      | integer     | No       | Reference to data source                                               | FK to `dim_source.source_id`         |
| geo_id         | integer     | No       | Reference to geographic entity (country/region/area)                   | FK to `dim_geo.geo_id`               |
| indicator      | enum        | No       | Type of share metric (e.g., "RE Capacity (%)", 'RE Generation (%)')    | ENUM: `energy_metric`                |
| year           | integer     | No       | Reporting year (YYYY)                                                  |                                      |
| value          | numeric     | Yes      | Measured percentage value (e.g., 42.3 for 42.3%)                       | Nullable                             |

#### **Geo Type Behavior - `ren_share`**

- **Country** - Individual country-level records used for all regional and subregional aggregations.  
- **Region** - Represents pre-aggregated regional totals included in the source dataset but *not* used for analysis.  
  Regional insights are derived by aggregating country-level data based on standardized region and subregion mappings.  
- **Global** - Represents source-provided global totals; used directly for global analysis (not recalculated).  
- **Residual/unallocated** - Includes non-standard or mixed geographic areas such as "Middle East".  
  These were excluded from analysis after remapping affected countries to standard UN regions.  
- **Economic_group** - Contains cross-regional aggregates (e.g., OECD, EU); excluded from analysis.

**Usage Notes:**  
The dataset covers renewable energy share of electricity generation and capacity at multiple geographic levels.  
For consistency, all regional analyses are computed from *country-level data only*, excluding residual and economic groups.  
Global analyses use the pre-aggregated `Global` records.


<br>


### **Table:** fossil_cost_range  

**Purpose:**  
Stores reference values for the lowest and highest cost bands of aggregated fossil fuels, allowing comparison against renewable energy costs.  

**Constraint:** `UNIQUE (group_technology, cost_band, reference_year)`  


| Column Name        | Data Type   | Nullable | Description                                           | Notes                             |
|--------------------|-------------|----------|-------------------------------------------------------|-----------------------------------|
| cost_band_id       | integer     | No       | Unique record identifier                              | **Primary key (PK)**              |
| source_id          | integer     | No       | Reference to data source                              | FK to `dim_source.source_id`      |
| group_technology   | varchar(15) | No       | Aggregated technology group (e.g., "Fossil fuels")    |                                   |
| cost_band          | enum        | No       | Cost band category ("Low band"/"High band")           | ENUM: `band`                      |
| value              | numeric     | No       | Cost value for the band                               | Values are in USD/kWh only        |
| unit               | enum        | No       | Unit of the cost value ("USD/kWh", "EUR/kWh")         | ENUM: `price_unit`                |
| reference_year     | integer     | No       | Reference year for the cost data                      |                                   |


<br>


### **Table:** investments  

**Purpose:**  
Stores detailed public investment data in energy projects, linked to source, geography, project, finance type, and technology, enabling financial trend and cost-comparison analyses.  

**Constraint:** `UNIQUE (original_source_id, geo_id, project_id, finance_id, tech_id, year, reference_date, amount_usd_million)`  


| Column Name          | Data Type | Nullable | Description                                                         | Notes                                           |
|----------------------|-----------|----------|---------------------------------------------------------------------|-------------------------------------------------|
| investment_id        | integer   | No       | Unique identifier for each investment record                        | **Primary key (PK)**                            |
| source_id            | integer   | No       | Reference to data source                                            | FK to `dim_source.source_id`                    |
| original_source_id   | integer   | No       | Reference to the original URL or document source                    | FK to `inv_source_lookup.original_source_id`    |
| geo_id               | integer   | No       | Reference to the geographic entity where the investment was made    | FK to `dim_geo.geo_id`                          |
| project_id           | integer   | No       | Reference to the project details (project, donor, agency)           | FK to `project_lookup.project_id`               |
| finance_id           | integer   | No       | Reference to the finance group and type                             | FK to `finance_lookup.finance_id`               |
| tech_id              | integer   | No       | Reference to the energy technology group                            | FK to `dim_technology.tech_id`                  |
| year                 | integer   | No       | Year of the investment (YYYY)                                       |                                                 |
| reference_date       | date      | No       | Exact date of the investment record                                 |                                                 |
| amount_usd_million   | numeric   | No       | Investment amount in millions of USD                                |                                                 |

#### **Geo Type Behavior - `investments`**

- **Country** - Standard country-level records; used in all subregional analyses.  
- **Region** - Not included; regional totals are computed by aggregating relevant country and residual records.  
- **Residual/unallocated** - Represents investments assigned to a region but not attributable to a specific country  
  (e.g., "Other Africa," "Other Asia Pacific").  
  These are included in *regional* analysis but excluded from subregional and country-level comparisons.  
- **Economic_group** - Includes entries such as "European Union."  
  These are not country aggregates and can be safely included in *global* analyses since project IDs are unique.  
- **Multilateral / Unspecified** - Represent global or cross-regional investments (e.g., from international organizations).  
  Included in *global* totals only.  

**Usage Notes:**  
Regional analyses include both `Country` and `Residual/unallocated` records.  
Subregional analyses rely solely on `Country` data for consistency,  
while global analyses incorporate *all* records (`Country`, `Residual/unallocated`, `Multilateral`, `Economic_group`, `Unspecified`).


<br>


### **Table:** energy_emissions  

**Purpose:**  
Stores carbon dioxide emissions (million tonnes) from energy use by country and economic groups, supporting environmental impact analysis and trend comparisons.  

**Constraint:** `UNIQUE (geo_id, year)`  


| Column Name       | Data Type  | Nullable | Description                                             | Notes                                |
|-------------------|------------|----------|---------------------------------------------------------|--------------------------------------|
| emission_id       | integer    | No       | Unique identifier for each emissions record             | **Primary key (PK)**                 |
| source_id         | integer    | No       | Reference to data source                                | FK to `dim_source.source_id`         |
| geo_id            | integer    | No       | Reference to geographic entity (country/region/area)	  | FK to `dim_geo.geo_id`               |
| year              | integer    | No       | Reporting year (YYYY)                                   |                                      |
| unit              | enum       | No       | Unit of measurement ("MtCO2")         			            | ENUM: `emission_unit`                |
| value             | numeric    | Yes      | CO2 emissions for (million tonnes)                      | Nullable                             |

#### **Geo Type Behavior - `energy_emissions`**

- **Country** - Individual country-level records; used for subregional, regional, and global aggregations.  
- **Region** - Represents standalone area-level records (e.g., *Other Southern Africa*, *Middle Africa*).  
  These are not country aggregates and are valid for regional-level analysis.  
- **Global** - Source-provided global totals; used directly for global analysis (not recalculated).  
- **Residual/unallocated** - Includes non-standard or legacy areas (e.g., *Other Middle East,* *USSR,* *Other CIS,* *Other Asia Pacific*).  
  Excluded from regional and subregional analysis.  
- **Economic_group** - Aggregates such as "EU" or "OECD"; excluded from analysis to avoid double counting.

**Usage Notes:**  
Regional analyses use both `Country` and `Region` records,  
while subregional and country-level analyses rely solely on `Country` rows.  
Global trends are derived from pre-aggregated `Global` records.


<br>


### **Table:** ren_indicators_global

**Purpose:**  
Holds global-level renewable energy indicators (e.g. LCOE, capacity factor, total installed cost) for each technology and year, supporting cost-trend and performance analyses.  

**Constraint:** `UNIQUE (technology, indicator, year, value_category)`  


| Column Name       | Data Type      | Nullable | Description                                                                                          | Notes                                |
|-------------------|----------------|----------|------------------------------------------------------------------------------------------------------|--------------------------------------|
| indicator_gl_id   | integer        | No       | Unique identifier for each global indicator record                                                   | **Primary key (PK)**                 |
| source_id         | integer        | No       | Reference to data source                                                                             | FK to `dim_source.source_id`         |
| tech_id           | integer        | No       | Reference to renewable technology                                                                    | FK to `dim_technology.tech_id`       |
| year              | integer        | No       | Measurement year (YYYY)                                                                              |                                      |
| indicator         | enum           | No       | Type of indicator (e.g. "LCOE (USD/kWh)", "Capacity factor (%)", "Total installed cost (USD/kW)")    | ENUM: `energy_metric`                |
| value_category    | varchar(20)    | No       | Calculation method for the indicator (e.g. "Weighted average", "95th percentile" ...)                |                                      |
| value             | numeric        | Yes      | Indicator value (unit depends on `indicator`)	                                                       | Nullable                             |


<br>


### **Table:** ren_indicators_country

**Purpose:**  
Stores country-level renewable energy indicators (e.g., LCOE, capacity factor, total installed cost) by technology, project type, period, and year, enabling detailed cost and performance comparisons at the national level.  

**Constraint:** `UNIQUE (geo_id, technology, project_type, indicator, year, value_category)`  


| Column Name       | Data Type      | Nullable | Description                                                                                       | Notes                                  |
|-------------------|----------------|----------|---------------------------------------------------------------------------------------------------|----------------------------------------|
| indicator_c_id    | integer        | No       | Unique identifier for each country-level indicator record                                         | **Primary key (PK)**                   |
| source_id         | integer        | No       | Reference to data source                                                                          | FK to `dim_source.source_id`           |
| geo_id            | integer        | No       | Reference to geographic entity (country/region/area)                                              | FK to `dim_geo.geo_id`                 |
| tech_id           | integer        | No       | Reference to renewable technology                                                                 | FK to `dim_technology.tech_id`         |
| project_type      | varchar(15)    | Yes      | Large, Small or Utility-scale (for hydropower and solar; null otherwise)                          | Nullable                               |
| period            | char(9)        | No       | Time period label (e.g. "2010-2015", "2016-2023")                                                 |                                        |
| year              | integer        | Yes      | Reporting year (YYYY); null if only period-level data                                             | Nullable                               |
| indicator         | enum           | No       | Type of indicator (e.g. "LCOE (USD/kWh)", "Capacity factor (%)" ...)                              | ENUM: `energy_metric`                  |
| value_category    | varchar(20)    | No       | Calculation method (e.g. "Weighted average", "95th percentile" ...)                               |                                        |
| country_value     | numeric        | Yes      | Indicator value for the country                                                                   | Nullable                               |
| regional_value    | numeric        | Yes      | Indicator value aggregated at the regional level                                                  | Nullable                               |

#### **Geo Type Behavior - `ren_indicators_country`**

- **Country** - Standard country-level records; used for all technology analyses (Solar PV, Onshore Wind, Offshore Wind).  
- **Region** - Present only for *Hydropower*; represents standalone area-level records (not country aggregates); excluded from analysis..  
- **Residual/unallocated** - Includes a single "Middle East" record for *Hydropower*; excluded from analysis.  
- **Global / Economic_group** - Not included in this dataset.  

**Usage Notes:**  
Only *Hydropower* includes regional and residual entries.  
Due to limited hydropower country coverage (3 countries and 10 regional records),  
the main comparative analyses focus on *Solar PV*, *Onshore Wind*, and *Offshore Wind* technologies.


<br>


## **Eurostat Fact Tables**

#### **Geo Type Behavior** - *(applies to `eu_consumption`, `eu_elec_prices`, and `eu_price_breakdown`)*

- **Country** - Represents individual European countries; used for country-level and regional EU analyses.  
- **Economic_group** - Includes a single record identified as `EU27_2020`, representing the aggregate of 27 EU member states.  
  These values are significantly larger and should be interpreted as *regional aggregates*, not individual entities.  
- **Region / Global / Residual/unallocated** - Not present in these datasets.

**Usage Notes:**  
Analyses at the EU level use `EU27_2020` as the aggregated benchmark,  
while comparisons across European countries rely on `Country` rows only.  
The datasets cover European nations broadly - not limited to EU members.

<br>

### **Table:** eu_consumption

**Purpose:**  
Stores EU country-level energy consumption data - both primary and final - tagged by consumption indicator, for comparative and trend analysis.  

**Constraint:** `UNIQUE (geo_id, indicator, year)`  


| Column Name   | Data Type   | Nullable | Description                                                   | Notes                           				            			|
|---------------|-------------|----------|---------------------------------------------------------------|----------------------------------------------------------|
| eu_cons_id    | integer     | No       | Unique identifier for each EU consumption record              | **Primary key (PK)**            							            |
| source_id     | integer     | No       | Reference to data source                          			       | FK to `dim_source.source_id`    						             	|
| geo_id        | integer     | No       | Reference to geographic entity (EU country/union)     		     | FK to `dim_geo.geo_id`        						                |
| indicator     | enum        | No       | Consumption indicator abbreviation ("FEC_EED" / "PEC_EED")    | FK to `indicator_lookup.indicator`; ENUM: `consumption`  |
| year          | integer     | No       | Reporting year (YYYY)                               		       |                                 					            		|
| unit          | enum        | No       | Unit of measurement ("Exajoules")                           	 | ENUM: `energy_unit`  							                      |
| value         | numeric     | Yes      | Energy consumption value for the country            			     | Nullable                        					            		|


<br>


### **Table:** eu_elec_prices

**Purpose:**  
Stores EU electricity price data by consumer type and consumption band, including tax treatment and data quality flags.  

**Constraint:** `UNIQUE (geo_id, consumer_type, consumption_band, tax, year)`  


| Column Name       | Data Type   | Nullable | Description                                                                           | Notes                                    |
|-------------------|-------------|----------|---------------------------------------------------------------------------------------|------------------------------------------|
| el_price_id       | integer     | No       | Unique identifier for each price record                                               | **Primary key (PK)**                     |
| source_id         | integer     | No       | Reference to data source                                                              | FK to `dim_source.source_id`             |
| geo_id            | integer     | No       | Reference to geographic entity (EU country/union)                                     | FK to `dim_geo.geo_id`                   |
| consumer_type     | enum        | No       | Type of consumer: "Household" or "Non-household"                              	       | ENUM: `consumer`                         |
| consumption_band  | varchar(20) | No       | Consumption band category (e.g., "KWH1000-2499")                                	     |                                          |
| tax               | enum        | No       | Tax treatment code: "I_TAX" (incl. all taxes) or "X_VAT" (excl. VAT)               	 | ENUM: `energy_tax`                       |
| year              | integer     | No       | Reporting year extracted from period (YYYY)                                    	   	 |                                          |
| unit              | enum        | No       | Unit of the price value ("EUR/kWh")                                            	     | ENUM: `price_unit`                       |
| value             | numeric     | Yes      | Average electricity price for the given consumer type, band, and tax for that year    | Nullable                                 |
| flag              | char(1)     | Yes      | Data reliability flag (e.g., "e" = estimated, null = official)                        | Nullable                                 |


<br>


### **Table:** eu_price_breakdown

**Purpose:**  
Stores detailed breakdowns of EU electricity prices by component, consumer type, and consumption band, enabling analysis of price drivers such as network fees, taxes, and levies.  

**Constraint:** `UNIQUE (geo_id, consumer_type, consumption_band, price_component, year)`  


| Column Name       | Data Type    | Nullable | Description                                                                | Notes                               		        |
|-------------------|--------------|----------|----------------------------------------------------------------------------|------------------------------------------------|
| component_id      | integer      | No       | Unique identifier for each price component record                          | **Primary key (PK)**               		        |
| source_id         | integer      | No       | Reference to data source                                                   | FK to `dim_source.source_id`       		        |
| geo_id            | integer      | No       | Reference to geographic entity (EU country/union)                          | FK to `dim_geo.geo_id`              		        |
| consumer_type     | enum         | No       | Type of consumer: "Household" or "Non-household"                           | ENUM: `consumer`                               |
| consumption_band  | varchar(20)  | No       | Consumption band category (e.g., "KWH1000-2499")                           |                                                |
| price_component   | varchar(30)  | No       | Abbreviated code for price component (e.g., "NRG_SUP", "NETC", TAX_CAP)"   | FK to `price_component_lookup.price_component` |
| year              | integer      | No       | Reporting year (YYYY)                                                      |                                                |
| unit              | enum         | No       | Unit of the price value ("EUR/kWh")                                        | ENUM: `price_unit`                             |
| value             | numeric      | Yes      | Price component value for the given consumer type, band, and year          | Nullable                                       |
| flag              | char(1)      | Yes      | Data reliability flag (e.g., "e" = estimated, null = official)             | Nullable                                       |


<br>
<br>


## **Dimension Tables**


### **Table:** dim_technology

**Purpose:**  
Stores standardized hierarchical breakdown of energy technologies, from broad category (renewable vs. non-renewable) down to specific sub-technologies, enabling detailed technology-level analysis.  

**Constraint:** `UNIQUE (technology, sub_technology)`  


| Column Name       | Data Type    | Nullable | Description                                                                 | Notes                       |
|-------------------|--------------|----------|-----------------------------------------------------------------------------|-----------------------------|
| tech_id           | integer      | No       | Unique identifier for each technology                                       | **Primary key (PK)**        |
| category          | enum         | No       | Broad technology category. Possible values: "Renewable", "Non-renewable"    | ENUM: `energy_category`     |  
| group_technology  | varchar(50)  | No       | High-level technology group (e.g., "Solar", "Wind")                         |                             |
| technology        | varchar(50)  | No       | Specific technology name (e.g., "Solar PV", "Solid biofuels")               |                             |
| sub_technology    | varchar(50)  | No       | Detailed sub-technology classification (e.g., "Rice husks")                 |                             |


<br>


### **Table:** dim_geo

**Purpose:**  
Stores standardized geographic entities - including countries, regions, global groups, economic groups, multilateral groupings, and residual/unallocated categories - for consistent geo-referencing.  

**Constraint:** See in notes.  


| Column Name      | Data Type     | Nullable | Description                                                          | Notes                  |
|------------------|---------------|----------|----------------------------------------------------------------------|------------------------|
| geo_id           | integer       | No       | Unique geographic record identifier                                  | **Primary key (PK)**   |
| geo_name         | varchar(60)   | No       | Standardized geographic name (country, region, area, group, etc.)    | Unique                 |
| geo_type         | enum          | No       | Geographic type. Possible values:                                    | ENUM: `geo`            |
|                  |               |          | "Country", "Region", "Global", "Economic_group", "Multilateral",     |                        |
|                  |               |          | "Residual/unallocated", "Unspecified"                                |                        |
| is_standard      | boolean       | No       | Indicates whether this name matches an official/ISO standard         | Default FALSE          |
| iso3             | char(3)       | Yes      | ISO alpha-3 country code                                             | Unique, Nullable       |
| iso2             | char(2)       | Yes      | ISO alpha-2 country code                                             | Unique, Nullable       |
| m49_code         | varchar(3)    | Yes      | UN M49 numeric country code                                          | Unique, Nullable       |
| country_name     | varchar(60)   | Yes      | Official country name                                                | Unique, Nullable       |
| region_name      | varchar(10)   | Yes      | UN region name                                                       | Nullable               |
| sub_region_name  | varchar(50)   | Yes      | UN sub-region name                                                   | Nullable               |
| continent_code   | char(2)       | Yes      | Continent code (e.g., AF, EU, AS)                                    | Nullable               |
| capital          | varchar(50)   | Yes      | Capital city name                                                    | Nullable               |


<br>


### **Table:** dim_source

**Purpose:**  
Stores metadata about each data source, ensuring traceability and reproducibility of all fact table records.  

**Constraint:** `UNIQUE (source_name, dataset_url)`  


| Column Name   | Data Type        | Nullable | Description                                                    | Notes                                |
|---------------|------------------|----------|----------------------------------------------------------------|--------------------------------------|
| source_id     | integer          | No       | Unique identifier for each data source                         | **Primary key (PK)**                 |
| source_name   | varchar(50)      | No       | Human-readable name of the data source                         |                                      |
| source_type   | varchar(50)      | Yes      | Type or category of the source (e.g., agency, organization)    | Nullable                             |
| dataset_url   | text             | No       | URL or reference link to the original dataset                  |                                      |
| notes         | text             | Yes      | Additional information or caveats about the source             | Nullable                             |

 
<br>
<br>


## **Lookup Tables**


### **Table:** finance_lookup

**Purpose:**  
Stores categorized finance information (group and type) for investment records, normalizing repetitive finance data.

**Constraint:** `UNIQUE (finance_group, finance_type)`  


| Column Name   | Data Type       | Nullable | Description                                                                     | Notes                         |
|---------------|-----------------|----------|---------------------------------------------------------------------------------|-------------------------------|
| finance_id    | integer         | No       | Unique identifier for each finance category record                              | **Primary key (PK)**          |
| finance_group | varchar(25)     | No       | High-level finance category (e.g., "Equity", "Grants", "Debt")                  |                               |
| finance_type  | varchar(100)    | No       | Specific finance instrument or facility type (e.g., "Bonds", "Standard loan")   |                               |


<br>


### **Table:** project_lookup

**Purpose:**  
Stores details about individual investment projects, including donor and implementing agency, for traceability of investment records.

**Constraint:** `UNIQUE (project, donor, agency)`  


| Column Name | Data Type      | Nullable | Description                                                                                 | Notes                        |
|-------------|----------------|----------|---------------------------------------------------------------------------------------------|------------------------------|
| project_id  | integer        | No       | Unique identifier for each project                                                          | **Primary key (PK)**         |
| project     | text           | Yes      | Project name or title (e.g, "Seismic Cooperation Program")                                  | Nullable                     |
| donor       | varchar(100)   | No       | Donor organization or governmental body responsible for funding (e.g., "EU Institutions")   |                              |
| agency      | varchar(100)   | No       | Implementing agency or partner organization (e.g., "European Investment Bank")              |                              |


<br>


### **Table:** inv_source_lookup

**Purpose:**  
Stores the original URLs or references for investments data, ensuring traceability back to source documents.

**Constraint:** `UNIQUE (original_url)`  


| Column Name         | Data Type | Nullable | Description                                            | Notes                   |
|---------------------|-----------|----------|--------------------------------------------------------|-------------------------|
| original_source_id  | integer   | No       | Unique identifier for each URL record                  | **Primary key (PK)**    |
| original_url        | text      | No       | Full URL or reference to the original source document  |                         |


<br>


### **Table:** indicator_lookup

**Purpose:**  
Provides full names and descriptions for abbreviated consumption indicators used in EU energy consumption data.

**Constraint:** `UNIQUE (full_name)`  


| Column Name | Data Type    | Nullable | Description                                                                                                 | Notes                                     |
|-------------|--------------|----------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| indicator   | enum         | No       | Abbreviated consumption indicator. Possible values: "PEC_EED", "FEC_EED"                                    | **Primary key (PK)**; ENUM: `consumption` |
| full_name   | varchar(100) | No       | Full, human-readable name of the indicator (e.g.,"Final Energy Consumption - Energy Efficiency Directive")  |                                           |
| description | text         | Yes      | Detailed explanation of what the indicator measures                                                         | Nullable                                  |


<br>


### **Table:** price_component_lookup

**Purpose:**  
Maps abbreviated electricity price component codes to full names and detailed descriptions, enabling interpretation of EU price-breakdown data.

**Constraint:** `UNIQUE (full_name)`  


| Column Name     | Data Type      | Nullable | Description                                                                                         | Notes                |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------------------------|----------------------|
| price_component | varchar(30)    | No       | Abbreviated price component code (e.g., "NRG_SUP", "NETC", "TAX_CAP")                               | **Primary key (PK)** |
| full_name       | varchar(255)   | No       | Full, human-readable name of the component (e.g., "Energy and Supply", "Network Cost")              |                      |
| description     | text           | Yes      | Detailed explanation of what the component covers (e.g., "Includes generation, aggregation, ...")   | Nullable             |











