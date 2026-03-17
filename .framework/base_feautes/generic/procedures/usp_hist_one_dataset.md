# Functional Description of `generic_usp_hist_one_dataset` ([Back](../regression.md))

## Purpose

This stored procedure loads a single dataset for development testing by validating the existence of required view and table objects, then calling the generic load procedure to refresh the table data. It performs comprehensive validation checks to ensure both the source view and target table exist before attempting the data load operation. The procedure is designed for development environments where complete table refresh is needed for testing purposes.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_nm_schema | VARCHAR(128) | Schema name for the dataset (used to construct table and view names) |
| IN | ip_nm_table | VARCHAR(128) | Table name for the dataset (used to construct table and view names) |
| IN | ip_is_debugging | INT | Flag to enable/disable debug logging during execution |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.construct-object-names]<br>    B --> C[3.start-logging]<br>    C --> D[4.validate-view-exists]<br>    D --> E{5.check-view-existence}<br>    E -->|Not Found| F[6.log-view-error]<br>    E -->|Found| G[7.validate-table-exists]<br>    G --> H{8.check-table-existence}<br>    H -->|Not Found| I[9.log-table-error]<br>    H -->|Found| J[10.call-load-procedure]<br>    J --> K{11.check-load-status}<br>    K -->|Success| L[12.log-success-finish]<br>    K -->|Error| M[13.log-load-error]<br>    F --> EP([End Procedure])<br>    I --> EP<br>    M --> EP<br>    L --> EP<br>``` | **1. Initialize Variables**<br>Initialize local variables for logging, error handling, object names, and existence flags for validation checks<br><br>**2. Construct Object Names**<br>Build fully qualified table and view names using database, schema, and table parameters with appropriate naming conventions<br><br>**3. Start Logging**<br>Call `logging_usp_start` to begin execution tracking and `logging_usp_debug` for procedure start notification<br><br>**4. Validate View Exists**<br>Query `DBC.TablesV` system table to verify the existence of the required source view using TableKind filter<br><br>**5. Check View Existence**<br>Evaluate view existence result to determine if procedure should continue or terminate with validation error<br><br>**6. Log View Error**<br>Call `logging_usp_failed` with appropriate error message when required source view is not found<br><br>**7. Validate Table Exists**<br>Query `DBC.TablesV` system table to verify the existence of the target table for data loading<br><br>**8. Check Table Existence**<br>Evaluate table existence result to determine if data loading operation can proceed<br><br>**9. Log Table Error**<br>Call `logging_usp_failed` with appropriate error message when target table is not found<br><br>**10. Call Load Procedure**<br>Execute `generic_usp_load_view_into_table` with delete criteria '1=1' to perform complete table refresh<br><br>**11. Check Load Status**<br>Evaluate the status returned from the load procedure to determine success or failure<br><br>**12. Log Success Finish**<br>Call `logging_usp_finish` to complete successful execution logging with appropriate status<br><br>**13. Log Load Error**<br>Call `logging_usp_failed` when the load procedure returns an error status message |

## Examples

<details>
<summary>Example 1: Load Dataset with Debug Logging Enabled</summary>

```sql
-- Load single dataset for development with debug logging
CREATE OR REPLACE PROCEDURE test_hist_dataset_debug()
BEGIN
    DECLARE l_nm_schema      VARCHAR(128) DEFAULT 't_l2_func_test';
    DECLARE l_nm_table       VARCHAR(128) DEFAULT 'customer_data';
    DECLARE l_is_debugging   INT          DEFAULT 1;
    
    -- Create test view for the example
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_customer_data AS
    SELECT 'CUST001' AS customer_id,
           'John Doe' AS customer_name,
           CURRENT_DATE AS load_date;
    
    -- Create test table for the example
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_customer_data (
        customer_id VARCHAR(10),
        customer_name VARCHAR(100),
        load_date DATE
    );
    
    CALL ${nm_database_target}generic_usp_hist_one_dataset(
        l_nm_schema,
        l_nm_table,
        l_is_debugging
    );
    
    -- Verify data load results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_customer_data
    WHERE  customer_id = 'CUST001';
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_customer_data;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_customer_data;
    
END;

CALL test_hist_dataset_debug();
DROP PROCEDURE test_hist_dataset_debug;
```
</details>

<details>
<summary>Example 2: Load Dataset without Debug Logging</summary>

```sql
-- Load single dataset for production-like testing without debug
CREATE OR REPLACE PROCEDURE test_hist_dataset_production()
BEGIN
    DECLARE l_nm_schema      VARCHAR(128) DEFAULT 't_l2_func_test';
    DECLARE l_nm_table       VARCHAR(128) DEFAULT 'transaction_history';
    DECLARE l_is_debugging   INT          DEFAULT 0;
    
    -- Create test view for the example
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_transaction_history AS
    SELECT 'TXN001' AS transaction_id,
           'Payment' AS transaction_type,
           100.00 AS amount,
           CURRENT_TIMESTAMP AS transaction_date;
    
    -- Create test table for the example
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_transaction_history (
        transaction_id VARCHAR(20),
        transaction_type VARCHAR(50),
        amount DECIMAL(10,2),
        transaction_date TIMESTAMP
    );
    
    CALL ${nm_database_target}generic_usp_hist_one_dataset(
        l_nm_schema,
        l_nm_table,
        l_is_debugging
    );
    
    -- Verify data load results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_transaction_history
    WHERE  transaction_id   = 'TXN001'
       AND transaction_type = 'Payment'
       AND amount           = 100.00;
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_transaction_history;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_transaction_history;
    
END;

CALL test_hist_dataset_production();
DROP PROCEDURE test_hist_dataset_production;
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