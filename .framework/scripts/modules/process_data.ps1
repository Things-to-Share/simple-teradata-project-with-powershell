function ps_process_data { param(
    [Parameter(Mandatory = $true)] [ValidateSet("O", "T", "A", "P")] [string]$ip_cd_environment,
    [switch]$ip_skip_processing_data
  )

  # Get Environment Infromation
  $environment        = $environments | Where-Object { $_.cd_environment -eq $ip_cd_environment}
  $parameters         = $environment.parameters
  $nm_database_target = ($parameters | Where-Object { $_.name -eq "nm_database_target" }).value
  $nm_database        = $nm_database_target.split('.')[0]
  $nm_dsn             = $environment.nm_dsn

  # OPen SQL Connection
  $ob_sql_connection = ps_sql_connection -ip_nm_dsn $nm_dsn -ip_nm_database $nm_database

  if ($false -eq $ip_skip_processing_data.IsPresent) { # Ingest, transform and prep Data
    
    # Execute ALL Process Groups
    $result = ps_exec_sql_non_query_statement -ip_ob_sql_connection $ob_sql_connection -ip_tx_sql "CALL $($nm_database_target)generic_usp_process_group_all(1);" -ip_nm_dsn $nm_dsn

      # Userfeedback that the process has failed.
    $tx_data_processing_failed = "The processing of then Ingestion, Transformation and Preparation for the CSV data has failed!"
    if ($result -eq $false) { Write-Host $tx_data_processing_failed -ForegroundColor DarkRed } else { 

      # Initalize result to true for Success
      $result = $true
      
      # Build SQL Statement for Extract the log records
      $tx_sql  =   "WITH" 
      $tx_sql += "`ncte_last_log_star AS ("
      $tx_sql += "`n  SELECT"
      $tx_sql += "`n    MAX(l.log_start) AS last_log_start"
      $tx_sql += "`n  FROM $($nm_database_target)logging_tbl_log AS l"
      $tx_sql += "`n  WHERE l.procedure_code = '$($nm_database_target)generic_usp_process_group_all'"
      $tx_sql += "`n),"
      $tx_sql += "`ncte_last_log_record AS ("
      $tx_sql += "`n  SELECT"
      $tx_sql += "`n    log_start,"
      $tx_sql += "`n    log_ended,"
      $tx_sql += "`n    error_text,"
      $tx_sql += "`n    CASE WHEN error_text IS NULL THEN 0 ELSE 1 END AS is_ended_in_error"
      $tx_sql += "`n  FROM $($nm_database_target)logging_tbl_log AS l"
      $tx_sql += "`n  WHERE l.procedure_code = '$($nm_database_target)generic_usp_process_group_all'"
      $tx_sql += "`n  AND l.log_start = (SELECT last_log_start FROM cte_last_log_star)"
      $tx_sql += "`n)"
      $tx_sql += "`nSELECT "
      $tx_sql += "`n  lr.log_start    AS log_start,"
      $tx_sql += "`n  lr.log_ended    AS log_ended,"
      $tx_sql += "`n  lr.message_text AS opreation,"
      $tx_sql += "`n  lr.error_text,"
      $tx_sql += "`n  lr.dynamic_sql_text"
      $tx_sql += "`nFROM $($nm_database_target)logging_tbl_log AS lr JOIN cte_last_log_record AS es "
      $tx_sql += "`nON  es.log_start <= lr.log_start "
      $tx_sql += "`nAND es.log_ended >= lr.log_ended"
      $tx_sql += "`nAND es.is_ended_in_error = 1"
      $tx_sql += "`nWHERE lr.error_text IS NOT NULL"
      $tx_sql += "`nORDER BY lr.log_start DESC;"

      # Execute SQL Statement for Extract the log records
      $rows = ps_exec_sql_query_statement -ip_ob_sql_connection $ob_sql_connection -ip_nm_dsn $nm_dsn -ip_tx_sql $tx_sql

      # Alle eigenschappen onder elkaar
      $rows | Format-List

      # stop processing if there were errors
      if ($null -ne $rows) { $result = $false; Write-Host $tx_data_processing_failed -ForegroundColor DarkRed; Exit-PSHostProcess }
      
    }
  }

  # return the result
  return $result
  
}