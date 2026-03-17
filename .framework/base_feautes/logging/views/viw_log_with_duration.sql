REPLACE VIEW ${nm_database_target}logging_viw_log_with_duration AS WITH
cte AS (
     SELECT l.id_log                                 AS id_log
          , l.id_log_parent                          AS id_log_parent
          , '${cd_environment}'                      AS environment_code
          , l.procedure_code                         AS procedure_code
          , l.message_text                           AS message_text
          , CASE --                                  AS procedure_ended_in_error
              WHEN l.error_text IS NOT NULL THEN 1 ELSE 0 
            END AS procedure_ended_in_error
          , l.affected                               AS affected
          , l.log_start                              AS log_start
          , COALESCE(l.log_ended, CURRENT_TIMESTAMP) AS log_ended
          , CASE WHEN l.log_ended IS NULL THEN 1 ELSE 0 END is_running
          --
          -- Convert log_start in seconds
          , EXTRACT(DAY    FROM l.log_start) * 3600 * 24
          + EXTRACT(HOUR   FROM l.log_start) * 3600
          + EXTRACT(MINUTE FROM l.log_start) * 60
          + EXTRACT(SECOND FROM l.log_start) AS log_start_in_seconds
          --
          -- Convert log_ended in seconds
          , EXTRACT(DAY    FROM COALESCE(l.log_ended, CURRENT_TIMESTAMP)) * 3600 * 24
          + EXTRACT(HOUR   FROM COALESCE(l.log_ended, CURRENT_TIMESTAMP)) * 3600
          + EXTRACT(MINUTE FROM COALESCE(l.log_ended, CURRENT_TIMESTAMP)) * 60
          + EXTRACT(SECOND FROM COALESCE(l.log_ended, CURRENT_TIMESTAMP)) AS log_ended_in_seconds
          --
          -- Calculate the duration
          , CAST(log_ended_in_seconds - log_start_in_seconds AS INT) AS duration_in_seconds
          --
          -- Error Message if any
          , l.error_text AS error_text
          --
          -- SQL Query if `Dynamic SQL` was run.
          , l.dynamic_sql_text AS dynamic_sql_text
          --
     FROM ${nm_database_target}logging_tbl_log AS l
)
SELECT id_log, id_log_parent, environment_code, procedure_code, message_text, procedure_ended_in_error
     , CASE WHEN is_running = 1 AND duration_in_seconds > 1500 THEN 'Likely Not Running anymore' 
            WHEN is_running = 1                                THEN 'Running'
            ELSE 'Finished' END AS cd_status
     , CAST(CAST(cte.log_start AS FORMAT 'YYYY-MM-DDBHH:MI:SS') AS VARCHAR(32)) AS log_start
     , CAST(CAST(cte.log_ended AS FORMAT 'YYYY-MM-DDBHH:MI:SS') AS VARCHAR(32)) AS log_ended
     , duration_in_seconds, affected, error_text, dynamic_sql_text
FROM cte;