# Power Query Transformation Examples

This section highlights selected examples of Power Query transformations applied during the **data preparation phase** of the Renewable Energy Analytics project before importing datasets into PostgreSQL.
Each example demonstrates summary of transformation logic, Query (M) code, and visuals showing the transformation steps.

---

## Example 1: Building a Unified Country-Level Technology Costs Dataset (IRENA)  

### Objective  
Create a single, long-format dataset of **country-level renewable technology costs** by normalizing figure-style sheets (per technology and metric) and appending them into one table.  
The **Onshore Wind – Installed Cost** sheet is shown as a representative example; the final dataset combines **19 technology tables** prepared using the same pattern.

### Key Steps
1. **Select & sanitize the sheet**
   - Pick the relevant sheet (e.g., `Fig 2.6`).
   - Remove title rows, footers, and blank rows and columns; promote headers; set types.
2. **Standardize column names & text**
   - Rename to snake_case (`year`, `value_category`, `technology`, `metric_type`, etc.).
   - Trim/Clean; fix odd encodings/diacritics if present.
3. **Unpivot years → long format**
   - Temporarily replace all null values with 0 in order to not lose nulls when unpivoting.
   - Convert year columns to **`year` / `value`** structure.
   - Replace 0s with nulls.
5. **Add semantic fields**
   - `source = "IRENA"`, `group_technology = "Wind"`, `technology = "Onshore wind"`.
   - `metric_type = "Total installed cost (USD/kW)"`, `value_category = "Weighted average"`.
6. **Schema alignment for cross-tech append**
   - Add Hydro-compatible columns so all techs share the same schema:
     - `project_type` (null for wind), `period` (null), `regional_value` (null).
7. **Finalize**
   - Validate numeric types; sort; keep only needed columns and order them for consistency.

