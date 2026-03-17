# Functional Description of `generic_usp_drop_table` ([Back](../regression.md))

## Purpose

This stored procedure safely drops a table from the Teradata database with built-in error handling. It handles both schema-qualified and unqualified table names and implements intelligent error handling that distinguishes between actual errors and expected "table does not exist" scenarios. The procedure provides comprehensive logging functionality and returns appropriate status messages to indicate success or failure of the drop operation.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_id_log_parent | CHAR(64) | Parent log identifier for tracking procedure execution |
| IN | ip_schema_name | VARCHAR(128) | Database/schema name where table resides (NULL for current database) |
| IN | ip_table_name | VARCHAR(128) | Name of the table to be dropped |
| OUT | op_status_text | VARCHAR(999) | Status message indicating success or error details |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.setup-error-handler]<br>    B --> C[3.build-drop-sql]<br>    C --> D[4.execute-drop-statement]<br>    D --> E{5.check-execution-result}<br>    E -->|Success| F[6.set-success-status]<br>    E -->|Expected Error| G[7.ignore-not-exists-error]<br>    E -->|Actual Error| H[8.log-error-and-fail]<br>    F --> EP([End Procedure])<br>    G --> EP<br>    H --> EP<br>``` | **1. Initialize Variables**<br>Initialize local variables including procedure name, error text variables, SQL statement variable, and logging identifier<br><br>**2. Setup Error Handler**<br>Establish SQL exception handler that captures error messages and determines if the error is expected (table doesn't exist) or an actual failure<br><br>**3. Build Drop SQL**<br>Construct DROP TABLE statement with conditional schema qualification based on whether ip_schema_name parameter is provided<br><br>**4. Execute Drop Statement**<br>Execute the dynamically built DROP TABLE statement using `DBC.SysExecSQL` system procedure<br><br>**5. Check Execution Result**<br>Evaluate if the drop operation succeeded, failed with expected error, or failed with unexpected error<br><br>**6. Set Success Status**<br>Set output parameter op_status_text to 'Success' when table is successfully dropped<br><br>**7. Ignore Not Exists Error**<br>Handle the expected "table does not exist" error gracefully without logging as failure (implicit success)<br><br>**8. Log Error and Fail**<br>Call `logging_usp_start` and `logging_usp_failed` for unexpected errors and set appropriate error status message |

## Examples

<details>
<summary>Example 1: Drop Table from Specific Schema</summary>

```sql
-- Drop table from specific schema
CREATE OR REPLACE PROCEDURE test_drop_schema_table()
BEGIN
    DECLARE l_id_log_parent    CHAR(64)     DEFAULT 'TEST001';
    DECLARE l_schema_name      VARCHAR(128) DEFAULT 't_l2_func_test';
    DECLARE l_table_name       VARCHAR(128) DEFAULT 'test_table_to_drop';
    DECLARE l_status_text      VARCHAR(999);
    
    -- First create a test table
    CREATE TABLE t_l2_func_test.test_table_to_drop AS (
        SELECT 1 AS test_id, 'test_data' AS test_value
    ) WITH DATA;
    
    -- Now drop the table using the procedure
    CALL ${nm_database_target}generic_usp_drop_table(
        l_id_log_parent,
        l_schema_name,
        l_table_name,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
END;

CALL test_drop_schema_table();
DROP PROCEDURE test_drop_schema_table;
```
</details>

<details>
<summary>Example 2: Drop Volatile Table (No Schema)</summary>

```sql
-- Drop volatile table without schema qualification
CREATE OR REPLACE PROCEDURE test_drop_volatile_table()
BEGIN
    DECLARE l_id_log_parent    CHAR(64)     DEFAULT 'TEST002';
    DECLARE l_schema_name      VARCHAR(128) DEFAULT NULL;
    DECLARE l_table_name       VARCHAR(128) DEFAULT 'temp_volatile_table';
    DECLARE l_status_text      VARCHAR(999);
    
    -- First create a volatile test table
    CREATE MULTISET VOLATILE TABLE temp_volatile_table AS (
        SELECT 'volatile_test' AS test_type,
               CURRENT_TIMESTAMP AS created_time
    ) WITH DATA ON COMMIT PRESERVE ROWS;
    
    -- Now drop the volatile table using the procedure
    CALL ${nm_database_target}generic_usp_drop_table(
        l_id_log_parent,
        l_schema_name,
        l_table_name,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
END;

CALL test_drop_volatile_table();
DROP PROCEDURE test_drop_volatile_table;
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
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
   - Inlcude declare for all paramters using a 'l_'-prefix for local variables. 
   - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
   - variable in the temporal procedure have the prefix `l_`
   - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
   - Do use the fullname of the procedure, for example 't_l2_func_test.regression_usp_result'.
   - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
   - cleanup any temporal procedures

- At the End of the document after the Examples, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - calapsable text block with the used ASN GPT prompt, title "the prompt" without everthing after
</details>

*end of document*