REPLACE PROCEDURE ${nm_database_target}generic_usp_hist_one_dataset (
  --
  -- Input Parameters
  IN ip_nm_schema    VARCHAR(128),
  IN ip_nm_table     VARCHAR(128),
  IN ip_is_debugging INT
  --
  /*
  --
  -- Example 1:
  DELETE FROM ${nm_database_target}logging_tbl_debug;
  CALL ${nm_database_target}generic_usp_hist_one_dataset( 'fdwh2_dwa_control', 'model_snapshot', 1 );
  SELECT * FROM ${nm_database_target}logging_tbl_debug ORDER BY id ASC;
  SELECT * FROM ${nm_database_target}fdwh2_dwa_control_tbl_model_snapshot;
  --
  -- Example 2:
  DELETE FROM ${nm_database_target}logging_tbl_debug;
  CALL ${nm_database_target}generic_usp_hist_one_dataset( 'fdwh2_spal_mbdt', 'counterparties', 1 );
  SELECT * FROM ${nm_database_target}logging_tbl_debug ORDER BY id ASC;
  SELECT * FROM ${nm_database_target}logging_tbl_log ORDER BY log_start DESC;
  SELECT * FROM ${nm_database_target}fdwh2_spal_mbdt_tbl_counterparties;
-- */
)
BEGIN
  --
  -- Local Variables for Logging
  DECLARE l_procedure_name   VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_load_one_dataset';
  DECLARE l_message_text     VARCHAR(999);
  DECLARE l_message_text_ext VARCHAR(999);
  DECLARE l_tx_error         VARCHAR(2000);
  DECLARE l_id_log           CHAR(64);
  DECLARE l_nm_database      VARCHAR(128) DEFAULT '${nm_database_target}';
  DECLARE l_nm_schema_table  VARCHAR(128);
  DECLARE l_nm_schema_view   VARCHAR(128);
  DECLARE l_status_text      VARCHAR(999);
  DECLARE l_view_exists      INT DEFAULT 0;
  DECLARE l_table_exists     INT DEFAULT 0;
  --
  CALL ${nm_database_target}logging_usp_debug (l_procedure_name||' Started', ip_is_debugging);
  --
  BEGIN
    --
    -- Declare Error Handler
    DECLARE exit handler for sqlexception BEGIN GET diagnostics exception 1 l_tx_error = message_text; 
      CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);
    END;
    --
    -- Set Schema / Table names
    SET l_nm_schema_table = l_nm_database || ip_nm_schema || '_' || ip_nm_table;
    SET l_nm_schema_view  = OREPLACE(l_nm_schema_table, '_tbl_', '_viw_');
    --
    -- Initialize local Variables
    SET l_message_text = 'Load single dataset for development testing: '||l_nm_schema_table;
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, NULL, 1, l_id_log);
    --
    SET l_message_text_ext = l_message_text || ' - Step 1: Validate View Exists';
    CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
    --
    -- Check if view exists
    SELECT COUNT(*) INTO l_view_exists
    FROM DBC.TablesV AS t
    WHERE t.TableKind = 'V'
    AND t.DataBaseName || '.' || t.TableName = l_nm_schema_view;
    --
    IF l_view_exists = 0 THEN
      SET l_tx_error = 'View does not exist: ' || l_nm_schema_view;
      CALL ${nm_database_target}logging_usp_debug ('ERROR: ' || l_tx_error, ip_is_debugging);
      CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);
    ELSE
      CALL ${nm_database_target}logging_usp_debug ('View exists: ' || l_nm_schema_view, ip_is_debugging);
      --
      SET l_message_text_ext = l_message_text || ' - Step 2: Validate Table Exists';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Check if table exists
      SELECT COUNT(*) INTO l_table_exists
      FROM DBC.TablesV AS t
      WHERE t.TableKind = 'T'
      AND t.DataBaseName || '.' || t.TableName = l_nm_schema_table;
      --
      IF l_table_exists = 0 THEN
        SET l_tx_error = 'Table does not exist: ' || l_nm_schema_table;
        CALL ${nm_database_target}logging_usp_debug ('ERROR: ' || l_tx_error, ip_is_debugging);
        CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);
      ELSE
        CALL ${nm_database_target}logging_usp_debug ('Table exists: ' || l_nm_schema_table, ip_is_debugging);
        --
        SET l_message_text_ext = l_message_text || ' - Step 3: Load Data using generic_usp_load_view_into_table';
        CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
        --
        -- Call the generic load procedure
        CALL ${nm_database_target}generic_usp_hist_view_into_table (
          /* ip_nm_schema          */ ip_nm_schema,
          /* ip_nm_table           */ ip_nm_table,
          /* ip_tx_delete_criteria */ '1=1', -- Delete all existing data for development testing
          /* ip_is_debugging       */ ip_is_debugging,
          /* op_status_text        */ l_status_text
        );
        --
        -- Check if load was successful
        IF NVL(l_status_text, '') <> '' THEN
          CALL ${nm_database_target}logging_usp_debug ('Load failed with error: ' || l_status_text, ip_is_debugging);
          CALL ${nm_database_target}logging_usp_failed (l_id_log, l_status_text, 1);
        ELSE
          CALL ${nm_database_target}logging_usp_debug ('Load completed successfully', ip_is_debugging);
          CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
        END IF;
        --
      END IF;
      --
    END IF;
    --
  END;
  --
END;