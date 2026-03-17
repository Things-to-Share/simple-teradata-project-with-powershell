# Functional Description of `generic_usp_load_view_into_table` ([Back](../regression.md))

## Purpose

This stored procedure performs a complete refresh of a target table by loading data from a corresponding view. It dynamically constructs column lists from the target table metadata, deletes existing data based on configurable criteria, then inserts fresh data from the source view. The procedure handles complex view definitions including those with Common Table Expressions (CTEs) and ensures proper column alignment between source and target structures.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_nm_schema | VARCHAR(128) | Schema name used to construct table and view names |
| IN | ip_nm_table | VARCHAR(128) | Table name used to construct table and view names |
| IN | ip_tx_delete_criteria | VARCHAR(25000) | WHERE clause criteria for deleting existing data (defaults to '1=1' if empty) |
| IN | ip_is_debugging | INT | Flag to enable/disable debug logging during execution |
| OUT | op_status_text | VARCHAR(999) | Status message indicating success or error details |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.construct-object-names]<br>    B --> C[3.start-logging]<br>    C --> D[4.build-column-list]<br>    D --> E[5.delete-existing-data]<br>    E --> F[6.extract-view-definition]<br>    F --> G[7.process-view-sql]<br>    G --> H[8.wrap-with-cte]<br>    H --> I[9.construct-insert-statement]<br>    I --> J[10.execute-insert-operation]<br>    J --> K[11.finish-logging]<br>    K --> EP([End Procedure])<br>``` | **1. Initialize Variables**<br>Initialize local variables for logging, object names, SQL statements, column lists, and string manipulation helpers<br><br>**2. Construct Object Names**<br>Build fully qualified table and view names using database, schema, and table parameters with standard naming conventions<br><br>**3. Start Logging**<br>Call `logging_usp_start` to begin execution tracking and `logging_usp_debug` for procedure start notification<br><br>**4. Build Column List**<br>Query `DBC.ColumnsV` to dynamically construct column list excluding meta_dt_created_at column, ensuring proper column ordering by ColumnId<br><br>**5. Delete Existing Data**<br>Execute DELETE statement using provided criteria or default '1=1' through `generic_usp_exec_dynamic_sql` with retry logic<br><br>**6. Extract View Definition**<br>Query `DBC.TablesV` to retrieve the complete RequestText for the source view definition<br><br>**7. Process View SQL**<br>Remove the "REPLACE VIEW ... AS" portion from the view definition to extract the core SELECT statement<br><br>**8. Wrap with CTE**<br>Analyze SQL structure and wrap in cte_final CTE, handling both simple queries and existing CTE structures appropriately<br><br>**9. Construct Insert Statement**<br>Build complete INSERT INTO statement with target table name, column list, and CTE-wrapped source query<br><br>**10. Execute Insert Operation**<br>Execute the dynamically constructed INSERT statement through `generic_usp_exec_dynamic_sql` with retry capabilities<br><br>**11. Finish Logging**<br>Call `logging_usp_finish` to complete execution logging with appropriate status information |

## Examples

<details>
<summary>Example 1: Load Customer Data with Specific Delete Criteria</summary>

```sql
-- Load customer data with specific delete criteria and debug logging
CREATE OR REPLACE PROCEDURE test_load_customer_view()
BEGIN
    DECLARE l_nm_schema          VARCHAR(128)   DEFAULT 't_l2_func_test';
    DECLARE l_nm_table           VARCHAR(128)   DEFAULT 'customer_summary';
    DECLARE l_tx_delete_criteria VARCHAR(25000) DEFAULT 'customer_status = ''INACTIVE''';
    DECLARE l_is_debugging       INT            DEFAULT 1;
    DECLARE l_status_text        VARCHAR(999);
    
    -- Create test view with customer data
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_customer_summary AS
    SELECT 'CUST001' AS customer_id,
           'John Doe' AS customer_name,
           'ACTIVE' AS customer_status,
           CURRENT_DATE AS last_updated,
           100.00 AS total_balance;
    
    -- Create test target table
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_customer_summary (
        customer_id VARCHAR(10),
        customer_name VARCHAR(100),
        customer_status VARCHAR(20),
        last_updated DATE,
        total_balance DECIMAL(10,2),
        meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Insert some test data to be deleted
    INSERT INTO ${nm_database_target}t_l2_func_test_tbl_customer_summary 
    VALUES ('OLD001', 'Old Customer', 'INACTIVE', CURRENT_DATE, 50.00, CURRENT_TIMESTAMP);
    
    CALL ${nm_database_target}generic_usp_load_view_into_table(
        l_nm_schema,
        l_nm_table,
        l_tx_delete_criteria,
        l_is_debugging,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify load results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_customer_summary
    WHERE  customer_id     = 'CUST001'
       AND customer_status = 'ACTIVE'
       AND total_balance   = 100.00;
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_customer_summary;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_customer_summary;
    
END;

CALL test_load_customer_view();
DROP PROCEDURE test_load_customer_view;
```
</details>

<details>
<summary>Example 2: Complete Table Refresh without Debug Logging</summary>

```sql
-- Complete table refresh for production environment
CREATE OR REPLACE PROCEDURE test_load_complete_refresh()
BEGIN
    DECLARE l_nm_schema          VARCHAR(128)   DEFAULT 't_l2_func_test';
    DECLARE l_nm_table           VARCHAR(128)   DEFAULT 'product_inventory';
    DECLARE l_tx_delete_criteria VARCHAR(25000) DEFAULT '';
    DECLARE l_is_debugging       INT            DEFAULT 0;
    DECLARE l_status_text        VARCHAR(999);
    
    -- Create test view with complex CTE structure
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_product_inventory AS
    WITH product_base AS (
        SELECT 'PROD001' AS product_id,
               'Widget A' AS product_name,
               50 AS quantity_on_hand
    ),
    inventory_calc AS (
        SELECT product_id,
               product_name,
               quantity_on_hand,
               CASE WHEN quantity_on_hand > 25 THEN 'IN_STOCK' ELSE 'LOW_STOCK' END AS stock_status
        FROM product_base
    )
    SELECT product_id,
           product_name,
           quantity_on_hand,
           stock_status,
           CURRENT_TIMESTAMP AS last_calculated
    FROM inventory_calc;
    
    -- Create test target table
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_product_inventory (
        product_id VARCHAR(10),
        product_name VARCHAR(100),
        quantity_on_hand INT,
        stock_status VARCHAR(20),
        last_calculated TIMESTAMP,
        meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CALL ${nm_database_target}generic_usp_load_view_into_table(
        l_nm_schema,
        l_nm_table,
        l_tx_delete_criteria,
        l_is_debugging,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify load results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_product_inventory
    WHERE  product_id      = 'PROD001'
       AND stock_status    = 'IN_STOCK'
       AND quantity_on_hand = 50;
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_product_inventory;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_product_inventory;
    
END;

CALL test_load_complete_refresh();
DROP PROCEDURE test_load_complete_refresh;
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