# Teradata View Documentation: metadata_viw_table

## 1. General Description

The `metadata_viw_table` view is a comprehensive metadata management component that belongs to the **metadata** functional schema. This view extracts and standardizes table metadata from the Teradata system catalog (DBC.TablesV), creating a unified view of database objects with their associated metadata, schemas, and view definitions. It processes both tables and views, extracting JSON metadata from comment strings and establishing relationships between tables and their corresponding views through naming conventions.

The view serves as a central repository for table metadata, enabling consistent access to table information, functional descriptions, and associated view definitions across the database environment.

## 2. Logical / Functional Steps

1. **Metadata Extraction (cte_md)**:
   - Queries DBC.TablesV system catalog for tables and views
   - Extracts JSON metadata from CommentString field
   - Filters objects matching the target database pattern
   - Processes table naming conventions to separate schema and table components
   - Identifies table types (T=Table, V=View) and creates corresponding view names

2. **Schema and Table Name Parsing**:
   - Removes database prefix from full object names
   - Identifies schema boundaries using '_tbl' and '_viw' markers
   - Extracts clean schema and table names from composite names
   - Standardizes naming conventions across different object types

3. **Table-View Relationship Mapping (cte_table)**:
   - Generates unique SHA256 hash identifiers for each table
   - Extracts functional metadata from JSON comments (fn=function, fd=description)
   - Links tables with their corresponding views through naming conventions
   - Consolidates metadata into standardized output format

4. **Result Generation**:
   - Returns processed table metadata with unique identifiers
   - Includes functional names and descriptions extracted from JSON metadata
   - Provides associated view names and definitions where applicable
   - Ensures consistent data types and null handling

## 3. Examples in Utilization of This View

<details>
<summary><strong>Example 1: Table Metadata Discovery and Analysis</strong></summary>

```sql
-- Example 1: Comprehensive table metadata analysis
DECLARE l_schema_filter    VARCHAR(128)   DEFAULT 'staging';
DECLARE l_total_tables     INTEGER        DEFAULT NULL;
DECLARE l_documented_tables INTEGER       DEFAULT NULL;

-- Get table statistics
SELECT 
    COUNT(*) AS total_tables,
    SUM(CASE WHEN fn_table <> 'n/a' OR fd_table <> 'n/a' THEN 1 ELSE 0 END) AS documented_tables
INTO 
    l_total_tables,
    l_documented_tables
FROM ${nm_database_target}metadata_viw_table
WHERE nm_schema = l_schema_filter
   OR l_schema_filter IS NULL;

-- Query detailed table metadata
SELECT 
    nm_schema,
    nm_table,
    fn_table AS functional_name,
    fd_table AS functional_description,
    CASE 
        WHEN nm_view <> 'n/a' THEN 'HAS_VIEW'
        ELSE 'TABLE_ONLY'
    END AS view_status,
    CASE 
        WHEN fn_table = 'n/a' AND fd_table = 'n/a' THEN 'UNDOCUMENTED'
        WHEN fn_table <> 'n/a' AND fd_table <> 'n/a' THEN 'FULLY_DOCUMENTED'
        ELSE 'PARTIALLY_DOCUMENTED'
    END AS documentation_status
FROM ${nm_database_target}metadata_viw_table
WHERE nm_schema = l_schema_filter
   OR l_schema_filter IS NULL
ORDER BY 
    nm_schema ASC,
    nm_table ASC;

-- Display summary statistics
SELECT 
    l_total_tables      AS total_tables_found,
    l_documented_tables AS documented_tables_count,
    l_schema_filter     AS analyzed_schema,
    CASE 
        WHEN l_documented_tables = 0 THEN 'NO_DOCUMENTATION'
        WHEN l_documented_tables = l_total_tables THEN 'FULLY_DOCUMENTED'
        ELSE 'PARTIAL_DOCUMENTATION'
    END AS documentation_coverage;
```
</details>

<details>
<summary><strong>Example 2: Table-View Relationship Analysis</strong></summary>

