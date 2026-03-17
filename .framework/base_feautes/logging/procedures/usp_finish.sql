REPLACE PROCEDURE ${nm_database_target}logging_usp_finish (
    --
    -- Input Parameters
    IN ip_id_log        CHAR(64),
    IN ip_affected      INT,
    IN ip_is_logging_on INT
   --
)
BEGIN
    --
    IF (ip_is_logging_on = 1) THEN
        --
        UPDATE ${nm_database_target}logging_tbl_log 
        SET log_ended   = CURRENT_TIMESTAMP
          , affected    = ip_affected
        WHERE id_log = ip_id_log;
        --
    END IF;
    --
END;