REPLACE PROCEDURE ${nm_database_target}metadata_usp_load_metadata (
  --
  -- Input Parameters
  IN ip_is_debugging INT
  --
  -- Output Parameters
  -- OUT op_not_available VARCHAR(000)
  --
  -- Example:
  /*
  CALL ${nm_database_target}metadata_usp_load_metadata(1);
  SELECT * FROM ${nm_database_target}metadata_tbl_environment;
  SELECT * FROM ${nm_database_target}metadata_tbl_table;
  SELECT * FROM ${nm_database_target}metadata_tbl_column;
  SELECT * FROM ${nm_database_target}metadata_tbl_referenced;
  SELECT * FROM ${nm_database_target}metadata_tbl_process_group;
  */
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_environment_code VARCHAR(32);
  DECLARE l_procedure_name   VARCHAR(128) DEFAULT '${nm_database_target}metadata_usp_load_metadata';
  DECLARE l_message_text     VARCHAR(999); --> These are used from the input, for this the constructed message form the calling procedure will provide context.
  DECLARE l_op_status_text   VARCHAR(999);
  DECLARE l_tx_error         VARCHAR(2000);
  DECLARE l_id_log           CHAR(64);    
  --
  CALL ${nm_database_target}logging_usp_debug (l_procedure_name||' Started', ip_is_debugging);
  BEGIN
    --
    -- Declare Error Handler
    DECLARE exit handler for sqlexception BEGIN GET diagnostics exception 1 l_tx_error = message_text; CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);  END;
    --
    -- Initialize local Variables
    SET l_message_text = 'Load metadata for the `table`, `column` and `referenced`';
    SET l_op_status_text = '';
    --
    -- Start Logging
    CALL ${nm_database_target}logging_usp_start(NULL, l_procedure_name, l_message_text, '', 1, l_id_log);
    --
    CALL ${nm_database_target}logging_usp_debug ('Extractie van Metadata for "Environment"', ip_is_debugging);
    CALL ${nm_database_target}generic_usp_load_view_into_table (
      /* ip_nm_schema          */ 'metadata',
      /* ip_nm_table           */ 'tbl_environment',
      /* ip_tx_delete_criteria */ '1=1',
      /* ip_is_debugging       */ 1,
      /* op_status_text        */ l_op_status_text
    );
    --
    CALL ${nm_database_target}logging_usp_debug ('Extractie van Metadata for "Table"', ip_is_debugging);
    CALL ${nm_database_target}generic_usp_load_view_into_table (
      /* ip_nm_schema          */ 'metadata',
      /* ip_nm_table           */ 'tbl_table',
      /* ip_tx_delete_criteria */ '1=1',
      /* ip_is_debugging       */ 1,
      /* op_status_text        */ l_op_status_text
    );
    --
    CALL ${nm_database_target}logging_usp_debug ('Extractie van Metadata for "Column"', ip_is_debugging);
    CALL ${nm_database_target}generic_usp_load_view_into_table (
      /* ip_nm_schema          */ 'metadata',
      /* ip_nm_table           */ 'tbl_column',
      /* ip_tx_delete_criteria */ '1=1',
      /* ip_is_debugging       */ 1,
      /* op_status_text        */ l_op_status_text
    );
    --
    CALL ${nm_database_target}logging_usp_debug ('Extractie van Metadata for "Referenced"', ip_is_debugging);
    CALL ${nm_database_target}generic_usp_load_view_into_table (
      /* ip_nm_schema          */ 'metadata',
      /* ip_nm_table           */ 'tbl_referenced',
      /* ip_tx_delete_criteria */ '1=1',
      /* ip_is_debugging       */ 1,
      /* op_status_text        */ l_op_status_text
    );
    --
    CALL ${nm_database_target}logging_usp_debug ('Extractie van Metadata for "Process Group"', ip_is_debugging);
    CALL ${nm_database_target}generic_usp_load_view_into_table (
      /* ip_nm_schema          */ 'metadata',
      /* ip_nm_table           */ 'tbl_process_group',
      /* ip_tx_delete_criteria */ '1=1',
      /* ip_is_debugging       */ 1,
      /* op_status_text        */ l_op_status_text
    );    
    --
  END;
  --
  -- End Logging
  CALL ${nm_database_target}logging_usp_finish (l_id_log, NULL, 1);
  --
END;