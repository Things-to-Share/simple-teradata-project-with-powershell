# Teradata View Documentation: metadata_viw_referenced

## 1. General Description

The `metadata_viw_referenced` view is a metadata management component that belongs to the **metadata** functional schema. This view automatically detects and maps table references by analyzing view definitions and identifying which tables are referenced within other table/view objects. It performs pattern matching on view text to establish dependencies between database objects, creating a comprehensive reference mapping that can be used for impact analysis, dependency tracking, and data lineage purposes.

The view cross-references table metadata with actual database objects to identify relationships and dependencies that exist within the database environment.

## 2. Logical / Functional Steps

1. **Database Context Establishment (cte_database)**: 
   - Queries the DBC.TablesV system table to identify relevant databases
   - Filters databases that match the target database pattern
   - Establishes the database context for the analysis

2. **Search Pattern Preparation (cte_table)**:
   - Constructs searchable patterns from table metadata
   - Creates normalized search strings combining database, schema, and table names
   - Retrieves view definition text for pattern matching
   - Cross-joins with database context for comprehensive coverage

3. **Reference Detection (cte_match)**:
   - Performs pattern matching using LIKE operations on view definitions
   - Identifies when one table's view definition references another table
   - Creates mappings between referencing tables and referenced tables
   - Uses self-join logic to compare all tables against all other tables

4. **Result Generation**:
   - Returns pairs of table identifiers showing reference relationships
   - Provides `id_table` (the referencing table) and `id_table_referenced` (the referenced table)
   - Filters out null references to ensure clean results

## 3. Examples in Utilization of This View

<details>
<summary><strong>Example 1: Table Dependency Analysis Query</strong></summary>

```sql
-- Example 1: Analyze table dependencies and reference patterns
DECLARE l_target_table     VARCHAR(128)   DEFAULT NULL;
DECLARE l_reference_count  INTEGER        DEFAULT NULL;
DECLARE l_dependent_count  INTEGER        DEFAULT NULL;

-- Get reference statistics for a specific table
SET l_target_table = 'specific_table_id';

SELECT 
    COUNT(*) AS total_references
INTO l_reference_count
FROM ${nm_database_target}metadata_viw_referenced
WHERE id_table = l_target_table
   OR id_table_referenced = l_target_table;

-- Query detailed reference relationships
SELECT 
    ref.id_table,
    ref.id_table_referenced,
    t1.nm_schema AS referencing_schema,
    t1.nm_table AS referencing_table,
    t2.nm_schema AS referenced_schema,
    t2.nm_table AS referenced_table,
    CASE 
        WHEN ref.id_table = ref.id_table_referenced THEN 'SELF_REFERENCE'
        ELSE 'EXTERNAL_REFERENCE'
    END AS reference_type
FROM ${nm_database_target}metadata_viw_referenced AS ref
LEFT JOIN ${nm_database_target}metadata_tbl_table AS t1
    ON ref.id_table = t1.id_table
LEFT JOIN ${nm_database_target}metadata_tbl_table AS t2
    ON ref.id_table_referenced = t2.id_table
WHERE ref.id_table_referenced IS NOT NULL
  AND (ref.id_table = l_target_table OR l_target_table IS NULL)
ORDER BY 
    t1.nm_schema ASC,
    t1.nm_table ASC,
    t2.nm_schema ASC,
    t2.nm_table ASC;

-- Display summary statistics
SELECT 
    l_reference_count AS total_references_found,
    l_target_table    AS analyzed_table;
```
</details>

<details>
<summary><strong>Example 2: Impact Analysis and Dependency Mapping</strong></summary>

```sql
-- Example 2: Comprehensive impact analysis procedure
REPLACE PROCEDURE ${nm_database_target}temp_reference_impact_analysis()
BEGIN
    DECLARE l_total_references    INTEGER        DEFAULT 0;
    DECLARE l_unique_tables       INTEGER        DEFAULT 0;
    DECLARE l_self_references     INTEGER        DEFAULT 0;
    DECLARE l_orphaned_tables     INTEGER        DEFAULT 0;
    
    -- Calculate reference statistics
    SELECT 
        COUNT(*) AS total_references,
        COUNT(DISTINCT id_table) AS unique_referencing_tables,
        SUM(CASE WHEN id_table = id_table_referenced THEN 1 ELSE 0 END) AS self_references
    INTO 
        l_total_references,
        l_unique_tables,
        l_self_references
    FROM ${nm_database_target}metadata_viw_referenced
    WHERE id_table_referenced IS NOT NULL;
    
    -- Find orphaned tables (no references)
    SELECT COUNT(*)
    INTO l_orphaned_tables
    FROM ${nm_database_target}metadata_tbl_table AS t
    WHERE NOT EXISTS (
        SELECT 1 
        FROM ${nm_database_target}metadata_viw_referenced AS r
        WHERE r.id_table = t.id_table
           OR r.id_table_referenced = t.id_table
    );
    
    -- Show tables with highest reference counts
    SELECT 
        t.nm_schema,
        t.nm_table,
        COUNT(*) AS reference_count,
        'HIGH_IMPACT' AS impact_level
    FROM ${nm_database_target}metadata_viw_referenced AS ref
    JOIN ${nm_database_target}metadata_tbl_table AS t
        ON ref.id_table_referenced = t.id_table
    WHERE ref.id_table_referenced IS NOT NULL
    GROUP BY t.id_table, t.nm_schema, t.nm_table
    HAVING COUNT(*) >= 3
    ORDER BY reference_count DESC;
    
    -- Show reference chains (dependencies)
    SELECT 
        ref.id_table,
        ref.id_table_referenced,
        t1.nm_schema || '.' || t1.nm_table AS referencing_object,
        t2.nm_schema || '.' || t2.nm_table AS referenced_object
    FROM ${nm_database_target}metadata_viw_referenced AS ref
    JOIN ${nm_database_target}metadata_tbl_table AS t1
        ON ref.id_table = t1.id_table
    JOIN ${nm_database_target}metadata_tbl_table AS t2
        ON ref.id_table_referenced = t2.id_table
    WHERE ref.id_table_referenced IS NOT NULL
      AND ref.id_table <> ref.id_table_referenced;
    
    -- Display comprehensive statistics
    SELECT 
        l_total_references AS total_references_mapped,
        l_unique_tables    AS tables_with_references,
        l_self_references  AS self_reference_count,
        l_orphaned_tables  AS orphaned_tables_count,
        CASE 
            WHEN l_self_references > 0 THEN 'SELF_REFERENCES_DETECTED'
            ELSE 'NO_SELF_REFERENCES'
        END AS validation_status;
        
END;

-- Execute the impact analysis procedure
CALL ${nm_database_target}temp_reference_impact_analysis();

-- Cleanup
DROP PROCEDURE ${nm_database_target}temp_reference_impact_analysis;
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