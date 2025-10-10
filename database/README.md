# Database: Renewable Energy Analytics

This folder contains all SQL scripts and schema definitions used to build and populate the **PostgreSQL** database for the Renewable Energy Analytics project.

---

## Purpose
The database serves as the analytical foundation of the project.  
It integrates multiple cleaned datasets from **IRENA**, **Eurostat**, and the **Energy Institute**, harmonized through a shared geographic and technology schema.  
It supports SQL-based analysis, data validation, and Tableau visualization.

---

## Folder Structure
| Folder | Description |
|---------|--------------|
| **ddl/** | Data Definition Language scripts — create schema, enums, dimension, lookup, and fact tables. |
| **dml/** | Data Manipulation Language scripts — load, clean, and insert data into the final schema. |
| **views/** | Tableau-ready and analysis views (created after fact and dimension tables are populated). |
| **00_run_all.sql** | Master build script that rebuilds the entire database in one run (schema → data → views). |

---

## Schema Overview
- **Schema name:** `renewables_project`
- **Database:** PostgreSQL
- **Design:** Star schema with light normalization  
  - Core dimensions: `dim_geo`, `dim_technology`, `dim_source`, `dim_region`, `dim_price_component`
  - Fact tables: `investments`, `capacity_generation`, `primary_consumption`, `ren_primary_consumption`, etc.
- **Relationship logic:** All tables connect through standardized country/region codes and technology keys.

---

## Entity-Relationship Diagram (ERD)
![ERD Diagram](../docs/images/renewables_project_ERD.png)

*The ERD illustrates table relationships, primary/foreign keys, and core data flow.*

---

## How to Rebuild the Database

### 1. Requirements
- PostgreSQL 13 or higher  
- psql command-line tool  
- Cleaned CSVs located in `/data/clean_data/`

### 2. Run the Build Script

**Note:** Before running this command, navigate to the `/database` folder in your local repository.

```bash
cd database
psql -U <your_user> -d <your_database> -f 00_run_all.sql
```