### M Code
```powerquery
let
    Source = Excel.Workbook(File.Contents("D:\Data Analytics\Renewable Energies Project Data Sources\Cleaned Data (Excel Pre-SQL Cleanup)\IRENA_Renewable_Costs_filtered sheets.xlsx"), null, true),
    #"Fig 2.6_Sheet" = Source{[Item="Fig 2.6",Kind="Sheet"]}[Data],
    #"Removed Bottom Rows" = Table.RemoveLastN(#"Fig 2.6_Sheet",221),
    #"Replaced Value" = Table.ReplaceValue(#"Removed Bottom Rows",null,"Onshore wind",Replacer.ReplaceValue,{"Column1"}),
    #"Inserted Literal" = Table.AddColumn(#"Replaced Value", "Literal", each "Total installed cost (USD/kW)", type text),
    #"Removed Columns" = Table.RemoveColumns(#"Inserted Literal",{"Column18", "Column19", "Column20", "Column21", "Column22", "Column23"}),
    #"Removed Top Rows" = Table.Skip(#"Removed Columns",6),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Top Rows", [PromoteAllScalars=true]),
    #"Replaced Value1" = Table.ReplaceValue(#"Promoted Headers",null,0,Replacer.ReplaceValue,{"2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023"}),
    #"Unpivoted Columns" = Table.UnpivotOtherColumns(#"Replaced Value1", {"Onshore wind", "Country", "Column17", "Total installed cost (USD/kW)"}, "Attribute", "Value"),
    #"Replaced Value2" = Table.ReplaceValue(#"Unpivoted Columns",0,null,Replacer.ReplaceValue,{"Value"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Replaced Value2",{{"Attribute", "year"}, {"Value", "value"}, {"Total installed cost (USD/kW)", "metric_type"}, {"Column17", "region"}, {"Onshore wind", "technology"}, {"Country", "country"}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns1",{"technology", "region", "country", "year", "metric_type", "value"}),
    #"Inserted Literal1" = Table.AddColumn(#"Reordered Columns", "Literal", each "Weighted average", type text),
    #"Reordered Columns1" = Table.ReorderColumns(#"Inserted Literal1",{"technology", "region", "country", "year", "metric_type", "Literal", "value"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Reordered Columns1",{{"Literal", "value_category"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns2", "technology", "technology - Copy"),
    #"Renamed Columns3" = Table.RenameColumns(#"Duplicated Column",{{"technology - Copy", "group_technology"}}),
    #"Replaced Value3" = Table.ReplaceValue(#"Renamed Columns3","Onshore wind","Wind",Replacer.ReplaceText,{"group_technology"}),
    #"Reordered Columns2" = Table.ReorderColumns(#"Replaced Value3",{"group_technology", "technology", "region", "country", "year", "metric_type", "value_category", "value"}),
    #"Duplicated Column1" = Table.AddColumn(#"Reordered Columns2", "region - Copy", each [region], type any),
    #"Renamed Columns4" = Table.RenameColumns(#"Duplicated Column1",{{"region - Copy", "project_type"}}),
    #"Reordered Columns3" = Table.ReorderColumns(#"Renamed Columns4",{"group_technology", "technology", "project_type", "region", "country", "year", "metric_type", "value_category", "value"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Reordered Columns3",{{"group_technology", type text}, {"technology", type text}, {"project_type", type text}, {"region", type text}, {"country", type text}, {"year", Int64.Type}, {"value", type number}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Changed Type",{{"metric_type", type text}, {"value_category", type text}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type1", "period", each
         if [year] <= 2009 then "1984-2009"
         else if [year] >=2010 and [year] <=2015 then "2010-2015"
         else "2016-2023"),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom",{{"period", type text}}),
    #"Reordered Columns4" = Table.ReorderColumns(#"Changed Type2",{"group_technology", "technology", "project_type", "region", "country", "period", "year", "metric_type", "value_category", "value"}),
    #"Trimmed Text" = Table.TransformColumns(#"Reordered Columns4",{{"group_technology", Text.Trim, type text}, {"technology", Text.Trim, type text}, {"project_type", Text.Trim, type text}, {"region", Text.Trim, type text}, {"country", Text.Trim, type text}, {"period", Text.Trim, type text}, {"metric_type", Text.Trim, type text}, {"value_category", Text.Trim, type text}}),
    #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"group_technology", Text.Clean, type text}, {"technology", Text.Clean, type text}, {"project_type", Text.Clean, type text}, {"region", Text.Clean, type text}, {"country", Text.Clean, type text}, {"period", Text.Clean, type text}, {"metric_type", Text.Clean, type text}, {"value_category", Text.Clean, type text}}),
    #"Renamed Columns5" = Table.RenameColumns(#"Cleaned Text",{{"value", "country_value"}}),
    #"Inserted Literal2" = Table.AddColumn(#"Renamed Columns5", "regional_value", each null, type text),
    #"Inserted Literal3" = Table.AddColumn(#"Inserted Literal2", "source", each "IRENA", type text),
    #"Reordered Columns5" = Table.ReorderColumns(#"Inserted Literal3",{"source", "group_technology", "technology", "project_type", "region", "country", "period", "year", "metric_type", "value_category", "country_value", "regional_value"}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Reordered Columns5",{{"regional_value", type number}})
in
    #"Changed Type3"
```
### Visual Results

**Before → After Comparison**  
![Onshore Wind - Before and After](./images/onshore_wind_before_and_after.gif)

**Transformation Steps Overview**  
![Onshore Wind – Steps](./images/onshore_wind_steps.gif)  

---

## Example 2: IRENA – Renewable Energy Investments

*Example 2 focuses on text-cleaning and normalization techniques applied to the IRENA Public Investment in Renewable Energy dataset.  
This example demonstrates how Power Query was used to fix inconsistent text, remove diacritics, and prepare structured, analysis-ready data for SQL import.*

### Objective
To clean and standardize IRENA’s **Public Investment in Renewable Energy** dataset by fixing inconsistent text formatting, removing diacritics from project names, and harmonizing key fields for SQL import.  

---

### Key Steps

