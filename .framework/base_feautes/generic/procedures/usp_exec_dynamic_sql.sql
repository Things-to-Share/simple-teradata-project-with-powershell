REPLACE PROCEDURE ${nm_database_target}generic_usp_exec_dynamic_sql (
  --
  -- Input Parameters
  IN ip_id_log_parent    CHAR(64),
  IN ip_procedure_name   VARCHAR(128),
  IN ip_message_text     VARCHAR(999),
  IN ip_dynamic_sql_text VARCHAR(32000),
  IN ip_max_retry_times  INT,
  --
  -- Output Parameters
  OUT op_status_text     VARCHAR(999)
  --
)
BEGIN
  --
  -- Local Varaible for "Loggin" of "Attribute"-regression.
  DECLARE l_procedure_name VARCHAR(128) DEFAULT '${nm_database_target}generic_usp_exec_dynamic_sql';
  DECLARE l_ni_affected    INT;
  DECLARE l_tx_error       VARCHAR(2000);
  DECLARE l_id_log         CHAR(64);    
  DECLARE l_id_err         CHAR(64);    
  DECLARE l_tx_sql         VARCHAR(32000); --> the SQL Statement of the calling procedure will be executed.
  DECLARE l_ni_try_times   INT;
  DECLARE l_cd_error       INT; -- 0 => No Errors, 1 => Temporal Issue, wait 1 sec and try again, 2 => max try time exided, 3 => Critical Error.
  --
  -- Drop table if exists
  BEGIN
    --
    -- Initialize "# Try Times" and "Is Failed".
    SET l_ni_try_times = 0;
    SET l_cd_error     = 0;
    --
    -- Convert single and double quots
    SET l_tx_sql = ip_dynamic_sql_text;
    --
    -- Execute "Dymanic SQL"-statment max "ip_max_retry_times"
    WHILE (l_ni_try_times < ip_max_retry_times AND l_cd_error <= 1) DO 
      BEGIN
        --
        -- Declare Error Handleer
        DECLARE exit handler for sqlexception BEGIN
          --
          -- Extract Error Messageform diagnostics of the Exception
          GET diagnostics exception 1 l_tx_error = message_text;
          --
          CALL ${nm_database_target}logging_usp_start (ip_id_log_parent, l_procedure_name, ip_message_text, l_tx_sql, 1, l_id_log);
          --
          -- Add "# Times Tried" to Error Message
          SET l_tx_error = l_tx_error || '; # Times Tried: ' || TRIM(CAST(l_ni_try_times AS VARCHAR(4)));
          -- 
          -- Determine "Error Code" 
          SET l_cd_error = CASE 
            WHEN (l_ni_try_times >= ip_max_retry_times)      THEN 2 
            WHEN (l_tx_error LIKE '%Deadlock%')              THEN 1
            WHEN (l_tx_error LIKE 'No more spool space in%') THEN 1
            ELSE 3 --> Other error then Dedlock or No more spool space in <username>
          END;
          --
          IF (l_cd_error = 1) THEN --> for Deadlocks and Spool Space error do retry
            -- maken log record
            CALL ${nm_database_target}logging_usp_start (ip_id_log_parent, l_procedure_name, 'Handled Error: ' || l_tx_error, l_tx_sql, 1, l_id_err);
            CALL ${nm_database_target}generic_usp_wait(1);
            CALL ${nm_database_target}logging_usp_finish (l_id_err, 0, 1);
          END IF;
          --
          IF (l_cd_error IN (2, 3)) THEN --> Max Times Try was exceded or other error occured'
            CALL ${nm_database_target}logging_usp_failed (l_id_log, l_tx_error, 1); 
            SET op_status_text = 'Error: '||l_tx_error;
            SET l_ni_try_times = (ip_max_retry_times + 1);
          END IF;
          --
        END; -- exit handler
        --
        -- Initalize Error Code
        SET l_cd_error = 0;
        --
        -- Add 1 to times tried
        SET l_ni_try_times = l_ni_try_times + 1;
        --
        -- Execute "Dynamic SQL"-statement
        CALL DBC.SysExecSQL(l_tx_sql);
        SET l_ni_affected = ACTIVITY_COUNT;
        --
        -- No Error occure then set "l_ni_try_times" to equal "ip_max_retry_times" to break out of the while loop
        SET l_ni_try_times = ip_max_retry_times;
        --
      END; 
    END WHILE;
    --
    -- If "Dynamic SQL"-statement was executed Successfull, finish log record otherwise log reocrd was already finished with error.
    IF (l_cd_error = 0) THEN
      CALL ${nm_database_target}logging_usp_finish (l_id_log, l_ni_affected, 1);
      SET op_status_text = 'Success';
    END IF;
    --
  END;
  --
END;
