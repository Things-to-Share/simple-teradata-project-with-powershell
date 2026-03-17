REPLACE PROCEDURE ${nm_database_target}generic_usp_hist_view_into_table (
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
  /* Example:
DELETE FROM ${nm_database_target}logging_tbl_debug;
DELETE FROM ${nm_database_target}logging_tbl_log;
CALL ${nm_database_target}fdwh2_dwa_control_usp_load_dwa_control ();
SELECT * FROM ${nm_database_target}logging_tbl_debug order by id desc;
SELECT * FROM ${nm_database_target}logging_tbl_log order by LOG_START desc;
SELECT * FROM ${nm_database_target}fdwh2_dwa_control_tbl_model_snapshot;
   */
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_procedure_name     VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_hist_view_into_table';
  DECLARE l_message_text       VARCHAR(999); --> These are used from the input, for this the constructed message form the calling procedure will provide context.
  DECLARE l_message_text_ext   VARCHAR(999);
  DECLARE l_op_status_text     VARCHAR(999);
  DECLARE l_tx_error           VARCHAR(2000);
  DECLARE l_id_log             CHAR(64);
  DECLARE l_id_log_h           CHAR(64);
  DECLARE l_tx_sql             VARCHAR(32000); --> the SQL Statement of the calling procedure will be executed.
  DECLARE l_ls_columns         VARCHAR(25000);
  DECLARE l_nm_database        VARCHAR(128) DEFAULT '${nm_database_target}';
  DECLARE l_nm_schema_table    VARCHAR(128);
  DECLARE l_nm_schema_view     VARCHAR(128);
  DECLARE l_nm_schema_tsa      VARCHAR(128);
  DECLARE l_ls_meta_attributes VARCHAR(128) DEFAULT 'meta_dt_tech_valid_start, meta_dt_tech_valid_ended, meta_is_actual, meta_ch_rh, meta_ch_bk, meta_ni_rn, meta_ch_pk';
  --
  -- Helper in String handling
  DECLARE l_ni_position_last_select INT;
  DECLARE l_ni_position_as          INT;
  --
  -- Extraction of Technical Valid Start datetime
  DECLARE l_meta_dt_tech_valid_start TIMESTAMP;
  DECLARE l_cur CURSOR FOR stmt1;
  --
  CALL ${nm_database_target}logging_usp_debug (l_procedure_name || ' Started', ip_is_debugging);
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
    SET l_message_text = 'Historize data from view `'||l_nm_schema_view||'` into table `'||l_nm_schema_table||'`';
    SET op_status_text = '';
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, '', 1, l_id_log);
    --
    -- Initialize "Temporal Staging Table"
    SET l_nm_schema_tsa   = l_nm_database||'tmp_'||l_id_log;    
    --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 0: Build List Columns';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      SET l_ls_columns = '';
      FOR col AS (
        SELECT c.ColumnName FROM DBC.ColumnsV  AS c
        WHERE c.DataBaseName || '.'  || c.TableName = l_nm_schema_table
        AND c.ColumnName NOT LIKE 'meta%'
        ORDER BY c.ColumnId ASC
      ) DO
        SET l_ls_columns = CAST(l_ls_columns || CASE WHEN l_ls_columns = '' THEN '' ELSE ', ' END || col.ColumnName as VARCHAR(25000));
      END FOR;
      CALL ${nm_database_target}logging_usp_debug ('l_ls_columns: '||l_ls_columns, ip_is_debugging);
    END IF;
    --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 1: Create Temporal Staging Table';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      -- 
      -- Build SQL Statment
      SET l_tx_sql = (
        SELECT TRIM(t.RequestText) AS tx_sql
        FROM DBC.TablesV AS t
        WHERE t.TableKind IN ('V')
        AND   t.DataBaseName || '.' || t.TableName = l_nm_schema_view
      );
      CALL ${nm_database_target}logging_usp_debug ('l_tx_sql : ' || l_tx_sql, ip_is_debugging);
      --
      -- Remover the "REPLACE VIEW ...."-part.
      SET l_ni_position_as = POSITION(' AS ' IN UPPER(l_tx_sql)) + 4;
      CALL ${nm_database_target}logging_usp_debug ('l_ni_position_as : ' ||CAST(l_ni_position_as AS varchar(4)), ip_is_debugging);
      SET l_tx_sql = SUBSTR(l_tx_sql, l_ni_position_as, LENGTH(l_tx_sql)-l_ni_position_as + 1);
      IF (RIGHT(l_tx_sql,1)=';') THEN
        SET l_tx_sql = SUBSTR(l_tx_sql, 1, LENGTH(l_tx_sql)-1);
      END IF;
      CALL ${nm_database_target}logging_usp_debug ('l_tx_sql : ' || l_tx_sql, ip_is_debugging);
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
        --
      END IF;
      --
      -- Ensuring the SELECT outputs the Columns in the same order as the target Table.
      SET l_tx_sql = CAST(l_tx_sql AS VARCHAR(15000))
        ||CHR(10)||  CAST('SELECT '||l_ls_columns
        ||CHR(10)||       '     , '||l_ls_meta_attributes
        ||CHR(10)||       'FROM src' AS VARCHAR(10000));      
      --
      -- Execute SQL Statement 
      CALL ${nm_database_target}logging_usp_debug (l_tx_sql, ip_is_debugging);
      CALL ${nm_database_target}generic_usp_create_table ( l_id_log,
        /* ip_schema_name      */ NULL,
        /* ip_table_name       */ l_nm_schema_tsa,
        /* ip_index_list       */ 'meta_ch_pk',
        /* ip_tx_query         */ l_tx_sql,
        /* is_volatile         */ 0,
        /* ip_is_logging_on    */ 1,
        /* op_status_text      */ l_op_status_text
      );
      CALL ${nm_database_target}logging_usp_debug ('SELECT * FROM ' || l_nm_schema_tsa, ip_is_debugging);    
      --
    END IF;
    --
    IF (1=1) THEN  SET l_message_text_ext = l_message_text || 'Step 2: Extractie of "max" meta_dt_tech_valid_start';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      SET l_tx_sql = 'SELECT COALESCE(MAX(meta_dt_tech_valid_start),CURRENT_TIMESTAMP) AS dt FROM ' || l_nm_schema_tsa || ' AS tsa';
      CALL ${nm_database_target}logging_usp_debug (l_tx_sql, ip_is_debugging);
      PREPARE stmt1 FROM l_tx_sql; OPEN l_cur;
      for_loop: LOOP
        FETCH l_cur INTO l_meta_dt_tech_valid_start; IF SQLCODE <> 0 THEN LEAVE for_loop; END IF;      
      END LOOP for_loop;
      CLOSE l_cur; DEALLOCATE PREPARE stmt1;   
    END IF;
    --
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 3: End Records (Where Target BK does not exist in Source)';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Build SQL Statement
      SET l_tx_sql = 'UPDATE ' || l_nm_schema_table || ' AS tgt';
      SET l_tx_sql = l_tx_sql || CHR(10) || 'SET meta_dt_tech_valid_ended = CAST(''' || CAST(l_meta_dt_tech_valid_start AS VARCHAR(32)) || ''' AS TIMESTAMP)';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  , meta_is_actual = 0';
      SET l_tx_sql = l_tx_sql || CHR(10) || 'WHERE meta_is_actual = 1';
      SET l_tx_sql = l_tx_sql || CHR(10) || 'AND NOT EXISTS (';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  SELECT 1 is_found ';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  FROM ' || l_nm_schema_tsa || ' AS src';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  WHERE src.meta_ch_bk = tgt.meta_ch_bk';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  AND   src.meta_ch_rh = tgt.meta_ch_rh';
      SET l_tx_sql = l_tx_sql || CHR(10) || ')';
      --
      -- Execute SQL Statement
      CALL ${nm_database_target}logging_usp_debug (l_tx_sql, ip_is_debugging);
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
    IF (1=1) THEN SET l_message_text_ext = l_message_text || 'Step 2: Add records (where Target does not exists for BK from  Source)';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Build SQL Statment
      SET l_tx_sql = 'INSERT INTO ' || l_nm_schema_table || ' (';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  ' || l_ls_columns || ',';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  ' || l_ls_meta_attributes;
      SET l_tx_sql = l_tx_sql || CHR(10) || ')';
      SET l_tx_sql = l_tx_sql || CHR(10) || 'SELECT';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  ' || l_ls_columns || ',';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  ' || l_ls_meta_attributes;
      SET l_tx_sql = l_tx_sql || CHR(10) || 'FROM ' || l_nm_schema_tsa || ' AS src';
      SET l_tx_sql = l_tx_sql || CHR(10) || 'WHERE NOT EXISTS (';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  SELECT 1 AS is_found';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  FROM ' || l_nm_schema_table ||' AS tgt';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  WHERE tgt.meta_is_actual = 1';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  AND tgt.meta_ch_bk = src.meta_ch_bk';
      SET l_tx_sql = l_tx_sql || CHR(10) || '  AND tgt.meta_ch_rh = src.meta_ch_rh';
      SET l_tx_sql = l_tx_sql || CHR(10) || ')';
      --
      -- Execute SQL Statement
      CALL ${nm_database_target}logging_usp_debug (l_tx_sql, ip_is_debugging);
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
    -- Clean up of temp table
    CALL  ${nm_database_target}generic_usp_drop_table (
      /* ip_id_log_parent    */ l_id_log,
      /* ip_schema_name      */ NULL,
      /* ip_table_name       */ l_nm_schema_tsa,
      /* op_status_text      */ l_op_status_text
    );
    --
  END;
  --
  -- End Logging
  CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
  --
END;