1. **Renaming & Typing**  
   - Renamed columns to standardized `snake_case` names (`country_or_area`, `finance_type`, `amount_usd_million`, etc.).  
   - Converted data types for key fields (`year`, `reference_date`, `amount_usd_million`).

2. **Text Cleaning & Formatting**  
   - Applied *Trim* and *Clean* functions to all text columns to remove invisible Unicode characters and trailing spaces.  
   - Replaced empty project names with nulls.

3. **Deduplication**  
   - Removed fully duplicated rows to ensure project uniqueness.

4. **Diacritics Normalization (key transformation)**  
   - Used a custom Power Query expression to convert all diacritics and non-ASCII characters in the `project` column (e.g., *é, ü, ç*) into plain Latin equivalents.  
   - Cleaned up question marks and excessive spaces introduced during the conversion to produce a normalized `project` field.  
   - Example:  
     `"Énergie solaire à Bamako" → "Energie solaire a Bamako"`

5. **Final Structuring**  
   - Replaced original `project` column with the normalized version.  
   - Added `dataset_source = "IRENA"` for traceability.  
   - Reordered columns for SQL import consistency.

---

### Power Query (M) Code

```powerquery
let
    Source = Excel.CurrentWorkbook(){[Name="renewable_investment"]}[Content],
    #"Renamed Columns" = Table.RenameColumns(Source,{{"ISO-code", "iso3"}, {"Country/Area", "country/area"}, {"Region", "region"}, {"Project", "project"}, {"Donor", "donor"}, {"Agency", "agency"}, {"Year", "year"}, {"Category", "category"}, {"Technology", "technology"}, {"Sub-technology", "sub_technology"}, {"Finance Group", "finance_group"}, {"Finance Type", "finance_type"}, {"Source", "source"}, {"Reference Date", "reference_date"}, {"Amount (2020 USD million)", "amount_2020_usd_million"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"iso3", type text}, {"country/area", type text}, {"region", type text}, {"project", type text}, {"donor", type text}, {"agency", type text}, {"category", type text}, {"technology", type text}, {"sub_technology", type text}, {"finance_group", type text}, {"finance_type", type text}, {"source", type text}}),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type",{{"iso3", Text.Trim, type text}, {"country/area", Text.Trim, type text}, {"region", Text.Trim, type text}, {"project", Text.Trim, type text}, {"donor", Text.Trim, type text}, {"agency", Text.Trim, type text}, {"category", Text.Trim, type text}, {"technology", Text.Trim, type text}, {"sub_technology", Text.Trim, type text}, {"finance_group", Text.Trim, type text}, {"finance_type", Text.Trim, type text}, {"source", Text.Trim, type text}}),
    #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"iso3", Text.Clean, type text}, {"country/area", Text.Clean, type text}, {"region", Text.Clean, type text}, {"project", Text.Clean, type text}, {"donor", Text.Clean, type text}, {"agency", Text.Clean, type text}, {"category", Text.Clean, type text}, {"technology", Text.Clean, type text}, {"sub_technology", Text.Clean, type text}, {"finance_group", Text.Clean, type text}, {"finance_type", Text.Clean, type text}, {"source", Text.Clean, type text}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Cleaned Text",{{"year", Int64.Type}, {"reference_date", type date}, {"amount_2020_usd_million", type number}}),
    #"Renamed Columns1" = Table.RenameColumns(#"Changed Type1",{{"country/area", "country_or_area"}, {"amount_2020_usd_million", "amount_usd_million"}}),
    #"Replaced Value" = Table.ReplaceValue(#"Renamed Columns1","",null,Replacer.ReplaceValue,{"project"}),
    #"Removed Duplicates" = Table.Distinct(#"Replaced Value"),
    #"Added Custom" = Table.AddColumn(#"Removed Duplicates", "dataset_source", each "IRENA"),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Custom",{"dataset_source", "iso3", "country_or_area", "region", "project", "donor", "agency", "year", "category", "technology", "sub_technology", "finance_group", "finance_type", "source", "reference_date", "amount_usd_million"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Reordered Columns",{{"dataset_source", type text}}),
    #"Added Custom3" = Table.AddColumn(#"Changed Type2", "normalized_project", each
         if [project] = null then null
         else let
             ReplaceDiacritics = Text.FromBinary(Text.ToBinary([project], 28597), TextEncoding.Ascii), 
             RemoveQuestionMarks = Text.Replace(ReplaceDiacritics, "?", " "), 
             RemoveExcessSpaces = Text.Combine(
               List.RemoveItems(Text.Split(Text.Trim(RemoveQuestionMarks), " "), {""}),  " " )
           in RemoveExcessSpaces),
    #"Reordered Columns1" = Table.ReorderColumns(#"Added Custom3",{"dataset_source", "iso3", "country_or_area", "region", "project", "normalized_project", "donor", "agency", "year", "category", "technology", "sub_technology", "finance_group", "finance_type", "source", "reference_date", "amount_usd_million"}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Reordered Columns1",{{"normalized_project", type text}}),
    #"Removed Columns" = Table.RemoveColumns(#"Changed Type3",{"project"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Removed Columns",{{"normalized_project", "project"}})
in
    #"Renamed Columns2"
```
### Visual Results

