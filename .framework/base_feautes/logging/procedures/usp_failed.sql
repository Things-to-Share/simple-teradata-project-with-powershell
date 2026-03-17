REPLACE PROCEDURE ${nm_database_target}logging_usp_failed (
    --
    -- Input Parameters
    IN ip_id_log        CHAR(64),
    IN ip_error_text    VARCHAR(2000),
    IN ip_is_logging_on INT
    --
)
BEGIN
    --
    IF (ip_is_logging_on = 1) THEN
        --
        UPDATE ${nm_database_target}logging_tbl_log 
        SET log_ended  = CURRENT_TIMESTAMP,
            error_text = ip_error_text
        WHERE id_log = ip_id_log;
        --
        -- End All related still open "log"-records with the same error and referecnce to the "log"-record which actually failed.
        UPDATE ${nm_database_target}logging_tbl_log SET 
            log_ended  = CURRENT_TIMESTAMP,
            error_text = 'id_log `' || ip_id_log || '` Failed with error: ' || ip_error_text
        WHERE log_ended IS NULL AND id_log_parent = (
            SELECT id_log_parent 
            FROM ${nm_database_target}logging_tbl_log 
            WHERE id_log = ip_id_log
        );
        --
    END IF;
    --
END;