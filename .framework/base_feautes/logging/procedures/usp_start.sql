REPLACE PROCEDURE ${nm_database_target}logging_usp_start (
  -- Input Parameters
  IN ip_id_log_parent  CHAR(64),
  IN ip_procedure_name   VARCHAR(128),
  IN ip_message_text   VARCHAR(999),
  IN ip_dynamic_sql_text VARCHAR(32000),
  IN ip_is_logging_on  INT,
  -- Output Parameters
  OUT op_id_log CHAR(64)
)
BEGIN
  -- Local Variables
  DECLARE l_log_start TIMESTAMP;
  DECLARE l_id_log  CHAR(64);
  DECLARE l_is_failed INT DEFAULT 0;
  DECLARE l_retry_count INT DEFAULT 0;
  --
  -- Set Local Variables
  SET l_log_start = CURRENT_TIMESTAMP;
  SET l_id_log = CAST(SYSUDTLIB.HASH_SHA256(CONCAT(
                 '|', ip_procedure_name,
                 '|', ip_message_text,
                 '|', CAST(l_log_start AS VARCHAR(32)),
                 '|')) AS CHAR(64));
  --
  WHILE ((SELECT COUNT(*) FROM ${nm_database_target}logging_tbl_log WHERE id_log = l_id_log) = 1) DO
    SET l_log_start = CURRENT_TIMESTAMP;
    SET l_id_log = CAST(SYSUDTLIB.HASH_SHA256(CONCAT(
                   '|', ip_procedure_name,
                   '|', ip_message_text,
                   '|', CAST(l_log_start AS VARCHAR(32)),
                   '|')) AS CHAR(64));
  END WHILE;
  --
  -- Retry loop for INSERT
  IF (ip_is_logging_on = 1) THEN
    WHILE (l_is_failed = 0 AND l_retry_count < 3) DO
      BEGIN
        DECLARE exit handler for sqlexception BEGIN SET l_is_failed = 1; END;
        
        INSERT INTO ${nm_database_target}logging_tbl_log (
          id_log, id_log_parent, procedure_code, message_text, dynamic_sql_text, log_start)
        VALUES (l_id_log, NVL(ip_id_log_parent, l_id_log), ip_procedure_name, ip_message_text, ip_dynamic_sql_text, l_log_start);
        
        -- If we reach here, insert was successful
        SET l_retry_count = 3; -- Exit the loop
      END;
      
      SET l_retry_count = l_retry_count + 1;
    END WHILE;
  END IF;
  --
  -- Set Return Parameter
  SET op_id_log = l_id_log;
END;