**Transformation Steps Overview**  
![Investments – Steps](./images/investments_steps.gif)  

---

## Example 3: Eurostat – Household Electricity Prices

*Example 3 focuses on reshaping Eurostat’s household electricity price data from a wide, code-heavy table into a tidy, analysis-ready format.  
It demonstrates filtering (EUR, including taxes), unpivoting period columns, parsing Eurostat quality flags, and final type conversion for SQL import.  
The same transformation workflow was applied to the non-household electricity prices dataset, and both were later appended to form the final eurostat_electricity_prices dataset.*  

### Objective
Transform the Eurostat **household electricity prices** into a long, consistent structure with clear fields for
country (`iso2`), consumption band, period, and price value (EUR/kWh), keeping Eurostat’s quality flags where present.

---

### Key Steps

1. **Column Selection & Renaming**
   - Dropped unused metadata (e.g., `freq`, `product`).
   - Renamed `geo\TIME_PERIOD` → `iso2` for country mapping later.

2. **Filtering to a Single, Comparable Measure**
   - Kept **EUR currency** and **prices including taxes** (`tax = I_TAX`) only.

3. **Unpivoting Period Columns**
   - Converted all period columns (e.g., `2007-S1`, `2007-S2`, …) to a long format: `period` / `electricity_price`.
   - Renamed `nrg_cons` → `consumption_band`.

4. **Standard Fields & Ordering**
   - Added `consumer_type = "Household"`, `source = "Eurostat"`, and `metric_type = "Electricity price (EUR per KWH)"`.
   - Removed `unit` and `currency` (now implicit in `metric_type`).
5. **Text cleaning**
   - Applied *Trim* and *Clean* functions to all text columns to remove invisible Unicode characters and trailing spaces.  
6. **Flag Extraction & Cleaning**
   - Eurostat sometimes appends **quality flags** to values (e.g., `e`, `d`, `p`).  
     Parsed these into `is_flagged` while cleaning the numeric price:
     - If value had a colon `:`, treated as **missing** (`null`).
     - Removed trailing flag letters (`e`, `d`, `p`, `u`, `n`, `c`, `f`, `0n`, `b`, `|`).
     - Cast the cleaned text to **number**.

7. **Type Conversion**
   - Cast `value` to `number` and `is_flagged` to `text`.

---

### Power Query (M) Code

