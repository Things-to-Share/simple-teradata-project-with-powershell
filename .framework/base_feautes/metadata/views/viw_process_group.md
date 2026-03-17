# Teradata View Documentation: metadata_viw_process_group

## 1. General Description

The `metadata_viw_process_group` view is a sophisticated metadata management component that belongs to the **metadata** functional schema. This view analyzes table dependencies and relationships to determine processing groups and detect circular references within the database structure. It traverses dependency chains up to 15 levels deep to classify tables into processing groups based on their position in the dependency hierarchy and identifies potential circular references that could cause processing issues.

The view serves as a critical component for ETL orchestration, dependency management, and data lineage analysis by providing insights into how tables should be processed in sequence and flagging problematic circular dependencies.

## 2. Logical / Functional Steps

1. **Node Definition (cte_node)**: Creates a base dataset of all tables from `metadata_tbl_table`, treating each table as a node in a dependency graph
2. **Edge Definition (cte_edge)**: Extracts valid table references from `metadata_tbl_referenced` to define the edges/connections between tables
3. **Dependency Traversal (cte_referenced)**: Performs a 15-level deep traversal of table dependencies using recursive LEFT JOINs to:
   - Calculate the process group number based on dependency depth
   - Detect circular references by checking if any level references back to the original table
4. **Process Group Calculation**: Counts the number of dependency levels for each table to determine its processing group
5. **Circular Reference Detection**: Identifies tables that reference themselves through the dependency chain
6. **Aggregation (cte_process_group)**: Groups results by table and calculates the maximum process group level and circular reference flag
7. **Final Result**: Returns the processed metadata with process group assignments and circular reference indicators

## 3. Examples in Utilization of This View

<details>
<summary><strong>Example 1: Process Group Analysis Query</strong></summary>

```sql
-- Example 1: Analyze process groups and identify processing order
DECLARE l_schema_filter    VARCHAR(128)   DEFAULT 'staging';
DECLARE l_max_group        INTEGER        DEFAULT NULL;
DECLARE l_circular_count   INTEGER        DEFAULT NULL;

-- Get process group statistics
SELECT 
    MAX(ni_process_group) AS max_process_group,
    SUM(is_circular_referenced) AS circular_reference_count
INTO 
    l_max_group,
    l_circular_count
FROM ${nm_database_target}metadata_viw_process_group;

-- Query process groups with filtering
SELECT 
    nm_schema,
    nm_table,
    ni_process_group,
    is_circular_referenced,
    CASE 
        WHEN is_circular_referenced = 1 THEN 'CIRCULAR_REF_DETECTED'
        WHEN ni_process_group = 0 THEN 'SOURCE_TABLE'
        ELSE 'DEPENDENT_TABLE'
    END AS table_classification
FROM ${nm_database_target}metadata_viw_process_group
WHERE nm_schema = l_schema_filter
   OR l_schema_filter IS NULL
ORDER BY 
    ni_process_group ASC,
    nm_schema ASC,
    nm_table ASC;

-- Display summary statistics
SELECT 
    l_max_group      AS maximum_process_group,
    l_circular_count AS tables_with_circular_references;
```
</details>

<details>
<summary><strong>Example 2: ETL Processing Order Determination</strong></summary>

```sql
-- Example 2: Generate ETL processing order and validation
REPLACE PROCEDURE ${nm_database_target}temp_etl_processing_analysis()
BEGIN
    DECLARE l_total_tables        INTEGER        DEFAULT 0;
    DECLARE l_source_tables       INTEGER        DEFAULT 0;
    DECLARE l_dependent_tables    INTEGER        DEFAULT 0;
    DECLARE l_circular_tables     INTEGER        DEFAULT 0;
    DECLARE l_max_depth          INTEGER        DEFAULT 0;
    
    -- Get processing statistics
    SELECT 
        COUNT(*) AS total_tables,
        SUM(CASE WHEN ni_process_group = 0 THEN 1 ELSE 0 END) AS source_tables,
        SUM(CASE WHEN ni_process_group > 0 THEN 1 ELSE 0 END) AS dependent_tables,
        SUM(is_circular_referenced) AS circular_tables,
        MAX(ni_process_group) AS max_depth
    INTO 
        l_total_tables,
        l_source_tables,
        l_dependent_tables,
        l_circular_tables,
        l_max_depth
    FROM ${nm_database_target}metadata_viw_process_group;
    
    -- Display processing order by group
    SELECT 
        ni_process_group AS processing_order,
        COUNT(*) AS table_count,
        STRING_AGG(nm_schema || '.' || nm_table, ', ') AS tables_in_group
    FROM ${nm_database_target}metadata_viw_process_group
    WHERE is_circular_referenced = 0
    GROUP BY ni_process_group
    ORDER BY ni_process_group;
    
    -- Display circular reference issues
    SELECT 
        'CIRCULAR_REFERENCE_ALERT' AS alert_type,
        nm_schema,
        nm_table,
        ni_process_group
    FROM ${nm_database_target}metadata_viw_process_group
    WHERE is_circular_referenced = 1;
    
    -- Display summary report
    SELECT 
        l_total_tables     AS total_tables_analyzed,
        l_source_tables    AS source_tables_count,
        l_dependent_tables AS dependent_tables_count,
        l_circular_tables  AS circular_reference_issues,
        l_max_depth        AS maximum_dependency_depth,
        CASE 
            WHEN l_circular_tables > 0 THEN 'ISSUES_DETECTED'
            ELSE 'PROCESSING_ORDER_VALID'
        END AS validation_status;
        
END;

-- Execute the analysis procedure
CALL ${nm_database_target}temp_etl_processing_analysis();

-- Cleanup
DROP PROCEDURE ${nm_database_target}temp_etl_processing_analysis;
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