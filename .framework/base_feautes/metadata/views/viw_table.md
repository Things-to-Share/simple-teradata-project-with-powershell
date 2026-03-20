# Documentation: `viw_table.sql` [Back](./../metadata.md)

## Description

Extracts table-level metadata from `DBC.TablesV` for all physical tables within the target database. Parses the functional schema and table name from the Teradata physical naming convention (removing the database prefix and splitting on `_tbl_`). Joins each table to its corresponding population view to capture the full view SQL text. Functional name and description are sourced from JSON embedded in the object's comment string. Used to populate `metadata_tbl_table`.

## Output Columns

| Order | Is Primary Key | Name                 | Datatype       | Is Nullable | Functional Description                                                                              |
|------:|:--------------:|:---------------------|:---------------|:-----------:|:----------------------------------------------------------------------------------------------------|
|     1 | -              | `id_table`           | CHAR(64)       | No          | SHA-256 hash of database + table name. Unique table identifier.                                     |
|     2 | -              | `nm_schema`          | VARCHAR(128)   | Yes         | Parsed functional schema name (part before `_tbl_`).                                                |
|     3 | -              | `nm_table`           | VARCHAR(128)   | No          | Parsed table name (part after `_tbl_`, prefixed with `tbl_`).                                       |
|     4 | -              | `fn_table`           | VARCHAR(128)   | No          | Functional name from JSON comment (`$.fn`). Defaults to `'n/a'` when not set.                       |
|     5 | -              | `fd_table`           | VARCHAR(1024)  | Yes         | Functional description from JSON comment (`$.fd`). Defaults to `'n/a'` when not set.                |
|     6 | -              | `nm_view`            | VARCHAR(128)   | No          | Name of the corresponding population view (derived by replacing `_tbl_` with `_viw_`).              |
|     7 | -              | `tx_view`            | VARCHAR(25000) | No          | Full SQL text of the population view; source data for dependency detection in `viw_referenced`.     |

## Example in Utilization of this View

<details>
<summary>Example 1 – List all tracked tables with functional metadata</summary>

```sql
-- Example 1: Retrieve all tracked tables with functional names, ordered by schema and table
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    tbl.fn_table,
    tbl.fd_table,
    tbl.nm_view
FROM  ${nm_database_target}metadata_viw_table AS tbl
ORDER BY tbl.nm_schema,
         tbl.nm_table;
```

</details>

<details>
<summary>Example 2 – Retrieve the population view SQL for a specific table</summary>

```sql
-- Example 2: Inspect the view SQL for a specific table to verify its content
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    tbl.nm_view,
    tbl.tx_view
FROM  ${nm_database_target}metadata_viw_table AS tbl
WHERE tbl.nm_schema = 'inbound'
AND   tbl.nm_table  = 'tbl_customer';
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-b-of-sql-table-or-view-definition.md](./../.ai_prompts/documentation-sql-related/level-1-b-of-sql-view-or-view-definition.md)

*end of document*



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