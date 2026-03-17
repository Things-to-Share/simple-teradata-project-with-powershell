# Functional Description of `generic_usp_create_table` ([Back](../regression.md))

## Purpose

This stored procedure creates either volatile or persistent tables in Teradata based on a provided SELECT query. It supports creating tables with optional primary indexes and provides comprehensive error handling and logging. The procedure can create volatile tables that exist only for the session duration or persistent tables that remain in the database. It includes built-in logging functionality and automatic cleanup of existing tables with the same name before creation.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_id_log_parent | CHAR(64) | Parent log identifier for tracking procedure execution |
| IN | ip_schema_name | VARCHAR(128) | Schema name for the table (NULL for volatile tables) |
| IN | ip_table_name | VARCHAR(128) | Name of the table to be created |
| IN | ip_index_list | VARCHAR(999) | Comma-separated list of columns for primary index (NULL for no primary index) |
| IN | ip_tx_query | VARCHAR(31390) | SELECT query that defines the table structure and data |
| IN | is_volatile | INT | Flag indicating if table should be volatile (1) or persistent (0) |
| IN | ip_is_logging_on | INT | Flag to enable/disable logging functionality |
| OUT | op_status_text | VARCHAR(999) | Status message indicating success or error details |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.start-logging]<br>    B --> C[3.build-sql-statement]<br>    C --> D[4.drop-existing-table]<br>    D --> E{5.check-drop-status}<br>    E -->|Success| F[6.execute-create-table]<br>    E -->|Error| G[7.set-error-status]<br>    F --> H[8.update-affected-rows]<br>    H --> I[9.set-success-status]<br>    G --> EP([End Procedure])<br>    I --> EP<br>``` | **1. Initialize Variables**<br>Initialize local variables including procedure name, error handling variables, and SQL statement building components (newline, quotes, etc.)<br><br>**2. Start Logging**<br>Call `logging_usp_debug` and prepare logging message with procedure name and parameters for execution tracking<br><br>**3. Build SQL Statement**<br>Construct CREATE TABLE SQL statement based on is_volatile flag, incorporating the provided query, index specifications, and appropriate table options<br><br>**4. Drop Existing Table**<br>Call `generic_usp_drop_table` to remove any existing table with the same name to prevent conflicts<br><br>**5. Check Drop Status**<br>Evaluate the status from the drop operation to determine if procedure should continue or terminate with error<br><br>**6. Execute Create Table**<br>Execute the dynamically built CREATE TABLE statement using `DBC.SysExecSQL` system procedure<br><br>**7. Set Error Status**<br>If drop operation failed, set the output status parameter to the error message and terminate procedure<br><br>**8. Update Affected Rows**<br>Update the logging table with the count of rows in the newly created table for audit purposes<br><br>**9. Set Success Status**<br>Set the output status parameter to 'Success' indicating successful table creation |

## Examples

<details>
<summary>Example 1: Create Volatile Table</summary>

```sql
-- Create volatile table example
CREATE OR REPLACE PROCEDURE test_volatile_example()
BEGIN
    DECLARE l_id_log_parent    CHAR(64)      DEFAULT 'TEST001';
    DECLARE l_schema_name      VARCHAR(128)  DEFAULT NULL;
    DECLARE l_table_name       VARCHAR(128)  DEFAULT 'test_volatile_table';
    DECLARE l_index_list       VARCHAR(999)  DEFAULT NULL;
    DECLARE l_tx_query         VARCHAR(31390) DEFAULT 'SELECT 1 AS test_value, ''volatile_test'' AS description';
    DECLARE l_is_volatile      INT           DEFAULT 1;
    DECLARE l_is_logging_on    INT           DEFAULT 1;
    DECLARE l_status_text      VARCHAR(999);
    
    CALL ${nm_database_target}generic_usp_create_table(
        l_id_log_parent,
        l_schema_name,
        l_table_name,
        l_index_list,
        l_tx_query,
        l_is_volatile,
        l_is_logging_on,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify table creation
    SELECT *
    FROM   test_volatile_table
    WHERE  test_value = 1;
    
END;

CALL test_volatile_example();
DROP PROCEDURE test_volatile_example;
```
</details>

<details>
<summary>Example 2: Create Persistent Table with Index</summary>

```sql
-- Create persistent table with primary index
CREATE OR REPLACE PROCEDURE test_persistent_example()
BEGIN
    DECLARE l_id_log_parent    CHAR(64)      DEFAULT 'TEST002';
    DECLARE l_schema_name      VARCHAR(128)  DEFAULT 't_l2_func_test';
    DECLARE l_table_name       VARCHAR(128)  DEFAULT 'test_persistent_table';
    DECLARE l_index_list       VARCHAR(999)  DEFAULT 'customer_id';
    DECLARE l_tx_query         VARCHAR(31390) DEFAULT 'SELECT 100 AS customer_id, ''John Doe'' AS customer_name, CURRENT_DATE AS created_date';
    DECLARE l_is_volatile      INT           DEFAULT 0;
    DECLARE l_is_logging_on    INT           DEFAULT 1;
    DECLARE l_status_text      VARCHAR(999);
    
    CALL ${nm_database_target}generic_usp_create_table(
        l_id_log_parent,
        l_schema_name,
        l_table_name,
        l_index_list,
        l_tx_query,
        l_is_volatile,
        l_is_logging_on,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify table creation
    SELECT *
    FROM   t_l2_func_test.test_persistent_table
    WHERE  customer_id = 100
       AND customer_name = 'John Doe';
    
END;

CALL test_persistent_example();
DROP PROCEDURE test_persistent_example;
```
</details>

---

**Utilized ASN GPT Prompt**

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "Procedure" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_usp_" is the functional schema name

The document structure should have the topics in the give order: 
- Tilte should be "Functional Descripton of `<name-of-procedure>` ([Back](../regression.md))"
- Purpuse
  - This is short description, do NOT make it longer then required to get a general description of the purpuse of the procedure.
  - Max 200 words.
- Parameters
  - If there are None, skip this part.
  - Input (and if applicable Output), present these in table with columns direction, parameter, datatype and description.
- Logical/functional steps of the procedure
  - This has two columns, column 1 width 35% has the mermaid diagram, column 2 width 65% lists the steps with descriptions
  - Add Mermaid Diagram
    - Diagram should have `Start Procedure` and `End Procedure` using the formatting `SP([Start Procedure])` and `EP([End Procedure])`
    - Other process steps shoul have the following formatting `[...]`
  - number the logical/functional step
  - per step provide title in bold format
  - per step provide short description, if other objects are reference these can be shown, use `name-object`-format
  - Let the Steps correlate to the Mermaid diagram, the text of diagram block must follow pattern `#.step-name`,  # is substituted by the number correlating with the step.
- Examples
   - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be cal