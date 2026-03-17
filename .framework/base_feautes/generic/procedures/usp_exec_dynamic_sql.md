# Functional Description of `generic_usp_exec_dynamic_sql` ([Back](../regression.md))

## Purpose

This stored procedure executes dynamic SQL statements with built-in retry logic for handling transient database errors. It provides robust error handling specifically for deadlocks and spool space issues by implementing configurable retry attempts with wait intervals. The procedure includes comprehensive logging functionality to track execution attempts, errors, and final outcomes, making it suitable for executing complex dynamic SQL operations in production environments where temporary resource conflicts may occur.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_id_log_parent | CHAR(64) | Parent log identifier for tracking procedure execution hierarchy |
| IN | ip_procedure_name | VARCHAR(128) | Name of the calling procedure for logging purposes |
| IN | ip_message_text | VARCHAR(999) | Descriptive message about the SQL operation being performed |
| IN | ip_dynamic_sql_text | VARCHAR(32000) | Dynamic SQL statement to be executed |
| IN | ip_max_retry_times | INT | Maximum number of retry attempts for transient errors |
| OUT | op_status_text | VARCHAR(999) | Status message indicating success or final error details |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.setup-retry-loop]<br>    B --> C[3.setup-error-handler]<br>    C --> D[4.execute-dynamic-sql]<br>    D --> E{5.check-execution-result}<br>    E -->|Success| F[6.break-retry-loop]<br>    E -->|Transient Error| G[7.classify-error-type]<br>    E -->|Critical Error| H[8.log-critical-error]<br>    G --> I{9.check-retry-conditions}<br>    I -->|Can Retry| J[10.wait-and-log-retry]<br>    I -->|Max Retries| K[11.log-max-retries-exceeded]<br>    J --> B<br>    K --> L[12.set-error-status]<br>    H --> L<br>    F --> M[13.log-success-finish]<br>    M --> EP([End Procedure])<br>    L --> EP<br>``` | **1. Initialize Variables**<br>Initialize local variables including procedure name, try counter, error classification code, and affected rows counter<br><br>**2. Setup Retry Loop**<br>Begin WHILE loop that continues until maximum retry attempts reached or error classification indicates non-retryable error<br><br>**3. Setup Error Handler**<br>Establish SQL exception handler that captures error details and classifies errors as transient (deadlock/spool space) or critical<br><br>**4. Execute Dynamic SQL**<br>Execute the provided dynamic SQL statement using `DBC.SysExecSQL` and capture affected row count using ACTIVITY_COUNT<br><br>**5. Check Execution Result**<br>Evaluate if SQL execution succeeded, failed with transient error, or failed with critical error<br><br>**6. Break Retry Loop**<br>Set try counter to maximum value to exit retry loop when SQL execution is successful<br><br>**7. Classify Error Type**<br>Analyze error message to determine if error is deadlock, spool space issue, or other critical error using pattern matching<br><br>**8. Log Critical Error**<br>Call `logging_usp_failed` for non-retryable errors and set appropriate error status message<br><br>**9. Check Retry Conditions**<br>Evaluate whether current try count is below maximum and error type allows retry attempts<br><br>**10. Wait and Log Retry**<br>Call `generic_usp_wait` for 1 second delay and log retry attempt using `logging_usp_start` and `logging_usp_finish`<br><br>**11. Log Max Retries Exceeded**<br>Log failure when maximum retry attempts have been reached for transient errors<br><br>**12. Set Error Status**<br>Set output parameter op_status_text with appropriate error message and exit procedure<br><br>**13. Log Success Finish**<br>Call `logging_usp_finish` with affected row count and set op_status_text to 'Success' for successful execution |

## Examples

<details>
<summary>Example 1: Execute Simple Dynamic SQL with Retry</summary>

```sql
-- Execute dynamic SQL with retry capability
CREATE OR REPLACE PROCEDURE test_dynamic_sql_simple()
BEGIN
    DECLARE l_id_log_parent     CHAR(64)      DEFAULT 'TEST001';
    DECLARE l_procedure_name    VARCHAR(128)  DEFAULT 'test_dynamic_sql_simple';
    DECLARE l_message_text      VARCHAR(999)  DEFAULT 'Create test table with dynamic SQL';
    DECLARE l_dynamic_sql_text  VARCHAR(32000) DEFAULT 'CREATE MULTISET VOLATILE TABLE temp_test_table AS (SELECT 1 AS test_id, ''dynamic_sql_test'' AS test_description) WITH DATA ON COMMIT PRESERVE ROWS';
    DECLARE l_max_retry_times   INT           DEFAULT 3;
    DECLARE l_status_text       VARCHAR(999);
    
    CALL ${nm_database_target}generic_usp_exec_dynamic_sql(
        l_id_log_parent,
        l_procedure_name,
        l_message_text,
        l_dynamic_sql_text,
        l_max_retry_times,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify table creation if successful
    SELECT *
    FROM   temp_test_table
    WHERE  test_id = 1;
    
    -- Cleanup
    DROP TABLE temp_test_table;
    
END;

CALL test_dynamic_sql_simple();
DROP PROCEDURE test_dynamic_sql_simple;
```
</details>

<details>
<summary>Example 2: Execute Complex Dynamic SQL with High Retry Count</summary>

```sql
-- Execute complex dynamic SQL with multiple retry attempts
CREATE OR REPLACE PROCEDURE test_dynamic_sql_complex()
BEGIN
    DECLARE l_id_log_parent     CHAR(64)      DEFAULT 'TEST002';
    DECLARE l_procedure_name    VARCHAR(128)  DEFAULT 'test_dynamic_sql_complex';
    DECLARE l_message_text      VARCHAR(999)  DEFAULT 'Insert data into existing table using dynamic SQL';
    DECLARE l_dynamic_sql_text  VARCHAR(32000) DEFAULT 'CREATE TABLE t_l2_func_test.dynamic_test_results AS (SELECT CURRENT_TIMESTAMP AS execution_time, ''Complex SQL Test'' AS test_type, 100 AS record_count) WITH DATA';
    DECLARE l_max_retry_times   INT           DEFAULT 5;
    DECLARE l_status_text       VARCHAR(999);
    
    CALL ${nm_database_target}generic_usp_exec_dynamic_sql(
        l_id_log_parent,
        l_procedure_name,
        l_message_text,
        l_dynamic_sql_text,
        l_max_retry_times,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify table creation and data if successful
    SELECT *
    FROM   t_l2_func_test.dynamic_test_results
    WHERE  test_type     = 'Complex SQL Test'
       AND record_count  = 100;
    
    -- Cleanup
    DROP TABLE t_l2_func_test.dynamic_test_results;
    
END;

CALL test_dynamic_sql_complex();
DROP PROCEDURE test_dynamic_sql_complex;
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