```powerquery
let
    Source = Excel.CurrentWorkbook(){[Name="eu_household_elec_prices"]}[Content],
    #"Removed Columns" = Table.RemoveColumns(Source,{"freq", "product"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns",{{"geo\TIME_PERIOD", "iso2"}}),
    #"Filtered Rows" = Table.SelectRows(#"Renamed Columns", each ([tax] = "I_TAX") and ([currency] = "EUR")),
    #"Unpivoted Other Columns" = Table.UnpivotOtherColumns(#"Filtered Rows", {"nrg_cons", "unit", "tax", "currency", "iso2"}, "Attribute", "Value"),
    #"Renamed Columns1" = Table.RenameColumns(#"Unpivoted Other Columns",{{"Attribute", "period"}, {"Value", "electricity_price"}, {"nrg_cons", "consumption_band"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns1", "consumer_type", each "Household"),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Custom",{"consumer_type", "consumption_band", "unit", "tax", "currency", "iso2", "period", "electricity_price"}),
    #"Added Custom1" = Table.AddColumn(#"Reordered Columns", "source", each "Eurostat"),
    #"Reordered Columns1" = Table.ReorderColumns(#"Added Custom1",{"source", "consumer_type", "consumption_band", "unit", "tax", "currency", "iso2", "period", "electricity_price"}),
    #"Added Custom2" = Table.AddColumn(#"Reordered Columns1", "metric_type", each "Electricity price (EUR per KWH)"),
    #"Reordered Columns2" = Table.ReorderColumns(#"Added Custom2",{"source", "consumer_type", "consumption_band", "unit", "tax", "currency", "iso2", "period", "metric_type", "electricity_price"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Reordered Columns2",{"unit", "currency"}),
    #"Trimmed Text" = Table.TransformColumns(Table.TransformColumnTypes(#"Removed Columns1", {{"electricity_price", type text}}, "en-US"),{{"source", Text.Trim, type text}, {"consumer_type", Text.Trim, type text}, {"consumption_band", Text.Trim, type text}, {"tax", Text.Trim, type text}, {"iso2", Text.Trim, type text}, {"period", Text.Trim, type text}, {"metric_type", Text.Trim, type text}, {"electricity_price", Text.Trim, type text}}),
    #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"source", Text.Clean, type text}, {"consumer_type", Text.Clean, type text}, {"consumption_band", Text.Clean, type text}, {"tax", Text.Clean, type text}, {"iso2", Text.Clean, type text}, {"period", Text.Clean, type text}, {"metric_type", Text.Clean, type text}, {"electricity_price", Text.Clean, type text}}),
    #"Renamed Columns2" = Table.RenameColumns(#"Cleaned Text",{{"electricity_price", "value"}}),
    #"Added Custom3" = Table.AddColumn(#"Renamed Columns2", "is_flagged", each
         if Text.Contains([value], ":") then null
         else if Text.EndsWith([value], "e") then "e"
         else if Text.EndsWith([value], "d") then "d"
         else if Text.EndsWith([value], "p") then "p"
         else if Text.EndsWith([value], "u") then "u"
         else if Text.EndsWith([value], "n") then "n"
         else if Text.EndsWith([value], "c") then "c"
         else if Text.EndsWith([value], "f") then "f"
         else if Text.EndsWith([value], "0n") then "0n"
         else if Text.EndsWith([value], "b") then "b"
         else if Text.EndsWith([value], "|") then "|"
         else null),
    #"Replaced Value1" = Table.ReplaceValue(#"Added Custom3"," e","",Replacer.ReplaceText,{"value"}),
    #"Replaced Value2" = Table.ReplaceValue(#"Replaced Value1"," d","",Replacer.ReplaceText,{"value"}),
    #"Replaced Value3" = Table.ReplaceValue(#"Replaced Value2"," p","",Replacer.ReplaceText,{"value"}),
    #"Replaced Value" = Table.ReplaceValue(#"Replaced Value3"," u","",Replacer.ReplaceText,{"value"}),
    #"Replaced Value4" = Table.ReplaceValue(#"Replaced Value",":",null,Replacer.ReplaceValue,{"value"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Replaced Value4",{{"value", type number}, {"is_flagged", type text}})
in
    #"Changed Type"
```
### Visual Results

**Transformation Steps Overview**  
![Electricity prices – Steps](./images/electricity_prices_steps.gif)   

---
