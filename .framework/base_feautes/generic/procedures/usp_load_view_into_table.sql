REPLACE PROCEDURE ${nm_database_target}generic_usp_load_view_into_table (
  --
  -- Input Parameters
  IN ip_nm_schema          VARCHAR(128),
  IN ip_nm_table           VARCHAR(128),
  IN ip_tx_delete_criteria VARCHAR(25000),
  IN ip_is_debugging       INT,
  --
  -- Output Parameters
  OUT op_status_text VARCHAR(999)
  --
  -- Example:
  -- CALL ${nm_database_target}generic_usp_load_view_into_table (
  --
  --
  --
  --
  --
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_procedure_name   VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_load_view_into_table';
  DECLARE l_message_text     VARCHAR(999); --> These are used from the input, for this the constructed message form the calling procedure will provide context.
  DECLARE l_message_text_ext VARCHAR(999);
  DECLARE l_tx_error         VARCHAR(2000);
  DECLARE l_id_log           CHAR(64);
  DECLARE l_tx_sql           VARCHAR(32000); --> the SQL Statement of the calling procedure will be executed.
  DECLARE l_ls_columns       VARCHAR(25000);
  DECLARE l_nm_database      VARCHAR(128) DEFAULT '${nm_database_target}';
  DECLARE l_nm_schema_table  VARCHAR(128);
  DECLARE l_nm_schema_view   VARCHAR(128);
  --
  -- Helper in String handling
  DECLARE l_ni_position_last_select INT;
  DECLARE l_ni_position_as          INT;
  --
  CALL ${nm_database_target}logging_usp_debug (l_procedure_name||' Started', ip_is_debugging);
  --
  BEGIN
    --
    -- Declare Error Handler
    DECLARE exit handler for sqlexception BEGIN GET diagnostics exception 1 l_tx_error = message_text; 
      CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);
      SET op_status_text = l_tx_error;
    END;
    --
    -- Set Schema / Table
    SET l_nm_schema_table = l_nm_database || ip_nm_schema || '_' || ip_nm_table;
    SET l_nm_schema_view  = OREPLACE(l_nm_schema_table, '_tbl_', '_viw_');
    --
    -- Initialize local Variables
    SET l_message_text = 'Load data from view `'||l_nm_schema_view||'` into table `'||l_nm_schema_table||'`';
    SET op_status_text = '';
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, l_tx_sql, 1, l_id_log);
    --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 0: Build List Columns';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      SET l_ls_columns = '';
      FOR col AS (
        SELECT c.ColumnName FROM DBC.ColumnsV  AS c
        WHERE c.DataBaseName || '.' || c.TableName = l_nm_schema_table
        AND c.ColumnName    <> 'meta_dt_created_at'
        ORDER BY c.ColumnId ASC
      ) DO
        SET l_ls_columns = CAST(l_ls_columns || CASE WHEN l_ls_columns = '' THEN '' ELSE ', ' END || col.ColumnName as VARCHAR(25000));
      END FOR;
      CALL ${nm_database_target}logging_usp_debug ('Columns: '||NVL(l_ls_columns,'No Columns'), ip_is_debugging);
    END IF;
    --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 1: Delete Existing Metadata';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Build SQL Statement
      SET l_tx_sql = 'DELETE FROM '||l_nm_schema_table||' AS d WHERE ' || CASE WHEN NVL(ip_tx_delete_criteria, '') <> '' THEN ip_tx_delete_criteria ELSE '1=1' END;
      --
      -- Execute SQL Statement
      CALL ${nm_database_target}generic_usp_exec_dynamic_sql ( l_id_log,
        /* ip_procedure_name   */ l_procedure_name,
        /* ip_message_text     */ l_message_text_ext,
        /* ip_dynamic_sql_text */ l_tx_sql,
        /* ip_max_retry_times  */ 3,
        /* op_status_text      */ op_status_text
      );
      --
    END IF;
      --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 2: Insert Current Metadata';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Build SQL Statment
      SET l_tx_sql = (
        SELECT TRIM(NVL(t.RequestText,'')) AS tx_sql
        FROM DBC.TablesV AS t
        WHERE t.TableKind   IN ('V')
        AND   t.DataBaseName || '.' || t.TableName = l_nm_schema_view
      );
      CALL ${nm_database_target}logging_usp_debug ('l_tx_sql : ' || l_tx_sql, ip_is_debugging);
      --
      -- Remover the "REPLACE VIEW ...."-part.
      SET l_ni_position_as = POSITION(' AS ' IN UPPER(l_tx_sql)) + 4;
      CALL ${nm_database_target}logging_usp_debug ('l_ni_position_as : ' ||CAST(l_ni_position_as AS varchar(4)), ip_is_debugging);
      SET l_tx_sql = SUBSTR(l_tx_sql, l_ni_position_as, LENGTH(l_tx_sql)-l_ni_position_as);
      --
      -- If SQL Statement does not start with "WITH" then wrap the whole query in cte_final.
      IF (UPPER(SUBSTR(l_tx_sql, 1, 4))<>'WITH') THEN
        --
        SET l_tx_sql = 'WITH src AS ('
          ||CHR(10)|| l_tx_sql
          ||CHR(10)|| ')';
          --
      ELSE
        --
        -- Check it "SELECT * FROM src" is found, if NOT throw error
        IF (POSITION('SELECT * FROM src' IN l_tx_sql) = 0) THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Definition error in '||l_nm_schema_view||' `SELECT * FROM src` is missing, this must be last statement!';
        ELSE
          --
          -- Find the Last SELECT
          SET l_ni_position_last_select = (LENGTH(l_tx_sql) - POSITION(REVERSE('SELECT') IN REVERSE(UPPER(l_tx_sql))) - 5);
          CALL ${nm_database_target}logging_usp_debug ('l_ni_position_last_select : ' ||CAST(l_ni_position_last_select AS varchar(4)), ip_is_debugging);
          --
          SET l_tx_sql = SUBSTR(l_tx_sql, 1, l_ni_position_last_select-1);
          CALL ${nm_database_target}logging_usp_debug ('l_tx_sql : ' || l_tx_sql, ip_is_debugging);
          --
        END IF;
      END IF;
      --
      -- Add "INSERT INTO"-part to the SQL Statement
      SET l_tx_sql = CAST('INSERT INTO '||l_nm_schema_table||' ('||l_ls_columns||')'||CHR(10)||l_tx_sql AS VARCHAR(25000));
      --
      -- Ensuring the SELECT outputs the Columns in the same order as the target Table.
      SET l_tx_sql = CAST(l_tx_sql AS VARCHAR(15000))
        ||CHR(10)||  CAST('SELECT '||l_ls_columns
        ||CHR(10)|| 'FROM src' AS VARCHAR(10000));
      --
      -- Execute SQL Statement
      CALL ${nm_database_target}logging_usp_debug (NVL(l_tx_sql,'Query Empty'), ip_is_debugging);
      CALL ${nm_database_target}generic_usp_exec_dynamic_sql ( l_id_log,
        /* ip_procedure_name   */ l_procedure_name,
        /* ip_message_text     */ l_message_text_ext,
        /* ip_dynamic_sql_text */ l_tx_sql,
        /* ip_max_retry_times  */ 3,
        /* op_status_text      */ op_status_text
      );
      --
    END IF;
    --
  END;
  --
  -- End Logging
  CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
  --
END;
