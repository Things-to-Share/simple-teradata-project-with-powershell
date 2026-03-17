# Generic

## Introduction

This is a comprehensive data processing framework for Teradata environments that provides robust, scalable and maintainable data operations. This framework is built around a collection of generic stored procedures that handle common data management tasks including table creation, data loading, historization, and error handling with comprehensive logging capabilities.

The framework follows enterprise-grade practices with built-in retry logic for handling transient database errors such as deadlocks and spool space issues. It supports both volatile and persistent table operations, dynamic SQL execution and implements Slowly Changing Dimension Type 2 (SCD2) historization patterns for maintaining data lineage and historical tracking.

Key design principles include separation of concerns through modular procedures, comprehensive error handling with intelligent retry mechanisms and extensive logging for audit trails and debugging purposes. The framework utilizes standard naming conventions where objects follow the pattern of schema prefix followed by object type indicators (\_tbl\_ for tables, \_viw\_ for views, \_usp\_ for procedures), ensuring consistency across the data platform.

## Components of the Framework

| SQL Object Type | Name | Description |
|-----------------|------|-------------|
| Procedure | [`generic_usp_create_table`](./generic/procedures/usp_create_table.md) | Creates volatile or persistent tables with configurable primary indexes and comprehensive error handling |
| Procedure | [`generic_usp_drop_table`](./generic/procedures/usp_drop_table.md) | Safely drops tables with intelligent error handling for "table does not exist" scenarios |
| Procedure | [`generic_usp_exec_dynamic_sql`](./generic/procedures/usp_exec_dynamic_sql.md) | Executes dynamic SQL with retry logic for deadlocks and spool space issues |
| Procedure | [`generic_usp_hist_one_dataset`](./generic/procedures/usp_hist_one_dataset.md) | Loads single dataset for development testing with validation checks |
| Procedure | [`generic_usp_hist_view_into_table`](./generic/procedures/usp_hist_view_into_table.md) | Implements SCD2 historization from view to table maintaining data lineage |
| Procedure | [`generic_usp_load_view_into_table`](./generic/procedures/usp_load_view_into_table.md) | Performs complete table refresh by loading data from corresponding view |
| Procedure | [`generic_usp_wait`](./generic/procedures/usp_wait.md) | Implements delay mechanism for retry logic and rate limiting |

## Framework Architecture

```mermaid
flowchart TD
    A[generic_usp_hist_one_dataset] --> B[generic_usp_load_view_into_table]
    A --> C[generic_usp_hist_view_into_table]
    
    B --> D[generic_usp_exec_dynamic_sql]
    C --> D
    C --> E[generic_usp_create_table]
    
    D --> F[generic_usp_wait]
    E --> G[generic_usp_drop_table]
    
    H[(Source Views)] --> B
    H --> C
    I[(Target Tables)] <-- B
    I <-- C
    
    J[logging_usp_start] --> A
    J --> B
    J --> C
    J --> D
    J --> E
    J --> G
    
    K[logging_usp_debug] --> A
    K --> B
    K --> C
    K --> D
    K --> E
    K --> G
    
    L[logging_usp_finish] --> A
    L --> B
    L --> C
    L --> D
    L --> E
    
    M[logging_usp_failed] --> A
    M --> B
    M --> C
    M --> D
    M --> E
    M --> G
```

## Key Features

**Robust Error Handling**: The framework implements comprehensive error handling with intelligent classification of transient vs. critical errors. Procedures like [`generic_usp_exec_dynamic_sql`](./generic/procedures/usp_exec_dynamic_sql.md) automatically retry operations for deadlocks and spool space issues while failing fast for critical errors.

**Comprehensive Logging**: All framework procedures integrate with a centralized logging system providing detailed audit trails, debug information, and execution tracking through logging_usp_start, logging_usp_debug, logging_usp_finish, and logging_usp_failed procedures.

**Flexible Table Management**: The [`generic_usp_create_table`](./generic/procedures/usp_create_table.md) procedure supports both volatile and persistent table creation with configurable primary indexes, while [`generic_usp_drop_table`](./generic/procedures/usp_drop_table.md) provides safe table removal with intelligent error handling.

