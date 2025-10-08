# Power Query Transformation Examples

This section highlights selected examples of Power Query transformations applied during the **data preparation phase** of the Renewable Energy Analytics project.  
Each example demonstrates a key part of the data cleaning and structuring workflow used before importing the datasets into PostgreSQL.

---

## Example 1: Building a Unified Country-Level Technology Costs Dataset (IRENA)  

**Objective**  
Create a single, long-format dataset of **country-level renewable technology costs** by normalizing figure-style sheets (per technology and metric) and appending them into one table.  
The **Onshore Wind – Installed Cost** sheet is shown as a representative example; the final dataset combines **19 technology tables** prepared using the same pattern.

### Key Steps
1. **Select & sanitize the sheet**
   - Pick the relevant sheet (e.g., `Fig 2.6`).
   - Remove title rows, footers, and blank rows and columns; promote headers; set types.
2. **Standardize column names & text**
   - Rename to snake_case (`geo_name`, `year`, `value`, `technology`, `metric_type`).
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
    #"Added Custom" = Table.AddColumn(#"Changed Type1", "period", each if [year] <= 2009 then "1984-2009"
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
