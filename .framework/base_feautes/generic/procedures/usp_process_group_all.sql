REPLACE PROCEDURE ${nm_database_target}generic_usp_process_group_all (
  --
  -- Input Parameters
  IN ip_is_debugging INT
  --
  /* Example
  CALL ${nm_database_target}generic_usp_process_group_all(1);
  */
)
BEGIN
  --
  -- Local Variables for Logging
  DECLARE l_procedure_name   VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_process_group_all';
  DECLARE l_message_text     VARCHAR(999);
  DECLARE l_message_text_ext VARCHAR(999);
  DECLARE l_tx_error         VARCHAR(2000);
  DECLARE l_id_log           CHAR(64);
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
    -- Initialize local Variables
    SET l_message_text = 'Loading all "Process Groups" in sequencial order';
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, NULL, 1, l_id_log);
    --
    SET l_message_text_ext = l_message_text || ' - Step 1: Extract Process Groups';
    CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
    --
    FOR pgp AS (
      SELECT DISTINCT pgp.ni_process_group
      FROM ${nm_database_target}metadata_tbl_process_group as pgp
      ORDER BY pgp.ni_process_group ASC
    ) DO
      --
      SET l_message_text_ext = l_message_text || ' - Step 2: Execution of Process Groups One # "' || CAST(pgp.ni_process_group AS VARCHAR(2)) ||'"';
      CALL ${nm_database_target}logging_usp_debug (l_message_text_ext, ip_is_debugging);
      --
      -- Call the generic process group one
      CALL ${nm_database_target}generic_usp_process_group_one (
        /* ip_ni_process_group */ pgp.ni_process_group,
        /* ip_is_debugging     */ ip_is_debugging,
        /* op_status_text      */ l_status_text
      );
      --
      -- Check if load was successful
      IF NVL(l_status_text, '') <> 'Success' THEN
        --
        SET l_tx_error = 'Load failed with error: ' || l_status_text;
        CALL ${nm_database_target}logging_usp_debug (l_tx_error, ip_is_debugging);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = l_tx_error;
        --
      END IF;
      --
    END FOR;
    --
    -- No Errors occured
    CALL ${nm_database_target}logging_usp_debug ('Load completed successfully', ip_is_debugging);
    CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
    --
  END;
  --
END;