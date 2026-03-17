REPLACE PROCEDURE ${nm_database_target}generic_usp_create_table (
  --
  -- Input Parameters
  IN ip_id_log_parent    CHAR(64),
  IN ip_schema_name      VARCHAR(128),  --> is NULL if is_volatile = 1, or will be ignored
  IN ip_table_name       VARCHAR(128),
  IN ip_index_list       VARCHAR(999),
  IN ip_tx_query         VARCHAR(31390), -- +/- 110 characteres for the "create (volatile) table"-wrapper + 999 character
  IN is_volatile         INT,
  IN ip_is_logging_on    INT,
  --
  -- Output Parameters
  OUT op_status_text     VARCHAR(999)
  --
  -- Example 1: Create Volatile Table
  -- CALL ${nm_database_target}generic_usp_create_table ('A', NULL, 'test_volatile_table', NULL, 'SELECT 1 AS test_value', 1, 1);
  --
  -- Example 1: Create Volatile Table
  -- CALL ${nm_database_target}generic_usp_create_table ('A', 't_l2_func_test', 'test_table', 'test_value', 'SELECT 1 AS test_value', 1, 1);
  --
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_procedure_name VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_create_table';
  DECLARE l_message_text   VARCHAR(999);
  DECLARE l_op_status_text VARCHAR(999);
  DECLARE l_ni_affected    INT;
  DECLARE l_tx_error       VARCHAR(2000);
  DECLARE l_id_log         CHAR(64);    
  DECLARE l_id_exc         CHAR(64);    
  DECLARE l_tx_sql         VARCHAR(32000);
  DECLARE l_stap           VARCHAR(2);
  --
  -- Local Variables for buildign SQL Statement
  DECLARE t VARCHAR(32000); -- SQL Stement Text
  DECLARE n VARCHAR(1);     -- New Line
  DECLARE e VARCHAR(1);     -- Empty String
  DECLARE sq VARCHAR(1);    -- single Qout
  DECLARE dq VARCHAR(2);    -- double Qout
  
  --
  -- Local Variable for detecting table already exists.
  DECLARE l_ni_ignore INT;
  --
  CALL ${nm_database_target}logging_usp_debug (l_procedure_name || ' Started', ip_is_logging_on);
  --
  -- Execute SQL Statements
  BEGIN
    DECLARE exit handler for sqlexception BEGIN GET diagnostics exception 1 l_tx_error = message_text;
      CALL ${nm_database_target}logging_usp_start (ip_id_log_parent, l_procedure_name, l_message_text, l_tx_sql, 1, l_id_log);
      CALL ${nm_database_target}logging_usp_failed (l_id_log, ip_table_name ||' -> Error in stap '||l_stap|| ' -> length SQL : '||CAST( LENGTH(t) AS VARCHAR(10))||' -> Error Text: "' || l_tx_error||'"', 1); SET op_status_text = 'Error: '||l_tx_error;
    END;
    --
    -- Start Logging
    SET l_message_text = CONCAT('Call to Create Table : "', ip_table_name, '"');
    SET l_tx_sql =  CAST('CALL '||l_procedure_name || ' ('
                || CASE WHEN      ip_schema_name      IS NULL THEN 'NULL' ELSE ''''||ip_schema_name||'''' END || ', '
                || ''''    ||     ip_table_name       ||''', ' 
                || CASE WHEN      ip_index_list       IS NULL THEN 'NULL' ELSE ''''||ip_index_list||'''' END || ', '
                || ''''|| CAST(ip_tx_query            AS VARCHAR(28000)) || ''', '
                || CAST(          is_volatile         AS VARCHAR(1)) ||', '
                || CAST(          ip_is_logging_on    AS VARCHAR(1)) || ');' AS VARCHAR(32000));
    --
    -- Initialized Output Parameter
    SET op_status_text = '';
    --
    -- Buils SQL Statement for creating table
    BEGIN
      --
      -- Initializing Variables
      SET n = chr(10);
      SET e = '';
      set sq = '''';
      set dq = '''''';
      --
      -- Initial SQL Stement for creating Temp table.
      IF (is_volatile = 1) THEN
          SET l_stap = '1'; SET t=CAST(TRIM(e||e||'CREATE MULTISET VOLATILE TABLE ' || ip_table_name || ', NO LOG AS (') AS VARCHAR(28000));
          SET l_stap = '2'; SET t=CAST(TRIM(t||n||ip_tx_query) AS VARCHAR(28000));
          SET l_stap = '3'; SET t=CAST(TRIM(t||n||') WITH DATA') AS VARCHAR(28000));
          SET l_stap = '4'; SET t=CAST(TRIM(t||e||CASE WHEN LENGTH(NVL(ip_index_list, '')) > 0 
                                                       THEN ' PRIMARY INDEX (' || ip_index_list || ')' 
                                                       ELSE ' NO PRIMARY INDEX'
                                                  END) AS VARCHAR(28000));
          SET l_stap = '5'; SET t=CAST(CAST(t AS VARCHAR(28000))||' ON COMMIT PRESERVE ROWS' AS VARCHAR(28000));
      ELSE 
          SET l_stap = '1'; SET t=CAST(TRIM(e||e||'CREATE MULTISET TABLE ' || ip_table_name || ' AS (') AS VARCHAR(28000));
          SET l_stap = '2'; SET t=CAST(TRIM(t||n||ip_tx_query) AS VARCHAR(28000));
          SET l_stap = '3'; SET t=CAST(TRIM(t||n||') WITH DATA') AS VARCHAR(28000));
          SET l_stap = '4'; SET t=CAST(TRIM(t||e||CASE WHEN LENGTH(NVL(ip_index_list, '')) > 0 
                                                       THEN ' PRIMARY INDEX (' || ip_index_list || ')' 
                                                       ELSE ' ' 
                                                  END) AS VARCHAR(28000));
      END IF;
      --
      -- Replace Placeholders
      SET l_stap = '7';  SET t=CAST(CAST(t AS VARCHAR(28000)) ||';' AS VARCHAR(28000)); 
      SET l_stap = '8'; SET l_tx_sql = CAST(t AS VARCHAR(28000));
      --
      -- initialize affected rows.
      SET l_ni_affected = 0;
      --
    END;    
    --
    -- Drop table if exists, if not exists "ignore" error.
    CALL ${nm_database_target}generic_usp_drop_table(ip_id_log_parent, ip_schema_name, ip_table_name, l_op_status_text);
    IF (l_op_status_text <> 'Success') THEN
      SET op_status_text = l_op_status_text;
    ELSE
      --
      -- Execute SQL Statement for create table
      CALL DBC.SysExecSQL(l_tx_sql); 
      --
      -- Update Effected rows.
      SET l_tx_sql = 'UPDATE t.${nm_database_target}logging_tbl_log SET affected = (SELECT COUNT(*) FROM '||ip_table_name||' ) WHERE id_log = ''' ||l_id_exc||''';';
      CALL DBC.SysExecSQL(l_tx_sql); 
      --
      -- All Done
      SET op_status_text = 'Success';
      --
    END IF;
    --
  END ;
  --
END;
