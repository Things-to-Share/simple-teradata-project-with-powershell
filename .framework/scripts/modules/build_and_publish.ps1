function ps_build_and_publish { param(
    [Parameter(Mandatory = $true)] [ValidateSet("O", "T", "A", "P")] 
    [string]$ip_cd_environment,
    [System.Boolean]$ip_publish,
    [System.Boolean]$ip_excl_drop_objects,
    [System.Boolean]$ip_excl_tables,
    [System.Boolean]$ip_excl_views,
    [System.Boolean]$ip_excl_procedrues,
    [System.Boolean]$ip_is_override
  )

  try {

    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Started" -ForegroundColor DarkGreen

    if ($true) { # Build Location
      $ni_build = 0
      $fp_build = "$($global:fp_root)\.framework\.deployment\.build\$($ip_cd_environment)"
      $global:fp_event_log = "$fp_build\event.log"
      if (!(Test-Path $fp_build | Out-Null )) { New-Item -ItemType Directory -Path $fp_build -Force | Out-Null; }
      Remove-Item "$fp_build\*.*" -Recurse -Force | Out-Null
    }

    if ($true) { # Select Environment based on $ip_cd_environment
      $environment = $environments | Where-Object { $_.cd_environment -eq $ip_cd_environment}
      $parameters  = $environment.parameters
      $nm_database_target = ($parameters | Where-Object { $_.name -eq "nm_database_target" }).value
      $nm_database = $nm_database_target.split('.')[0]
      $nm_dsn      = $environment.nm_dsn
      $ni_max_length_view = $environment.ni_max_length_view
    }

    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | $($environment.nm_environment)" -ForegroundColor DarkGreen

    if ($true) { # Load Object for Defintions and the Objects from the Database
      $objects_tx = ps_get_sql_file_inventory -ip_nm_database_target $nm_database_target -ip_environment $environment
      if ($objects_tx.Count -eq 0) { Write-Host "!!! No Definitions Found !!!" -ForegroundColor DarkRed; Exit 1; }
      Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Loaded Definitions from Files" -ForegroundColor DarkGreen
    }
    
    if ($true) { # Load Object for Defintions and the Objects from the Database
      $objects_db = ps_get_sql_objt_inventory -ip_nm_database_target $nm_database_target -ip_environment $environment -ip_nm_dsn $nm_dsn -ip_excl_tables $ip_excl_tables -ip_excl_views $ip_excl_views -ip_excl_procedrues $ip_excl_procedrues -ip_objects_tx $objects_tx
      if ($objects_db.Count -eq 0) { Write-Host "!!! No Database Object Found !!!" -ForegroundColor DarkMagenta; }
      Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Loaded Objects from Database" -ForegroundColor DarkGreen
    }

    # -------------------------------------------------------------------------
    # DROP "OBJECTS" : Determine Actions for Object to be Removed, loop 
    #                  throught all database Objects and if there is NOT 
    #                  Definition for it Drop it.
    # -------------------------------------------------------------------------
    if ($false -eq $ip_excl_drop_objects) { 
      foreach ($object_db in $objects_db) {
        try {

          # Database Object
          $nm_database_object = if ($object_db.nm_schema -ne "n/a") { "$nm_database_target$($object_db.nm_schema)_$($object_db.nm_object)" } else { "$nm_database.$($object_db.fp_relative)" }

          # Find Schema + Object Name in Definitions
          $object_tx = $objects_tx | Where-Object { $_.nm_schema -eq $object_db.nm_schema -and $_.nm_object -eq $object_db.nm_object } 

          # Drop the Object if in the Database and NOT in definitions files
          if ($null -eq $object_tx) {
          
            # Build SQL Statement
            if ($object_db.cd_type -eq "procedures") {  $tx_sql = "DROP PROCEDURE $nm_database_object;" }
            if ($object_db.cd_type -eq "views") {       $tx_sql = "DROP VIEW $nm_database_object;" }
            if ($object_db.cd_type -eq "tables") {      $tx_sql = "DROP TABLE $nm_database_object;" }

            # Create SQL Files to be exectuted later
            $ni_build += 1;  $tx_sql | Out-File -FilePath "$fp_build\$($ni_build.ToString("000"))-Drop-$nm_database_object.sql" -Encoding UTF8 

          }
        } catch { Write-Error "Updating Database failed: $($_.Exception.Message)"; throw }
        
      }
    }

    # -------------------------------------------------------------------------
    # TABLE CHANGES : Creates, ALTER COLUMN DATATYPES.
    # -------------------------------------------------------------------------
    if ($false -eq $ip_excl_tables) { 
      foreach ($object_tx in ($objects_tx | Where-Object { $_.cd_type -eq "tables" })) {
        try {

          # Database Object
          $nm_database_object = "$nm_database_target$($object_tx.nm_schema)_$($object_tx.nm_object)"

          # Fetch Table/Column Definitions
          $object_db = $objects_db | Where-Object { $_.nm_schema -eq $object_tx.nm_schema -and $_.nm_object -eq $object_tx.nm_object }
          
          # Compare defintions if exists in scripts and database     
          $differences = if ($object_tx.dt_modified -ne $object_db.dt_modified) { $true } else  { $false }
          
          # If table does not exists yet, used create statement
          if ($null -eq $object_db) {
            $ni_build += 1;  $object_tx.tx_object | Out-File -FilePath "$fp_build\$($ni_build.ToString("000"))-Create-Table-$nm_database_object.sql" -Encoding UTF8 
          }
          else { # Generate ALTER statements
            if ($differences) {

              # Generate Alter Statmens
              $ni_build += 1; ps_generate_table_alter_script `
                -ip_ob_table_db $object_db `
                -ip_ob_table_tx $object_tx `
                -ip_nm_database $nm_database_target `
                -ip_nm_schema $object_tx.nm_schema `
                -ip_nm_table $object_tx.nm_object `
                -ip_ni_build $ni_build `
                -ip_fp_build $fp_build;
                            
            }
          }        
        } catch { Write-Error "Updating Database failed: $($_.Exception.Message)"; throw }

      }
    }

    # -------------------------------------------------------------------------
    # VIEW CHANGES : Replace Views
    # -------------------------------------------------------------------------
    if ($false -eq $ip_excl_views) { 
      foreach ($object_tx in ($objects_tx | Where-Object { $_.cd_type -eq "views" })) {
        try {

          # Add Warning that the View Definition longer is the $ni_max_length_view characters and posibility of being cut-off in de DBC.TableV.RequestText
          # This impacts the metadata_tbl_referenced information and could lead to inaccurated processing order.
          $ni_length_view_text = "$($object_tx.tx_object)".Length
          if ($ni_length_view_text -gt $ni_max_length_view) {
            Write-Host "!"*80 -BackgroundColor Gray -ForegroundColor DarkRed
            Write-Host "!!! The length of the VIEW $($object_tx.nm_schema).$($object_tx.nm_object) is longer then $ni_max_length_view characters." -BackgroundColor Gray -ForegroundColor DarkRed
            Write-Host "Please evaluatie if the Dataset (table/view) Defintion can be shortend of splitup." -BackgroundColor Gray -ForegroundColor DarkRed
            $respons = Read-Host "Provide S=Stop Processing, C=Continue" -BackgroundColor Gray -ForegroundColor DarkRed
            if ($respons -ne "C") {
              throw "Processing Aborted!"
            }
          }

          # Database Object
          $nm_database_object = "$nm_database_target$($object_tx.nm_schema)_$($object_tx.nm_object)"

          # Fetch view Definition from DB
          $object_db = ($objects_db | Where-Object { $_.nm_schema -eq $object_tx.nm_schema -and $_.nm_object -eq $object_tx.nm_object })

          # Compare DB vs Script
          $sql_db_cleaned = ps_minify_sql -SqlQuery "$($object_db.tx_object) "
          $sql_tx_cleaned = ps_minify_sql -SqlQuery "$($object_tx.tx_object) "
          
          # if equal then empty the $sql-value, for there are "NO" technical changes
          if (($sql_tx_cleaned -ne $sql_db_cleaned) -or ($true -eq $ip_is_override)) {
            $ni_build += 1;  $object_tx.tx_object | Out-File -FilePath "$fp_build\$($ni_build.ToString("000"))-View-$nm_database_object.sql" -Encoding UTF8 
          }

        } catch { Write-Error "Updating Database failed: $($_.Exception.Message)"; throw }

      }
    }

    # -------------------------------------------------------------------------
    # PROCEDURE CHANGES : Replace Procedures
    # -------------------------------------------------------------------------
    if ($false -eq $ip_excl_procedrues) { 
      foreach ($object_tx in ($objects_tx | Where-Object { $_.cd_type -eq "procedures" })) {
        try {

          # Database Object
          $nm_database_object = "$nm_database_target$($object_tx.nm_schema)_$($object_tx.nm_object)"

          # Fetch view Definition from DB
          $object_db = ($objects_db | Where-Object { $_.nm_schema -eq $object_tx.nm_schema -and $_.nm_object -eq $object_tx.nm_object })

          # Compare DB vs Script
          $sql_db_cleaned = ps_minify_sql -SqlQuery "$($object_db.tx_object) "
          $sql_tx_cleaned = ps_minify_sql -SqlQuery "$($object_tx.tx_object) "
          
          # if equal then empty the $sql-value, for there are "NO" technical changes
          if (($sql_tx_cleaned -ne $sql_db_cleaned) -or ($true -eq $ip_is_override)) {
            $ni_build += 1;  $object_tx.tx_object | Out-File -FilePath "$fp_build\$($ni_build.ToString("000"))-Procedure-$nm_database_object.sql" -Encoding UTF8 
          }

        } catch { Write-Error "Updating Database failed: $($_.Exception.Message)"; throw }
        
      }
    }

    Write-Host "Build SQL Update Files Complete" -ForegroundColor Green

    # Processing Build File
    if ($true -eq $ip_publish) {
      $ni_failed = ps_publish -ip_fp_build $fp_build -ip_nm_dsn $environment.nm_dsn -ip_nm_database "DBC"
      if ($null -eq $ni_failed) { $ni_failed = 0 }
    }

    $result = $true
    if ($ni_build -ne 0)  { # if no build-files, metadata need no updating

      Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Updating Metadata" -ForegroundColor DarkGreen
      $ob_sql_connection = ps_sql_connection -ip_nm_dsn $environment.nm_dsn -ip_nm_database "DBC"
      $tx_sql = "CALL $($nm_database_target)metadata_usp_load_metadata(0);"
      $result = ps_exec_sql_non_query_statement -ip_nm_dsn $environment.nm_dsn -ip_ob_sql_connection $ob_sql_connection -ip_tx_sql $tx_sql

    }

    $tx = "Database is "
    if ($ni_failed -eq 0) {   $tx += "updated" } else { $tx += "has NOT (completely) updated, build SQL-Files have FAILED!" }
    if ($result -eq $false) { $tx += ", however the updating of the Metadata has failed!" }
    if ($tx -eq "Database is updated") { Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | $tx" -ForegroundColor DarkGreen } 
    else {                               Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | $tx" -ForegroundColor DarkRed }

  }
  catch { ps_log_error -ip_fp_event_log $global:fp_event_log -ip_tx_sql_statement "n/a" -ip_feedback; exit 1; }

}

function ps_publish { param(
    [Parameter(Mandatory=$true)] [string]$ip_fp_build,
    [Parameter(Mandatory=$true)] [string]$ip_nm_dsn,
    [Parameter(Mandatory=$true)] [string]$ip_nm_database
  )
  try {
    
    # Set Start Datetime
    $global:dt_start = Get-Date

    # Create log file path
    $nm_build = [System.IO.Path]::GetFileNameWithoutExtension($ip_fp_build)
    $global:fp_event_log = "$(Split-Path $ip_fp_build -Parent)\$nm_build.event.log"
    "Start Event Log" | Out-File -FilePath "$global:fp_event_log" -Encoding UTF8

    # Get SQL statements from build file
    $statements = ps_get_sql_statements -ip_fp_build $ip_fp_build
    
    # Check if there are statements
    if ($statements.Count -eq 0) { Write-Host "No SQL statements found in build file" -ForegroundColor Green; return }
        
    # Initialize progress bar
    $stats = @{
      ni_total    = $statements.Count
      nr_complete = 0.0
      ni_done     = 0
      ni_todo     = $statements.Count
      ni_failed   = 0
      ni_retry    = 0
      mx_retry    = 1
    }
    
    ## Initialized Progressbar
    Write-Progress -Id 1 -Activity "SQL Processing" -Status "Starting..." -PercentComplete $stats.nr_complete
    Write-Progress -Id 2 -Activity "SQL Build File" -Status "Loading..."  -PercentComplete $stats.nr_complete
    
    # Loop through all statements
    $ob_sql_connection = $null; $n=0; foreach ($statement in $statements) {

      # Initialize SQL connection
      if ($null -eq $ob_sql_connection) { $ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database $ip_nm_database }

      # initialize success, as long as false 3 mx_retry are attempted
      $stats.ni_retry = 0; $successfull = $false; while ($stats.ni_retry -lt $stats.mx_retry -and -not $successfull) {
        try {

          # Execute SQL statement
          $successfull = ps_exec_sql_non_query_statement -ip_nm_dsn $ip_nm_dsn -ip_ob_sql_connection $ob_sql_connection -ip_tx_sql $statement.tx_sql
           
          If ($successfull -eq $false) {
            
            # Add 1 to the retries
            $stats.ni_retry += 1

            if ($stats.ni_retry -ge $stats.mx_retry) {
            
              # Feedback on status of statement
              $n+=1; Write-Host "Statement # $n | Failed to deploy: ""$($statement.fp_build)""" -ForegroundColor Red
              $stats.ni_todo -= 1
              $stats.ni_failed += 1

            }
            
          }
          else {
            
            # Feedback on status of statement
            $n+=1; # Write-Host "Statement # $n | Successfully deployed: ""$($statement.fp_build)""" -ForegroundColor DarkGreen

            # Update Stats
            $stats.ni_todo -= 1
            $stats.ni_done += 1
            $stats.nr_complete = ($stats.ni_done / $stats.ni_total) * 100

          }

          $dt_elapsed = $(Get-Date) - $global:dt_start
          $tx_elapsed = $dt_elapsed.ToString('hh\:mm\:ss')
          Write-Progress -id 1 -Activity "SQL Processing" -Status "$tx_elapsed | Executing $($stats.ni_done) of $($stats.ni_total) | Failed : $($stats.ni_failed)" -PercentComplete $stats.nr_complete
          Write-Progress -id 2 -Activity "SQL Build File" -Status "$($statement.fp_build)" -PercentComplete $stats.nr_complete 
          
        } catch {

          # Log Error
          ps_log_error -ip_fp_event_log $Global:fp_event_log -ip_tx_sql_statement $statement
          
          # Add 1 to the retries
          $stats.ni_retry += 1
          
          # If Retry is less the Max Retry
          if ($stats.ni_retry -lt $stats.mx_retry) {
            
            # Re-initialize SQL connection for retry
            try { $ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database $ip_nm_database }
            catch { ps_log_error -ip_fp_event_log $Global:fp_event_log -ip_tx_sql_statement $ip_tx_sql; $stats.ni_retry = $stats.mx_retry }

          }
        }

      }
      
    }

    # Remove Progressbar
    Write-Progress -Id 1 -Activity "SQL Processing" -Completed
    Write-Progress -Id 2 -Activity "SQL Build File" -Completed    

    # Complete progress bar
    Write-Host "Successfully processed $($stats.ni_done) of $($stats.ni_total) SQL statements" -ForegroundColor Green
    Write-Host "Failed processing $($stats.ni_failed) of $($stats.ni_total) SQL statements"    -ForegroundColor DarkRed
    
  }
  catch {
    ps_log_error -ip_fp_event_log $Global:fp_event_log -ip_tx_sql_statement "n/a"
  }

   return $($stats.ni_failed)
   
}
