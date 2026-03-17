# Functional Description of `generic_usp_hist_view_into_table` ([Back](../regression.md))

## Purpose

This stored procedure implements a historization process that loads data from a view into a table using Slowly Changing Dimension Type 2 (SCD2) methodology. It creates a temporal staging table from the source view, then performs two main operations: ending existing records that no longer exist in the source and inserting new or changed records. The procedure maintains historical data integrity by managing technical validity timestamps and actual record flags, enabling point-in-time data analysis.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ip_nm_schema | VARCHAR(128) | Schema name used to construct table and view names |
| IN | ip_nm_table | VARCHAR(128) | Table name used to construct table and view names |
| IN | ip_tx_delete_criteria | VARCHAR(25000) | Delete criteria for data filtering (not used in current implementation) |
| IN | ip_is_debugging | INT | Flag to enable/disable debug logging during execution |
| OUT | op_status_text | VARCHAR(999) | Status message indicating success or error details |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.construct-object-names]<br>    B --> C[3.start-logging]<br>    C --> D[4.build-column-list]<br>    D --> E[5.create-staging-table]<br>    E --> F[6.extract-max-valid-start]<br>    F --> G[7.end-obsolete-records]<br>    G --> H[8.insert-new-records]<br>    H --> I[9.cleanup-staging-table]<br>    I --> J[10.finish-logging]<br>    J --> EP([End Procedure])<br>``` | **1. Initialize Variables**<br>Initialize local variables for logging, object names, SQL statements, column lists, and meta attributes used in historization process<br><br>**2. Construct Object Names**<br>Build fully qualified table, view, and staging table names using schema and table parameters with appropriate naming conventions<br><br>**3. Start Logging**<br>Call `logging_usp_start` to begin execution tracking and `logging_usp_debug` for procedure start notification<br><br>**4. Build Column List**<br>Query `DBC.ColumnsV` to dynamically construct column list excluding meta attributes, ensuring proper column ordering by ColumnId<br><br>**5. Create Staging Table**<br>Extract view definition from `DBC.TablesV`, modify SQL to add CTE wrapper, and call `generic_usp_create_table` to create temporal staging table<br><br>**6. Extract Max Valid Start**<br>Query staging table to determine the maximum meta_dt_tech_valid_start timestamp for use in historization logic<br><br>**7. End Obsolete Records**<br>Update existing active records in target table that no longer exist in source by setting meta_dt_tech_valid_ended and meta_is_actual flags<br><br>**8. Insert New Records**<br>Insert records from staging table that don't exist as active records in target table, maintaining business key and record hash comparisons<br><br>**9. Cleanup Staging Table**<br>Call `generic_usp_drop_table` to remove the temporal staging table created during the process<br><br>**10. Finish Logging**<br>Call `logging_usp_finish` to complete execution logging with appropriate status information |

## Examples

<details>
<summary>Example 1: Historize Customer Data with Debug Logging</summary>

```sql
-- Historize customer data from view to table with debugging
CREATE OR REPLACE PROCEDURE test_hist_customer_data()
BEGIN
    DECLARE l_nm_schema          VARCHAR(128)   DEFAULT 't_l2_func_test';
    DECLARE l_nm_table           VARCHAR(128)   DEFAULT 'customer_master';
    DECLARE l_tx_delete_criteria VARCHAR(25000) DEFAULT '';
    DECLARE l_is_debugging       INT            DEFAULT 1;
    DECLARE l_status_text        VARCHAR(999);
    
    -- Create test view with customer data
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_customer_master AS
    SELECT 'CUST001' AS customer_id,
           'John Smith' AS customer_name,
           'Active' AS status,
           CURRENT_TIMESTAMP AS meta_dt_tech_valid_start,
           CAST(NULL AS TIMESTAMP) AS meta_dt_tech_valid_ended,
           1 AS meta_is_actual,
           'ABC123' AS meta_ch_rh,
           'CUST001' AS meta_ch_bk,
           1 AS meta_ni_rn,
           'CUST001' AS meta_ch_pk;
    
    -- Create test target table
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_customer_master (
        customer_id VARCHAR(10),
        customer_name VARCHAR(100),
        status VARCHAR(20),
        meta_dt_tech_valid_start TIMESTAMP,
        meta_dt_tech_valid_ended TIMESTAMP,
        meta_is_actual INT,
        meta_ch_rh VARCHAR(32),
        meta_ch_bk VARCHAR(100),
        meta_ni_rn INT,
        meta_ch_pk VARCHAR(100)
    );
    
    CALL ${nm_database_target}generic_usp_hist_view_into_table(
        l_nm_schema,
        l_nm_table,
        l_tx_delete_criteria,
        l_is_debugging,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify historization results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_customer_master
    WHERE  customer_id = 'CUST001'
       AND meta_is_actual = 1;
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_customer_master;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_customer_master;
    
END;

CALL test_hist_customer_data();
DROP PROCEDURE test_hist_customer_data;
```
</details>

<details>
<summary>Example 2: Historize Product Data without Debug Logging</summary>

```sql
-- Historize product data for production environment
CREATE OR REPLACE PROCEDURE test_hist_product_data()
BEGIN
    DECLARE l_nm_schema          VARCHAR(128)   DEFAULT 't_l2_func_test';
    DECLARE l_nm_table           VARCHAR(128)   DEFAULT 'product_catalog';
    DECLARE l_tx_delete_criteria VARCHAR(25000) DEFAULT '';
    DECLARE l_is_debugging       INT            DEFAULT 0;
    DECLARE l_status_text        VARCHAR(999);
    
    -- Create test view with product data
    CREATE VIEW ${nm_database_target}t_l2_func_test_viw_product_catalog AS
    SELECT 'PROD001' AS product_id,
           'Widget A' AS product_name,
           29.99 AS price,
           'Electronics' AS category,
           CURRENT_TIMESTAMP AS meta_dt_tech_valid_start,
           CAST(NULL AS TIMESTAMP) AS meta_dt_tech_valid_ended,
           1 AS meta_is_actual,
           'DEF456' AS meta_ch_rh,
           'PROD001' AS meta_ch_bk,
           1 AS meta_ni_rn,
           'PROD001' AS meta_ch_pk;
    
    -- Create test target table
    CREATE TABLE ${nm_database_target}t_l2_func_test_tbl_product_catalog (
        product_id VARCHAR(10),
        product_name VARCHAR(100),
        price DECIMAL(10,2),
        category VARCHAR(50),
        meta_dt_tech_valid_start TIMESTAMP,
        meta_dt_tech_valid_ended TIMESTAMP,
        meta_is_actual INT,
        meta_ch_rh VARCHAR(32),
        meta_ch_bk VARCHAR(100),
        meta_ni_rn INT,
        meta_ch_pk VARCHAR(100)
    );
    
    CALL ${nm_database_target}generic_usp_hist_view_into_table(
        l_nm_schema,
        l_nm_table,
        l_tx_delete_criteria,
        l_is_debugging,
        l_status_text
    );
    
    SELECT l_status_text AS procedure_status;
    
    -- Verify historization results
    SELECT *
    FROM   ${nm_database_target}t_l2_func_test_tbl_product_catalog
    WHERE  product_id = 'PROD001'
       AND category   = 'Electronics'
       AND price      = 29.99;
    
    -- Cleanup test objects
    DROP VIEW ${nm_database_target}t_l2_func_test_viw_product_catalog;
    DROP TABLE ${nm_database_target}t_l2_func_test_tbl_product_catalog;
    
END;

CALL test_hist_product_data();
DROP PROCEDURE test_hist_product_data;
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