```sql
-- Example 2: Table-view relationship analysis procedure
REPLACE PROCEDURE ${nm_database_target}temp_table_view_analysis()
BEGIN
    DECLARE l_total_objects       INTEGER        DEFAULT 0;
    DECLARE l_tables_with_views   INTEGER        DEFAULT 0;
    DECLARE l_standalone_tables   INTEGER        DEFAULT 0;
    DECLARE l_view_definitions    INTEGER        DEFAULT 0;
    
    -- Calculate object statistics
    SELECT 
        COUNT(*) AS total_objects,
        SUM(CASE WHEN nm_view <> 'n/a' THEN 1 ELSE 0 END) AS tables_with_views,
        SUM(CASE WHEN nm_view = 'n/a' THEN 1 ELSE 0 END) AS standalone_tables,
        SUM(CASE WHEN tx_view <> 'n/a' AND LENGTH(TRIM(tx_view)) > 0 THEN 1 ELSE 0 END) AS view_definitions
    INTO 
        l_total_objects,
        l_tables_with_views,
        l_standalone_tables,
        l_view_definitions
    FROM ${nm_database_target}metadata_viw_table;
    
    -- Show tables with their corresponding views
    SELECT 
        id_table,
        nm_schema,
        nm_table,
        nm_view,
        fn_table AS table_function,
        fd_table AS table_description,
        CASE 
            WHEN LENGTH(tx_view) > 100 THEN SUBSTR(tx_view, 1, 100) || '...'
            ELSE tx_view
        END AS view_definition_preview
    FROM ${nm_database_target}metadata_viw_table
    WHERE nm_view <> 'n/a'
      AND tx_view <> 'n/a'
    ORDER BY 
        nm_schema ASC,
        nm_table ASC;
    
    -- Show documentation gaps
    SELECT 
        nm_schema,
        nm_table,
        CASE 
            WHEN fn_table = 'n/a' THEN 'MISSING_FUNCTION_NAME'
            ELSE 'HAS_FUNCTION_NAME'
        END AS function_status,
        CASE 
            WHEN fd_table = 'n/a' THEN 'MISSING_DESCRIPTION'
            ELSE 'HAS_DESCRIPTION'
        END AS description_status
    FROM ${nm_database_target}metadata_viw_table
    WHERE fn_table = 'n/a' 
       OR fd_table = 'n/a'
    ORDER BY 
        nm_schema ASC,
        nm_table ASC;
    
    -- Display comprehensive analysis results
    SELECT 
        l_total_objects      AS total_table_objects,
        l_tables_with_views  AS tables_with_view_counterparts,
        l_standalone_tables  AS standalone_tables_only,
        l_view_definitions   AS tables_with_view_definitions,
        CAST(l_tables_with_views AS DECIMAL(5,2)) / l_total_objects * 100 AS view_coverage_percentage;
        
END;

-- Execute the table-view analysis procedure
CALL ${nm_database_target}temp_table_view_analysis();

-- Select from populated analysis results (if needed)
SELECT *
FROM ${nm_database_target}metadata_viw_table
WHERE nm_schema    = 'example_schema'
  AND fn_table    <> 'n/a'
  AND fd_table    <> 'n/a';

-- Cleanup
DROP PROCEDURE ${nm_database_target}temp_table_view_analysis;
```
</details>

---

**Utilized ASN GPT Prompt**

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "View" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_viw_" is the functional schema name

and provide functional descption of the view in attachment. Handle the following topics
1. General Description
2. logical / functional steps
3. Example in utilization of this view

- Examples
   - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
   - Inlcude declare for all paramters using a 'l_'-prefix for local variables. 
   - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
   - variable in the temporal procedure have the prefix `l_`
   - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
   - Do use the fullname of the procedure, for example '${nm_database_target}regression_usp_result'.
   - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
   - cleanup any temporal procedures

- At the End of the document after the Examples, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - calapsable text block with the used ASN GPT prompt, title "the prompt" without everthing after
</details>

*end of document*