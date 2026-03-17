REPLACE PROCEDURE ${nm_database_target}generic_usp_drop_table (
  --
  -- Input Parameters
  IN ip_id_log_parent    CHAR(64),
  IN ip_schema_name      VARCHAR(128), --> This is in Teradata Databasename
  IN ip_table_name       VARCHAR(128),
  --
  -- Output Parameters
  OUT op_status_text     VARCHAR(999)
  --
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_procedure_name VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_drop_table';
  DECLARE l_expected_text  VARCHAR(2000);
  DECLARE l_message_text   VARCHAR(999);
  DECLARE l_tx_error       VARCHAR(2000);
  DECLARE l_tx_sql         VARCHAR(32000);
  DECLARE l_id_log         CHAR(64);    
  --
  -- Drop table if exists
  BEGIN
    DECLARE exit handler for sqlexception
    BEGIN -- Logging Error only if error message is NOT like "... does not exists." othersie finish logging as successfull.
        GET diagnostics exception 1 l_tx_error = message_text;
        SET l_expected_text = 'Object ''' || CASE WHEN ip_schema_name IS NULL THEN '' ELSE ip_schema_name || '.' END || ip_table_name  || ''' does not exi';
        IF (SUBSTR(l_tx_error,1,LENGTH(l_expected_text)) <> l_expected_text) THEN
          CALL ${nm_database_target}logging_usp_start (ip_id_log_parent, l_procedure_name, l_message_text, l_tx_sql, 1, l_id_log); 
          CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1);
          SET op_status_text = 'Error: '||l_tx_error;
        END IF;
    END;  
    --
    -- Build SQL Statement for dropping table, if no schema/database is provide this is left out.
    SET l_tx_sql = 'DROP TABLE ' || CASE WHEN ip_schema_name IS NULL THEN '' ELSE ip_schema_name || '.' END || ip_table_name ||';';
    --
    -- EXecute SQL Statement
    SET l_message_text = CONCAT('Dropping Schema: "',CASE WHEN ip_schema_name IS NULL THEN '' ELSE ip_schema_name || '.' END || ip_table_name, '"');
    CALL DBC.SysExecSQL(l_tx_sql);
    SET op_status_text = 'Success';
    --
  END;
  --
END;
