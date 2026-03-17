REPLACE PROCEDURE ${nm_database_target}generic_usp_process_group_one (
  --
  -- Input Parameters
  IN ip_ni_process_group INT,
  IN ip_is_debugging     INT,
  --
  -- Output Parameters
  OUT op_status_text VARCHAR(999)
  --
)
BEGIN
  --
  -- Local Variables for Logging
  DECLARE l_procedure_name   VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_process_group_one';
  DECLARE l_message_text     VARCHAR(999);
  DECLARE l_message_text_ext VARCHAR(999);
  DECLARE l_tx_error         VARCHAR(2000);
  DECLARE l_id_log           CHAR(64);
  DECLARE l_status_text      VARCHAR(999);
  DECLARE l_view_exists      INT DEFAULT 0;
  DECLARE l_table_exists     INT DEFAULT 0;
  DECLARE l_is_ended_in_error INT;
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
    -- Initialize local Variables
    SET l_message_text = 'Loading one "Process Groups" and all the "Dataset in it, in sequencial order';
    SET l_is_ended_in_error = 0; /* This to track if one or more of dataset processing ended in error. */
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, NULL, 1, l_id_log);
    --
    SET l_message_text_ext = l_message_text || ' - Step 1: Extract Datasets (Schema and Table) for "process Group" #' || CAST(ip_ni_process_group AS VARCHAR(2)) ;
    CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
    --
    FOR pgp AS (
      SELECT pgp.nm_schema, pgp.nm_table
      FROM ${nm_database_target}metadata_tbl_process_group as pgp
      WHERE pgp.ni_process_group = ip_ni_process_group
      AND   pgp.nm_schema NOT IN ('logging', 'generic', 'metadata')
      ORDER BY pgp.nm_schema ASC, pgp.nm_table ASC 
    ) DO
      --
      SET l_message_text_ext = l_message_text || ' - Step 2: Loading dataset "' || pgp.nm_schema || '"."' || pgp.nm_table || '"';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Call the generic load procedure
      CALL ${nm_database_target}generic_usp_hist_view_into_table (
        /* ip_nm_schema          */ pgp.nm_schema,
        /* ip_nm_table           */ pgp.nm_table,
        /* ip_tx_delete_criteria */ '1=1', -- Delete all existing data for development testing
        /* ip_is_debugging       */ ip_is_debugging,
        /* op_status_text        */ l_status_text
      );
      --
      -- Check if load was successful
      IF NVL(l_status_text, '') <> 'Success' THEN
        --
        SET l_tx_error = 'Load failed with error: ' || l_status_text;
        CALL ${nm_database_target}logging_usp_debug (l_tx_error, ip_is_debugging);
        SET l_is_ended_in_error = 1;
        
        --
      END IF;
      --
    END FOR;
    --
    IF (l_is_ended_in_error = 1) THEN
      --
      -- Show latest Error
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = l_tx_error;
      --
    ELSE -- No Errors occured
      CALL ${nm_database_target}logging_usp_debug ('Load completed successfully', ip_is_debugging);
      CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
      SET op_status_text = 'Success';
    END IF;
    --
  END;
  --
END;