**Data Historization Support**: The framework implements SCD2 patterns through [`generic_usp_hist_view_into_table`](./generic/procedures/usp_hist_view_into_table.md), maintaining historical data integrity with technical validity timestamps and actual record flags for point-in-time analysis.

**Dynamic SQL Capabilities**: Complex view definitions including CTEs are handled seamlessly by [`generic_usp_load_view_into_table`](./generic/procedures/usp_load_view_into_table.md), which dynamically extracts and processes view SQL for data loading operations.

**Development Testing Support**: The [`generic_usp_hist_one_dataset`](./generic/procedures/usp_hist_one_dataset.md) procedure provides validation and loading capabilities specifically designed for development environments with comprehensive object existence checking.

## Practical Coding Examples

### Example 1: Complete Data Refresh Workflow

```sql
-- Complete refresh of customer data from view to table
DECLARE l_status_text VARCHAR(999);

-- Load customer data with complete refresh
CALL generic_usp_load_view_into_table(
    't_customer_data',           -- Schema name
    'customer_master',           -- Table name  
    '1=1',                      -- Delete all existing data
    1,                          -- Enable debugging
    l_status_text
);

-- Check execution status
SELECT CASE 
    WHEN l_status_text = '' THEN 'SUCCESS: Customer data loaded successfully'
    ELSE 'ERROR: ' || l_status_text
END AS execution_result;
```

### Example 2: SCD2 Historization Process

```sql
-- Implement historization for product catalog changes
DECLARE l_status_text VARCHAR(999);

-- Historize product changes maintaining full audit trail
CALL generic_usp_hist_view_into_table(
    't_product_data',            -- Schema name
    'product_catalog',           -- Table name
    '',                         -- No specific delete criteria
    0,                          -- Disable debugging for production
    l_status_text
);

-- Verify historization completed successfully
IF l_status_text = '' THEN
    SELECT COUNT(*) AS active_records,
           COUNT(CASE WHEN meta_is_actual = 0 THEN 1 END) AS historical_records
    FROM t_product_data_tbl_product_catalog;
ELSE
    SELECT 'Historization failed: ' || l_status_text AS error_message;
END IF;
```

### Example 3: Development Testing with Validation

```sql
-- Load single dataset for development testing with full validation
CALL generic_usp_hist_one_dataset(
    't_test_data',               -- Schema name for test environment
    'transaction_summary',       -- Table name to load
    1                           -- Enable debug logging for development
);

-- Verify test data load and structure
SELECT table_name,
       column_count,
       row_count,
       last_updated
FROM development_metadata_summary
WHERE schema_name = 't_test_data'
  AND table_name  = 'transaction_summary';
```

---

**Utilized ASN GPT Prompt**

This was generated with "Complex Claude 3.5 Sonnet"-version

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Given the previous texts, create summary overview of the framework utilized by the DD-OSX team. Handle the following topics
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s) 
- virutal schema the part before "_tbl", "_viw_" of "_usp_" is the virual schema name
- If reference a SQL object make it into a clickable link to the documentation use this format "[`sql-object`](./<virtual-schema-name>/tables/<name-of-table>.md)" for tables and for procedure use "[`sql-object`](./<virtual-schema-name>/procedures/<name-of_procedure>.md)"

- The document structure handle the following topic, in the given order
  - Introduction (MAx 500 words, DO NOT make if longer then is required)
  - Components of the Framework (present as a table with columns SQL Objecttype (procedure, Table or View), Name, Description)
  - Add mermaid Diagram on how the various sql-objects are used and related to one another
  - Let the SQL-objects correlate to the Mermaid diagram, the text of diagram componnets must follow pattern `sql-object-name`.
  - Key Features
  - Provide 2 ro 3 practical coding examples

- At the End of the document, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - This was generated with "Complex Claud 4 sonnet"-version
  - calapsable text block with the used ASN GPT prompt, title "the prompt"
  - Add final blank line
  - Add the text "*end of document*"
  - Add final blank line
</details>

*end of document*