function ps_get_sql_file_inventory { param(
    [Parameter(Mandatory=$true)] [string]$ip_nm_database_target,
    [Parameter(Mandatory=$true)] $ip_environment
  )
    
    # Initialize Local Variables
    $ni_ordering = 0

    $folders = @(
      "$global:fp_root\.framework\.base_feautes",
      "$global:fp_root\project\definitions"
    )

    # Methode 2: Gedetailleerde informatie exporteren naar CSV
    $sqlFiles = foreach ($folder in $folders) { if (Test-Path $folder) { Get-ChildItem -Path $folder -Filter "*.sql" -Recurse -File } }
    
    # Process each SQL file
    $results = foreach ($file in $sqlFiles) {

      # Get relative path from base folder
      $fp_relative = $file.FullName
      foreach ($folder in $folders) { $fp_relative = $fp_relative.Replace($folder, "").TrimStart('\', '/') }

      # Get Latest modified Data of File
      $dt_modified = if ( $file.LastWriteTime -gt $file.CreationTime ) {  $file.LastWriteTime } else { $file.CreationTime }

      If ($true) { # Extract Object Text and clean it

        $tx_object = Get-Content "$($file.FullName)" -Raw;
        $tx_object = ps_remove_comments $tx_object

        # Replace ($environ)
        $tx_object = $tx_object.Replace('${cd_environment}', $ip_environment.cd_environment)
        $tx_object = $tx_object.Replace('${nm_environment}', $ip_environment.nm_environment)
        $tx_object = $tx_object.Replace('${nm_database}',    $ip_environment.nm_database)

        # Loop througth the Parameters and replace the placeholders in the SQL Statement
        foreach ($parameter in $ip_environment.parameters) { $tx_object = $tx_object.Replace('${' + $parameter.name + '}', $parameter.value) }

      }

      # Split path into parts
      $pathParts = $fp_relative -split '\\'

      $ni_ordering += 1
      $nm_grouping = $pathParts[0]
      $nm_schema   = $pathParts[1]
      $cd_type     = $pathParts[2]
      if ($pathParts.Length -ge 4) { $nm_object = $pathParts[3].replace(".sql",""); }
      
      # Build Table Definiton if needed
      if ($cd_type -eq "tables") {
        $ob_table = ps_get_table_def_from_sql_statement -ip_tx_sql_statement  $tx_object -ip_nm_database $ip_nm_database_target -ip_nm_schema $nm_schema -ip_nm_table $nm_object  
      }

      # Create custom object with all properties
      [PSCustomObject]@{
          ni_ordering = $ni_ordering
          fp_relative = $fp_relative
          nm_grouping = $nm_grouping
          nm_schema   = $nm_schema
          nm_object   = $nm_object
          cd_type     = $cd_type
          tx_object   = $tx_object
          ob_table    = $ob_table              
          dt_modified = $dt_modified
      }

    }
    
    # Sort by ordering and return
    return $results | Sort-Object ni_ordering
}

function ps_get_sql_objt_inventory { param(
    [Parameter(Mandatory=$true)] [string]$ip_nm_database_target,
    [Parameter(Mandatory=$true)] [string]$ip_nm_dsn,
    [Parameter(Mandatory=$true)] $ip_environment,
    [Parameter(Mandatory=$true)] $ip_excl_tables,
    [Parameter(Mandatory=$true)] $ip_excl_views,
    [Parameter(Mandatory=$true)] $ip_excl_procedrues,
    [Parameter(Mandatory=$true)] $ip_objects_tx
  )
   
  # Open SQL Connection
  $ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database "DBC"    
  
  # Initialize Collection of Objects
  $ni_ordering = 0;  
  $objects = @()

  if ($true) { # Extract Tables from Database

    # Build SQL Statment
    $tx_sql  = "WITH"
    $tx_sql += "`ncte_objects AS ("
    $tx_sql += "`n  SELECT CAST(LOWER(t.DatabaseName) AS VARCHAR(128))            AS nm_database,"
    $tx_sql += "`n         CAST(t.TableName AS VARCHAR(255))                      AS nm_database_object,"
    $tx_sql += "`n         --" # Logic to extract "nm_schema"
    $tx_sql += "`n         LENGTH('$ip_nm_database_target') AS ni_database_target,"
    $tx_sql += "`n         SUBSTR(t.DataBaseName||'.'||t.TableName, ni_database_target+1, LENGTH(t.DataBaseName||'.'||t.TableName) - ni_database_target) AS nm_schema_table,"
    $tx_sql += "`n         CASE"
    $tx_sql += "`n           WHEN t.TableKind = 'T' THEN POSITION('_tbl' IN nm_schema_table)"
    $tx_sql += "`n           WHEN t.TableKind = 'V' THEN POSITION('_viw' IN nm_schema_table)"
    $tx_sql += "`n           WHEN t.TableKind = 'P' THEN POSITION('_usp' IN nm_schema_table)"
    $tx_sql += "`n           ELSE 0 "
    $tx_sql += "`n         END AS ni_schema_length,"
    $tx_sql += "`n         CASE WHEN ni_schema_length <> 0 THEN SUBSTR(nm_schema_table, 1, ni_schema_length-1) ELSE 'n/a' END AS nm_schema,"
    $tx_sql += "`n         --" 
    $tx_sql += "`n         CASE" 
    $tx_sql += "`n           WHEN ni_schema_length <> 0 THEN"
    $tx_sql += "`n             CASE"
    $tx_sql += "`n               WHEN t.TableKind = 'T' THEN 'tbl_'"
    $tx_sql += "`n               WHEN t.TableKind = 'V' THEN 'viw_'"
    $tx_sql += "`n               WHEN t.TableKind = 'P' THEN 'usp_'"
    $tx_sql += "`n               ELSE 0 "
    $tx_sql += "`n           END || SUBSTR(nm_schema_table, ni_schema_length+5, LENGTH(nm_schema_table) - (ni_schema_length+3))"
    $tx_sql += "`n           ELSE 'n/a'"
    $tx_sql += "`n         END AS nm_object,"
    $tx_sql += "`n         --"
    $tx_sql += "`n         GREATEST(t.CreateTimeStamp, t.LastAlterTimeStamp) AS dt_modified,"
    $tx_sql += "`n         --"
    $tx_sql += "`n         CASE"
    $tx_sql += "`n           WHEN t.TableKind = 'T' THEN 'tables'"
    $tx_sql += "`n           WHEN t.TableKind = 'V' THEN 'views'"
    $tx_sql += "`n           WHEN t.TableKind = 'P' THEN 'procedures'"
    $tx_sql += "`n           ELSE 'n/a'"
    $tx_sql += "`n         END AS cd_type"
    $tx_sql += "`n         --"
    $tx_sql += "`n  FROM DBC.TablesV AS t "
    $tx_sql += "`n  WHERE t.DataBaseName || '.' || t.TableName LIKE '$ip_nm_database_target%'"
    $tx_sql += "`n  AND   t.TableKind IN ("
    if ($false -eq $ip_excl_tables) {     $tx_sql += "`n          'T'," }
    if ($false -eq $ip_excl_views) {      $tx_sql += "`n          'V'," }
    if ($false -eq $ip_excl_procedrues) { $tx_sql += "`n          'P'," }
    $tx_sql += "`n          '~')"
    $tx_sql += "`n)"
    $tx_sql += "`nSELECT * FROM cte_objects" 

    # Execute SQL Statement
    $rows = ps_exec_sql_query_statement -ip_ob_sql_connection $ob_sql_connection -ip_tx_sql $tx_sql -ip_nm_dsn $ip_nm_dsn

  }
   
  # Set Progressbar variabel
  $pb = [PSCustomObject]@{
    ni_total    = $rows.Count
    ni_todo     = $rows.Count
    ni_done     = 0
    tx_status   = ""
    nm_object   = ""
    nr_complete = 0
    dt_started  = Get-Date
    dt_elapsed  = Get-Date 
  }

  # Loop through the result and store them in desired structure
  foreach ($row in $rows) { $ni_ordering += 1
    
    # Object Type
    $cd_type = $row["cd_type"]

    # Schema an Table
    $nm_database = $row["nm_database"]
    $nm_schema   = $row["nm_schema"]
    $nm_object   = $row["nm_object"]
    $dt_modified = $row["dt_modified"]
    
    # fp_relative is Here the table name in the Database (without the database name)
    $fp_relative = $row["nm_database_object"]
    
    # Grouping determination
    $nm_grouping = "n/a"

    # Create and Populate Table Object
    $ob_table = [cl_table]::new()
    if ($cd_type -eq "tables") {

      # Load Table Definition
      $ob_table.Database   = $ip_nm_database_target
      $ob_table.SchemaName = $nm_schema
      $ob_table.TableName  = $nm_object     
    
    }

    if ($true) { # Progressbar

      $pb.nm_object   = $fp_relative
      $pb.nr_complete = $pb.ni_done / $pb.ni_total
      $pb.dt_elapsed  = $(Get-Date) - $pb.dt_started
      $pb.tx_status  = "$($pb.dt_elapsed.ToString('hh\:mm\:ss')) | Total: $($pb.ni_total) | Done: $($pb.ni_done) | Todo: $($pb.ni_todo) | Completed : $($pb.nr_complete.ToString("P2"))"

      ## Initialized Progressbar
      Write-Progress -Id 1 -Activity "Progress  " -Status $pb.tx_status      -PercentComplete $($pb.nr_complete * 100)
      Write-Progress -Id 2 -Activity "SQL Object" -Status "$($pb.nm_object)" -PercentComplete $($pb.nr_complete * 100)

    }

    # Get local dt_modified of definition
    $def = $ip_objects_tx | Where-Object { ($_.nm_schema -eq $nm_schema) -and ($_.nm_object -eq $nm_object) }
    $def_dt_modified = if ( $null -eq $def ) { Get-Date } else { $def.dt_modified }

    # Extract Full Text from DB
    if ($dt_modified -lt $def_dt_modified) { 
            
      # Build Table Definiton if needed
      if ($cd_type -eq "tables") {
        $ob_table = ps_get_table_def_from_sql_database -ip_ob_sql_connection $ob_sql_connection -ip_nm_database $ip_nm_database_target -ip_nm_schema $nm_schema -ip_nm_table $nm_object -ip_nm_dsn $ip_nm_dsn  
      }

      # Populate the "Object"
      $object = [PSCustomObject]@{
        ni_ordering = $ni_ordering
        fp_relative = $fp_relative
        nm_grouping = $nm_grouping
        nm_schema   = $nm_schema
        nm_object   = $nm_object
        cd_type     = $cd_type
        tx_object   = $tx_object
        ob_table    = $ob_table
        dt_modified = $dt_modified
      }
    
    }
    else { # Database object "older" (was created after modified of file)

          # Populate the "Object"
      $object = [PSCustomObject]@{
        ni_ordering = $def.ni_ordering
        fp_relative = $def.fp_relative
        nm_grouping = $def.nm_grouping
        nm_schema   = $def.nm_schema
        nm_object   = $def.nm_object
        cd_type     = $def.cd_type
        tx_object   = $def.tx_object
        ob_table    = $def.ob_table
        dt_modified = $def.dt_modified
      }


    }

    # Add the object to the Collection of Objects
    $objects += $object
  
    if ($true) { # Progressbar
      $pb.ni_todo    -= 1
      $pb.ni_done    += 1
      $pb.nr_complete = $pb.ni_done / $pb.ni_total
      $pb.dt_elapsed  = $(Get-Date) - $pb.dt_started
      $pb.tx_status  = "$($pb.dt_elapsed.ToString('hh\:mm\:ss')) | Total: $($pb.ni_total) | Done: $($pb.ni_done) | Todo: $($pb.ni_todo) | Completed : $($pb.nr_complete.ToString("P2"))"

      ## Initialized Progressbar
      Write-Progress -Id 1 -Activity "Progress  " -Status $pb.tx_status      -PercentComplete $($pb.nr_complete * 100)
      Write-Progress -Id 2 -Activity "SQL Object" -Status "$($pb.nm_object)" -PercentComplete $($pb.nr_complete * 100)

    }

  }

  # Remove Progressbar
  Write-Progress -Id 1 -Activity "Progress  " -Completed
  Write-Progress -Id 2 -Activity "SQL Object" -Completed

  # Sort by ordering and return
  return $objects | Sort-Object ni_ordering

}

function ps_generate_table_alter_script { param(
    [Parameter(Mandatory=$true)] $ip_ob_table_db,
    [Parameter(Mandatory=$true)] $ip_ob_table_tx,
    [Parameter(Mandatory=$true)] $ip_nm_database_target,
    [Parameter(Mandatory=$true)] $ip_nm_schema,
    [Parameter(Mandatory=$true)] $ip_nm_table,
    [Parameter(Mandatory=$true)] $ip_ni_build,
    [Parameter(Mandatory=$true)] $ip_fp_build
  ) try {

    # Set Various Variables
    $emp             = ""
    $nwl             = "`n"
    $tx_sql_create   = $ip_ob_table_tx.tx_object
    $nm_table_target = "$($ip_nm_database_target)$($ip_nm_schema)_$($ip_nm_table)"
    $nm_table_rename = "$($nm_table_target)_renamed"
    $ls_column       = ""; foreach ($c in $ip_ob_table_tx.ob_table.Columns) { $comma = if ($ls_column -eq "") { "" } else { "," }; $ls_column += "$($comma) $($c.ColumnName)" }
    $ls_select       = ""; foreach ($c in $ip_ob_table_tx.ob_table.Columns) {
      
      # Determine if 1st column if not add "comma" and  "newline"
      $comma = $(if ($ls_select -eq "") { "" } else { "," }) +"`n";
      
      # if the column is "new" the default value must be used if NOT nullable
      $e = $ip_ob_table_db.ob_table.Columns | Where-Object { $_.ColumnName -eq $c.ColumnName }

      if ( $null -ne $e ) { # Column existed, so CAST with "new" datatype

        # Check if Datatype Are equal
        if ($c.Datatype -eq $e.Datatype) { $value = "src.$($c.ColumnName)" } else { # --> Datatypes are not Equal !!!
          
          # Assesment of Conversion
          $ob_source_datatype = [PSCustomObject]@{
            datatype  = $e.Datatype
            maxlength = $e.MaxLength
            precision = $e.precision
            scale     = $e.scale
          }
          $ob_target_datatype = [PSCustomObject]@{
            datatype  = $c.Datatype
            maxlength = $c.MaxLength
            precision = $c.precision
            scale     = $c.scale
          }

          # assesment of Conversion
          $conversion = ps_assesment_of_conversion -ip_source_datatype $ob_source_datatype  -ip_target_datatype $ob_target_datatype
          if ($false -eq $conversion.IsAllowed) { throw $conversion.Recommendation }

          # Conversion Seems to be Allowed or is of low risk
          $value = "CAST(src.$($c.ColumnName) AS $($c.DataType)) AS $($c.ColumnName)"

        }
      } 
      else { # Column is New
        if ($true -eq $c.IsNullable) { $value = "CAST(NULL AS $($c.DataType)) AS $($c.ColumnName)" }
        else { # is not NULLABLE use default value
          if ($null -eq $c.DefaultValue) { throw "Column ``$($c.ColumnName)`` is NOT Nullable and has NO ``DEFAULT`` Assigned!!!" }
          else { $value = "CAST($($c.DefaultValue) AS $($c.DataType)) AS $($c.ColumnName)" }
        }
        
      }

      # Extrent the SELECT-Clause "new"-column value
      $ls_select += "$($comma)  $($value)"

    }

    $tx_sql = "RENAME TABLE $nm_table_target TO $nm_table_rename;"
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-A-Rename-$nm_table_target-to-$nm_table_rename.sql" -Encoding UTF8 
    
    $tx_sql = $tx_sql_create
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-B-(Re)deploy-$nm_table_target.sql" -Encoding UTF8 

    $tx_sql  = $emp + "INSERT INTO $nm_table_target ( $ls_column )"
    $tx_sql += $nwl + "SELECT" + $ls_select
    $tx_sql += $nwl + "FROM $nm_table_rename AS src;"
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-C-Load-existing-Data-into-$nm_table_target.sql" -Encoding UTF8 
    
    $tx_sql = "DROP TABLE $nm_table_rename;" 
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-D-Drop-Renamed-Table-$nm_table_rename.sql" -Encoding UTF8 

  }
  catch {
    $tx_error  = "!!!" + "!" * 80
    $tx_error += "Failed to Generate alter script for ``$ip_nm_schema``_``$ip_nm_table``!!"
    $tx_error += "`n$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    $tx_error += "`n$($_.Exception.Message)"               # -> Error message
    $tx_error += "`n$($_.Exception.GetType().FullName)"    # -> Error type
    $tx_error += "`n$($_.ScriptStackTrace)"                # -> Stack trace
    $tx_error += "`n$($_.InvocationInfo.ScriptLineNumber)" # -> Line number where error occurred
    $tx_error += "`nSQL:`n$tx_sql"
    $tx_error += "!!!" + "!" * 80
    Write-Host $tx_error -BackgroundColor White -ForegroundColor DarkRed
  }

}

function get_credentials { param(
    [Parameter(Mandatory=$true)]  [string]$ip_prompt_for_override
  )

    $credentialPath = "$env:USERPROFILE\.teradata_credentials.xml"
    $forceNewCredentials = $false
    
    # Check if credentials already exist
    if (Test-Path $credentialPath) {
        #Write-Host "Existing credentials found." -ForegroundColor Yellow
        if ($ip_prompt_for_override -eq "y") {
            $response = Read-Host "Would you like to re-enter your database credentials? (y/n)"
            if ($response -eq 'y' -or $response -eq 'Y' -or $response -eq 'yes') {
                $forceNewCredentials = $true
            }
        }
    } else {
        Write-Host "No stored credentials found." -ForegroundColor Yellow
        $forceNewCredentials = $true
    }
    
    if ($forceNewCredentials) {
        # Prompt for new credentials
        Write-Host "Please enter your Teradata database credentials:" -ForegroundColor Cyan
        $username = Read-Host "Username"
        $securePassword = Read-Host "Password" -AsSecureString
        
        # Create credential object
        $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)
        
        # Save encrypted credentials to file
        try {
            $credential | Export-Clixml -Path $credentialPath
            Write-Host "Credentials saved securely." -ForegroundColor Green
        } catch {
            Write-Warning "Could not save credentials: $($_.Exception.Message)"
        }
        
        return $credential
    } else {
        # Load existing credentials
        try {
            $credential = Import-Clixml -Path $credentialPath
            #if ($ip_prompt_for_override -eq "y") {
            #    Write-Host "Using stored credentials for user: $($credential.UserName)" -ForegroundColor Green
            #}
            return $credential
        } catch {
            Write-Error "Could not load stored credentials: $($_.Exception.Message)"
            Write-Host "Prompting for new credentials..." -ForegroundColor Yellow
            
            # Fallback to prompting for new credentials
            $username = Read-Host "Username"
            $securePassword = Read-Host "Password" -AsSecureString
            return New-Object System.Management.Automation.PSCredential($username, $securePassword)
        }
    }
}

function ps_sql_connection { param(
    [Parameter(Mandatory=$true)] [string]$ip_nm_dsn,
    [Parameter(Mandatory=$true)] [string]$ip_nm_database
  )

  # Get credentials securely
  $dbCredential = get_credentials -ip_prompt_for_override "n"
  $nm_username = $dbCredential.UserName
  $cd_password = $dbCredential.GetNetworkCredential().Password

  # Build connection string using DSN
  $tx_connection_string = @(
      "DSN=$ip_nm_dsn"
      "UID=$nm_username"
      "PWD=$cd_password"
      "Database=$ip_nm_database"
  ) -join ";"
  
  # Initialize retry variables
  $maxRetries = 3
  $retryCount = 0
  $connectionSuccessful = $false
  $ob_connection = $null

  # Retry loop
  while ($retryCount -lt $maxRetries -and -not $connectionSuccessful) {
    try {
      # Build and Open Connection-Object
      $ob_connection = New-Object System.Data.Odbc.OdbcConnection
      $ob_connection.ConnectionString = $tx_connection_string
      $ob_connection.Open()
      
      # If we reach this point, connection was successful
      $connectionSuccessful = $true
      #Write-Host "Database connection established successfully." -ForegroundColor Green
    }
    catch {
      $retryCount++
      #Write-Warning "Connection attempt $retryCount failed: $($_.Exception.Message)"
      
      # Clean up failed connection object
      if ($ob_connection) {
        try { $ob_connection.Dispose() } catch { }
        $ob_connection = $null
      }
      
      # If not the last retry, wait before trying again
      if ($retryCount -lt $maxRetries) {
        $waitTime = $retryCount * 2  # Progressive delay: 2, 4, 6 seconds
        #Write-Host "Waiting $waitTime seconds before retry..." -ForegroundColor Yellow
        Start-Sleep -Seconds $waitTime
      }
      else {
        # All retries exhausted
        Write-Error "Failed to establish database connection after $maxRetries attempts. Last error: $($_.Exception.Message)"
        throw "Database connection failed after $maxRetries retry attempts"
      }
    }
  }

  # Return the open connection object
  return $ob_connection

}

function ps_sql_command { param(
    [Parameter(Mandatory=$true)] $ip_ob_sql_connection,
    [Parameter(Mandatory=$true)] $ip_tx_sql
  )

  # Create command for stored procedure call
  $ob_command = $ip_ob_sql_connection.CreateCommand()
  $ob_command.CommandText = $ip_tx_sql
  $ob_command.CommandType = [System.Data.CommandType]::Text
  $ob_command.CommandTimeout = 0  # No timeout for long-running procedures

  # Retrun the SQL Command object
  return $ob_command

}

function ps_exec_sql_query_statement { param(
    [Parameter(Mandatory=$true)] $ip_ob_sql_connection,
    [Parameter(Mandatory=$true)] $ip_tx_sql,
    [Parameter(Mandatory=$true)] $ip_nm_dsn
  ) try { 
    $retry = 0; $return = $false; while ($retry -lt 3 -and $return -eq $false) {
      try {

        # Create command for SQL query
        $ob_command = ps_sql_command -ip_ob_sql_connection $ip_ob_sql_connection -ip_tx_sql $ip_tx_sql

        # Create data adapter and dataset to hold results
        $ob_adapter = New-Object System.Data.Odbc.OdbcDataAdapter($ob_command)
        $ob_dataset = New-Object System.Data.DataSet
        
        # Execute SQL Query and fill dataset
        #Write-Host "Executing SQL query: $ip_tx_sql" -ForegroundColor DarkYellow
        $ob_adapter.Fill($ob_dataset) | Out-Null
        
        # Get the result table
        $ob_resultset = $ob_dataset.Tables[0]
        
        # Return the result set
        return $ob_resultset

      }
      catch {

        # Set local variables
        $return = $false; $retry += 1;      

        # Close connection if still open
        if ($ip_ob_sql_connection -and $ip_ob_sql_connection.State -eq 'Open') { $ip_ob_sql_connection.Close() }

        # Extract Error
        #$tx_error  =   "Error message: $($_.Exception.Message)"
        #$tx_error += "`nFull error details: $($_.Exception)"
        #$tx_error += "SQL Statement: `n$ip_tx_sql"
        #Write-host $tx_error -ForegroundColor DarkRed
        
      }
    }
  } catch {
    
    # Close connection if still open
    if ($ip_ob_sql_connection -and $ip_ob_sql_connection.State -eq 'Open') { $ip_ob_sql_connection.Close() }
    $ip_ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database "DBC"

    # Extract Error
    $tx_error  =   "Error message: $($_.Exception.Message)"
    $tx_error += "`nFull error details: $($_.Exception)"
    $tx_error += "`nSQL Statement: `n$ip_tx_sql"
    Write-host $tx_error -ForegroundColor DarkRed
    
    # Return empty dataset
    return $(New-Object System.Data.DataTable)

  } finally {

    # Clean up objects
    if ($ob_adapter) { $ob_adapter.Dispose() }
    if ($ob_dataset) { $ob_dataset.Dispose() }
    if ($ob_command) { $ob_command.Dispose() }
    
    # Clear sensitive variables from memory
    if ($cd_password) { $cd_password = $null }
    if ($dbCredential) { $dbCredential = $null }
    if ($tx_connection) { $tx_connection = $null }
    [System.GC]::Collect()

  }
}

function ps_exec_sql_non_query_statement { param(
    [Parameter(Mandatory=$true)] [string]$ip_nm_dsn,  
    [Parameter(Mandatory=$true)] $ip_ob_sql_connection,
    [Parameter(Mandatory=$true)] $ip_tx_sql
  )
  $retry = 0; $return = $false; while ($retry -lt 3 -and $return -eq $false) {
    try {

      # Create command for SQL query
      $ob_command = ps_sql_command -ip_ob_sql_connection $ip_ob_sql_connection -ip_tx_sql $ip_tx_sql

      # Excute SQL Non Query Statement
      $result = $ob_command.ExecuteNonQuery()
      
      # All is Well
      if ($null -ne $result) { $return = $true } else { $return = $false }

    } catch { 
      
      # Set local variables
      $retry += 1;  

      # Extract Error
      if ($retry -ge 3) { ps_log_error -ip_fp_event_log $Global:fp_event_log -ip_tx_sql_statement $ip_tx_sql }
      else {
    
        # Close connection if still open
        if ($ip_ob_sql_connection -and $ob_ip_ob_sql_connectionconnection.State -eq 'Open') { $ip_ob_sql_connection.Close() }
        $ip_ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database "DBC"

      }        
    }

  }
  return $return
}

function ps_remove_comments {
    <#
      .SYNOPSIS
      Removes SQL comments from a SQL statement.
      
      .DESCRIPTION
      Removes both single-line (--) and multi-line (/* */) comments from SQL text.
      Preserves comments that are inside quoted strings.
      
      .PARAMETER SqlText
      The SQL statement containing comments to be removed.
      
      .EXAMPLE
      $sql = @"
      CREATE TABLE test (
          -- This is a comment
          id INT NOT NULL,
          name VARCHAR(50) /* another comment */
      );
      "@
      Remove-SqlComments -SqlText $sql
    #>
    
    param(
      [Parameter(Mandatory=$true)] [string]$ip_tx_sql_statement
    )
    
    # Remove multi-line comments /* ... */
    $ip_tx_sql_statement = $ip_tx_sql_statement -replace '/\*[\s\S]*?\*/', ''
    
    # Split into lines to handle single-line comments
    $lines = $ip_tx_sql_statement -split "`n"
    $cleanedLines = @()
    
    foreach ($line in $lines) {
        $inQuote = $false
        $quoteChar = $null
        $commentPos = -1
        
        # Find position of -- that's not inside quotes
        for ($i = 0; $i -lt $line.Length - 1; $i++) {
            $char = $line[$i]
            
            if ($char -eq "'" -or $char -eq '"') {
                if (-not $inQuote) {
                    $inQuote = $true
                    $quoteChar = $char
                } elseif ($char -eq $quoteChar) {
                    $inQuote = $false
                    $quoteChar = $null
                }
            } elseif ($char -eq '-' -and $line[$i + 1] -eq '-' -and -not $inQuote) {
                $commentPos = $i
                break
            }
        }
        
        # Remove comment portion
        if ($commentPos -ge 0) {
            $line = $line.Substring(0, $commentPos)
        }
        
        # Only add non-empty lines or lines with actual content
        $trimmedLine = $line.Trim()
        if ($trimmedLine -ne '') {
            $cleanedLines += $line
        }
    }
    
    # Join lines back together
    $result = $cleanedLines -join "`n"
    
    # Remove excessive blank lines
    $result = $result -replace "`n\s*`n\s*`n", "`n`n"
    
    return $result.Trim()
}

function ps_minify_sql {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$SqlQuery,
        
        [switch]$PreserveComments,
        [switch]$KeepNewlinesAfterKeywords
    )

    <# Example usage:

      $sqlExample = @"
      SELECT 
          customer.customer_id,
          customer.first_name, -- Customer's first name
          customer.last_name,
          orders.order_date
      FROM 
          customers customer
          INNER JOIN orders ON customer.customer_id = orders.customer_id
      WHERE 
          customer.active = 1
          AND orders.order_date >= '2023-01-01'
          /* This is a multi-line
             comment that should be removed */
      ORDER BY 
          orders.order_date DESC;
      "@
      
      Write-Host "Original SQL:"
      Write-Host $sqlExample
      Write-Host "`n" + "="*50
      
      Write-Host "`nMinified SQL (default):"
      $minified = ps_minify_sql -SqlQuery $sqlExample
      Write-Host $minified
      
      Write-Host "`nMinified SQL (with keywords on new lines):"
      $minifiedWithNewlines = ps_minify_sql -SqlQuery $sqlExample -KeepNewlinesAfterKeywords
      Write-Host $minifiedWithNewlines
      
      Write-Host "`nUltra-compact minified SQL:"
      $ultraCompact = ps_minify_sql -SqlQuery $sqlExample
      Write-Host $ultraCompact
      
      Write-Host "`nMinified SQL (preserving comments):"
      $withComments = ps_minify_sql -SqlQuery $sqlExample -PreserveComments
      Write-Host $withComments

    #>

    # Remove single-line comments (-- comments) unless preserving comments
    if (-not $PreserveComments) {
        $SqlQuery = $SqlQuery -replace '--.*$', ''
    }
    
    # Remove multi-line comments (/* comments */) unless preserving comments
    if (-not $PreserveComments) {
        $SqlQuery = $SqlQuery -replace '/\*[\s\S]*?\*/', ''
    }

    # Remove extra whitespace and normalize line breaks
    $SqlQuery = $SqlQuery -replace '\r\n', ' '
    $SqlQuery = $SqlQuery -replace '\n', ' '
    $SqlQuery = $SqlQuery -replace '\r', ' '
    
    # Replace multiple spaces with single space
    $SqlQuery = $SqlQuery -replace '\s+', ' '
    
    # Remove spaces around operators and punctuation
    $SqlQuery = $SqlQuery -replace '\s*([()=<>!,;])\s*', '$1'
    
    # Remove spaces around specific operators
    $SqlQuery = $SqlQuery -replace '\s*(>=|<=|!=|<>)\s*', '$1'
    
    # Add space after commas for readability
    $SqlQuery = $SqlQuery -replace ',', ', '
    
    # Handle string literals - preserve spaces within quotes
    $stringPattern = '''([^'']|'''')*'''
    $strings = @()
    $index = 0
    
    # Extract string literals
    $SqlQuery = [regex]::Replace($SqlQuery, $stringPattern, {
        param($match)
        $placeholder = "___STRING_PLACEHOLDER_$index___"
        $strings += @{ Index = $index; Value = $match.Value }
        $index++
        return $placeholder
    })
    
    # Optional: Keep newlines after major keywords for better readability
    if ($KeepNewlinesAfterKeywords) {
        $keywords = @('SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL JOIN', 
                     'GROUP BY', 'ORDER BY', 'HAVING', 'UNION', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER', 'DROP')
        
        foreach ($keyword in $keywords) {
            $SqlQuery = $SqlQuery -replace "\b$keyword\b", "`n$keyword"
        }
    }
    
    # Restore string literals
    foreach ($stringInfo in $strings) {
        $placeholder = "___STRING_PLACEHOLDER_$($stringInfo.Index)___"
        $SqlQuery = $SqlQuery -replace [regex]::Escape($placeholder), $stringInfo.Value
    }
    
    # Final cleanup
    $SqlQuery = $SqlQuery.Trim()
    
    return $SqlQuery
}

function ps_log_error { param(
    [Parameter(Mandatory=$true)] [string]$ip_fp_event_log,
    [Parameter(Mandatory=$true)] [string]$ip_tx_sql_statement,
    [switch]$ip_feedback
  )  
    $tx_error  = "!!!" + "!" * 80
    $tx_error += "`n$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    $tx_error += "`n$($_.Exception.Message)"               # -> Error message
    $tx_error += "`n$($_.Exception.GetType().FullName)"    # -> Error type
    $tx_error += "`n$($_.ScriptStackTrace)"                # -> Stack trace
    $tx_error += "`n$($_.InvocationInfo.ScriptLineNumber)" # -> Line number where error occurred
    $tx_error += "`nSQL:`n$ip_tx_sql_statement"
    $tx_error += "!!!" + "!" * 80
    $tx_error | Out-File -FilePath "$ip_fp_event_log" -Append -Encoding UTF8  
    if ($ip_feedback) { Write-Host $tx_error}
}

function ps_get_sql_statements { param(
    [Parameter(Mandatory=$true)] [string]$ip_fp_build
  )
  try {

    # Check if file exists
    if (-not (Test-Path $ip_fp_build)) { throw "Build file not found: $ip_fp_build" }
    
    # Fetch all SQL files form Build-folder
    $files = Get-ChildItem -Path $ip_fp_build -Filter "*.sql" -Recurse -File

    # Load all Statement into Collection
    $statements = foreach ($file in $files) {

      # Read the entire file content
      [PSCustomObject]@{
        tx_sql   = Get-Content -Path $file.FullName -Raw
        fp_build = $file.BaseName
      }
    
    }

    Write-Host "Found $($statements.Count) SQL statements in build file" -ForegroundColor Green
    return $statements

  }
  catch { Write-Error "Error reading SQL statements from file: $_"; return @() }
}

function ps_exec_sql_query_to_file { 
  param(
    [Parameter(Mandatory=$true)] $ip_ob_sql_connection,
    [Parameter(Mandatory=$true)] $ip_tx_sql,
    [Parameter(Mandatory=$true)] $ip_nm_dsn,
    [Parameter(Mandatory=$true)]  [string]$ip_output_file,
    [Parameter(Mandatory=$false)] [string]$ip_delimiter = "|",
    [Parameter(Mandatory=$false)] [string]$ip_encoding = "UTF8",
    [Parameter(Mandatory=$false)] [bool]$ip_include_headers = $true,
    [Parameter(Mandatory=$false)] [bool]$ip_add_row_number = $true
  )
  
  $ob_command = $null
  $ob_reader = $null
  $streamWriter = $null
  
  try { 
    $retry = 0
    $success = $false
    
    while ($retry -lt 3 -and $success -eq $false) {
      try {
        # Ensure output directory exists
        $outputDir = Split-Path -Path $ip_output_file -Parent
        if ($outputDir -and !(Test-Path $outputDir)) {
          New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Create command for SQL query
        $ob_command = ps_sql_command -ip_ob_sql_connection $ip_ob_sql_connection -ip_tx_sql $ip_tx_sql
        
        # Execute query and get DataReader
        Write-Host "Executing SQL query (streaming to file): $ip_output_file" -ForegroundColor DarkYellow
        $ob_reader = $ob_command.ExecuteReader()
        
        # Create StreamWriter for efficient file writing
        $streamWriter = New-Object System.IO.StreamWriter($ip_output_file, $false, [System.Text.Encoding]::$ip_encoding)
        
        # Get column names
        $columnNames = @()
        for ($i = 0; $i -lt $ob_reader.FieldCount; $i++) {
          $columnNames += $ob_reader.GetName($i)
        }
        
        # Write headers if requested
        if ($ip_include_headers) {
          $headerLine = $columnNames -join $ip_delimiter
          $streamWriter.WriteLine($headerLine)
        }
        
        # Stream through results row by row
        $rowCount = -1; while ($ob_reader.Read()) { $rowCount++; $values = @()
          
          for ($i = 0; $i -lt $ob_reader.FieldCount; $i++) {
            if ($ob_reader.IsDBNull($i)) {
              $values += ""
            } else {
              $value = $ob_reader.GetValue($i).ToString()
              # Escape delimiter if it appears in the data
              #if ($value.Contains($ip_delimiter)) {$value = '"' + $value.Replace('"', '""') + '"' }
              $values += $value
            }
          }

          # Add Rownumber to Records
          if ($true -eq $ip_add_row_number) { $values = if ($rowCount -gt 0) { "$rowCount;$values" } else { $values } }

          # Add Linenew CRLF values
          $line = "$values`r`n"

          #$streamWriter.WriteLine($line)
          $streamWriter.Write($line)
          
          # Progress indicator
          if ($rowCount % 10000 -eq 0) {
            Write-Host "Processed $rowCount rows..." -ForegroundColor Cyan
            $streamWriter.Flush()  # Flush to disk periodically
          }
        }
        
        Write-Host "Total rows written to file: $rowCount" -ForegroundColor Green
        Write-Host "Output file: $ip_output_file" -ForegroundColor Green
        $success = $true
        
      }
      catch {
        $retry += 1
        
        # Close reader, writer and connection if still open
        if ($streamWriter) { $streamWriter.Close(); $streamWriter.Dispose(); $streamWriter = $null }
        if ($ob_reader -and -not $ob_reader.IsClosed) { $ob_reader.Close() }
        if ($ip_ob_sql_connection -and $ip_ob_sql_connection.State -eq 'Open') { $ip_ob_sql_connection.Close() }
        
        if ($retry -lt 3) {
          Write-Host "Retry attempt $retry after error..." -ForegroundColor Yellow
          Start-Sleep -Seconds ($retry * 2)
          $ip_ob_sql_connection = ps_sql_connection -ip_nm_dsn $ip_nm_dsn -ip_nm_database "DBC"
        } else {
          throw
        }
      }
    }
    
  } 
  catch {
    # Close connection if still open
    if ($streamWriter) { $streamWriter.Close(); $streamWriter.Dispose() }
    if ($ob_reader -and -not $ob_reader.IsClosed) { $ob_reader.Close() }
    if ($ip_ob_sql_connection -and $ip_ob_sql_connection.State -eq 'Open') { $ip_ob_sql_connection.Close() }
    
    # Extract Error
    $tx_error  = "Error message: $($_.Exception.Message)"
    $tx_error += "`nFull error details: $($_.Exception)"
    $tx_error += "`nSQL Statement: `n$ip_tx_sql"
    Write-Host $tx_error -ForegroundColor DarkRed
    
    # Delete partially written file if error occurred
    if (Test-Path $ip_output_file) {
      Write-Host "Removing partially written file..." -ForegroundColor Yellow
      Remove-Item $ip_output_file -Force
    }
    
    throw
    
  } 
  finally {
    # Clean up objects
    if ($streamWriter) { $streamWriter.Close(); $streamWriter.Dispose() }
    if ($ob_reader -and -not $ob_reader.IsClosed) { $ob_reader.Close(); $ob_reader.Dispose() }
    if ($ob_command) { $ob_command.Dispose() }
    
    # Clear sensitive variables from memory
    [System.GC]::Collect()
  }
}

function ps_get_table_def_from_sql_statement { param(
    [Parameter(Mandatory=$true)] $ip_tx_sql_statement,
    [Parameter(Mandatory=$true)] $ip_nm_database,
    [Parameter(Mandatory=$true)] $ip_nm_schema,
    [Parameter(Mandatory=$true)] $ip_nm_table
  ) try {
        
    # Extract table name and schema
    $ob_table = [cl_table]::new()
    $ob_table.Database   = $ip_nm_database
    $ob_table.SchemaName = $ip_nm_schema
    $ob_table.TableName  = $ip_nm_table
        
    # Extract column definitions
    $columnPattern = '\[?(\w+)\]?\s+([A-Z]+(?:\([^)]+\))?)\s*(NOT\s+NULL|NULL)?\s*(?:DEFAULT\s+([^,\s]+))?(?:,|\s*\))'
    $matches = [regex]::Matches($ip_tx_sql_statement, $columnPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    $position = 1; foreach ($match in $matches) {

        $ob_column = [cl_column]::new()
        $ob_column.ColumnName = $match.Groups[1].Value
        $ob_column.OrdinalPosition = $position++
        
        # Parse data type
        $dataTypeInfo = $match.Groups[2].Value
        if ($dataTypeInfo -match '([A-Z]+)(?:\(([^)]+)\))?') {
            $ob_column.DataType = $matches[1].ToUpper()
            
            # Parse length/precision/scale
            if ($matches[2]) {
                $params = $matches[2] -split ','
                if ($params.Count -eq 1) {
                    if ($ob_column.DataType -in @('VARCHAR', 'CHAR', 'NVARCHAR', 'NCHAR')) {
                        $ob_column.MaxLength = [int]$params[0]
                    } else {
                        $ob_column.Precision = [int]$params[0]
                    }
                } elseif ($params.Count -eq 2) {
                    $ob_column.Precision = [int]$params[0]
                    $ob_column.Scale = [int]$params[1]
                }
            }
        }

        # Build complete DDL-ready data type with length/precision/scale
        if ($ob_column.DataType -eq "VARCHAR" -or $ob_column.DataType -eq "CHAR" -or $ob_column.DataType -eq "DEC") { 

          # Combine Datatype information so it is DDL useable
          $ddlDataType = $ob_column.DataType
          
          # Add length/precision/scale parameters where applicable
          if ($ob_column.MaxLength-gt 0 -and $ob_column.DataType -ne "DEC") {

              # For string types with length
              $ddlDataType += "($($ob_column.MaxLength))"

          } elseif ($ob_column.Precision -gt 0 -and $ob_column.Scale -gt 0) { 

              # For numeric types with precision and scale
              $ddlDataType += "($($ob_column.Precision),$($ob_column.Scale))"

          } elseif ($ob_column.Precision -gt 0) {

              # For types with only precision (like DECIMAL(10) or FLOAT(53))
              $ddlDataType += "($($ob_column.Precision))"

          }
          
          # Store the DDL-ready data type
          $ob_column.DataType = $ddlDataType

        }
        
        # Parse nullable
        $nullable = $match.Groups[3].Value
        $ob_column.IsNullable = -not ($nullable -eq "NOT NULL")
        
        # Parse default value
        if ($match.Groups[4].Success) {
            $ob_column.DefaultValue = $match.Groups[4].Value
        }
        
        $ob_table.Columns.Add($ob_column) | Out-Null
    }
    
    # All Done
    return $ob_table

  } catch { throw }
}

function ps_get_table_def_from_sql_database { param(
        [Parameter(Mandatory=$true)] $ip_ob_sql_connection,
        [Parameter(Mandatory=$true)] $ip_nm_database,
        [Parameter(Mandatory=$true)] $ip_nm_schema,
        [Parameter(Mandatory=$true)] $ip_nm_table,
        [Parameter(Mandatory=$true)] $ip_nm_dsn
    ) 
    Try {
        # Build SQL Statement for extraction of Table Definition from Teradata
        $DatabaseNameTableName = "$($ip_nm_database)$($ip_nm_schema)_$($ip_nm_table)"
        $tx_sql  = ""
        $tx_sql += "SELECT"
        $tx_sql += "`n  TRIM(ColumnName) AS ""COLUMN_NAME"","
        $tx_sql += "`n  CASE"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'I'  THEN 'INT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'I1' THEN 'BYTEINT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'I2' THEN 'SMALLINT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'I8' THEN 'BIGINT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'D'  THEN 'DEC'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'F'  THEN 'FLOAT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'CF' THEN 'CHAR'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'CV' THEN 'VARCHAR'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'CO' THEN 'CLOB'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'BF' THEN 'BYTE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'BV' THEN 'VARBYTE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'BO' THEN 'BLOB'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'DA' THEN 'DATE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'TS' THEN 'TIMESTAMP'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'TZ' THEN 'TIMESTAMP WITH TIME ZONE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'AT' THEN 'TIME'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'SZ' THEN 'TIME WITH TIME ZONE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'YM' THEN 'INTERVAL YEAR TO MONTH'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'YR' THEN 'INTERVAL YEAR'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'MO' THEN 'INTERVAL MONTH'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'DY' THEN 'INTERVAL DAY'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'DH' THEN 'INTERVAL DAY TO HOUR'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'DM' THEN 'INTERVAL DAY TO MINUTE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'DS' THEN 'INTERVAL DAY TO SECOND'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'HR' THEN 'INTERVAL HOUR'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'HM' THEN 'INTERVAL HOUR TO MINUTE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'HS' THEN 'INTERVAL HOUR TO SECOND'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'MI' THEN 'INTERVAL MINUTE'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'MS' THEN 'INTERVAL MINUTE TO SECOND'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'SC' THEN 'INTERVAL SECOND'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'N'  THEN 'NUMBER'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'A1' THEN 'ARRAY'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'AN' THEN 'MULTI-DIMENSIONAL ARRAY'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'UT' THEN 'UDT'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'XM' THEN 'XML'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'JN' THEN 'JSON'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'GE' THEN 'GEOMETRY'"
        $tx_sql += "`n    WHEN UPPER(TRIM(ColumnType)) = 'MG' THEN 'ST_GEOMETRY'"
        $tx_sql += "`n    ELSE TRIM(ColumnType)"
        $tx_sql += "`n  END AS ""DATA_TYPE"","
        $tx_sql += "`n  ColumnLength AS ""MAX_LENGTH"","
        $tx_sql += "`n  DecimalTotalDigits AS ""PRECISION"","
        $tx_sql += "`n  DecimalFractionalDigits AS ""SCALE"","
        $tx_sql += "`n  CASE WHEN UPPER(TRIM(Nullable)) = 'Y' THEN 1 ELSE 0 END AS ""IS_NULLABLE"","
        $tx_sql += "`n  TRIM(DefaultValue) AS ""COLUMN_DEFAULT"","
        $tx_sql += "`n  0 AS ""IS_IDENTITY"","
        $tx_sql += "`n  ColumnId AS ""ORDINAL_POSITION"""
        $tx_sql += "`nFROM DBC.ColumnsV"
        $tx_sql += "`nWHERE (TRIM(DatabaseName) || '.' || TRIM(TableName)) = '$DatabaseNameTableName'"
        $tx_sql += "`nORDER BY DatabaseName ASC, TableName ASC, ColumnId ASC"
        #Write-Host "`n$tx_sql`n"

        # Execute SQL Statement
        $rows = ps_exec_sql_query_statement -ip_ob_sql_connection $ip_ob_sql_connection -ip_tx_sql $tx_sql -ip_nm_dsn $ip_nm_dsn

        # Load Table Definition
        $ob_table = [cl_table]::new()
        $ob_table.Database   = $ip_nm_database
        $ob_table.SchemaName = $ip_nm_schema
        $ob_table.TableName  = $ip_nm_table
        
        # Load Column Definitions
        foreach ($row in $rows) {

            $ob_column = [cl_column]::new()
            $ob_column.ColumnName      = $row["COLUMN_NAME"].ToString()
            
            # Get the base data type
            $baseDataType = $row["DATA_TYPE"].ToString()
            $maxLength = if ($row["MAX_LENGTH"] -is [DBNull]) { 0 } else { [int]$row["MAX_LENGTH"] }
            $precision = if ($row["PRECISION"]  -is [DBNull]) { 0 } else { [int]$row["PRECISION"] }
            $scale     = if ($row["SCALE"]      -is [DBNull]) { 0 } else { [int]$row["SCALE"] }
            
            # Build complete DDL-ready data type with length/precision/scale
            $ddlDataType = switch ($baseDataType) {
                "INTEGER" { 
                   "INT"
                }
                "DECIMAL" { 
                    if ($precision -gt 0 -and $scale -gt 0) { "DEC($precision,$scale)" }
                    elseif ($precision -gt 0) { "DEC($precision)" }
                    else { "DEC" }
                }
                "DEC" { 
                    if ($precision -gt 0 -and $scale -gt 0) { "DEC($precision,$scale)" }
                    elseif ($precision -gt 0) { "DEC($precision)" }
                    else { "DEC" }
                }
                "CHAR" { 
                    if ($maxLength -gt 0) { "CHAR($maxLength)" }
                    else { "CHAR" }
                }
                "VARCHAR" { 
                    if ($maxLength -gt 0) { "VARCHAR($maxLength)" }
                    else { "VARCHAR" }
                }
                "BYTE" { 
                    if ($maxLength -gt 0) { "BYTE($maxLength)" }
                    else { "BYTE" }
                }
                "VARBYTE" { 
                    if ($maxLength -gt 0) { "VARBYTE($maxLength)" } else { "VARBYTE" }
                }
                #"TIMESTAMP" {
                #    if ($scale -gt 0) { "TIMESTAMP($scale)" } else { "TIMESTAMP" }
                #}
                #"TIME" {
                #    if ($scale -gt 0) { "TIME($scale)" }
                #    else { "TIME" }
                #}
                default { $baseDataType }
            }
            
            # Override MaxLength
            if ($ddlDataType                -eq "BIGINT") { $maxLength = 0 }
            if ($ddlDataType.Substring(0,3) -eq "DEC") {    $maxLength = 0 }

            # populate Column-object
            $ob_column.DataType        = $ddlDataType
            $ob_column.MaxLength       = $maxLength
            $ob_column.Precision       = $precision
            $ob_column.Scale           = $scale
            $ob_column.IsNullable      = [bool]$row["IS_NULLABLE"]
            $ob_column.DefaultValue    = if ($row["COLUMN_DEFAULT"] -is [DBNull]) { "" } else { $row["COLUMN_DEFAULT"].ToString() }
            if ($ob_column.DefaultValue -eq "Current TimeStamp(6)") {$ob_column.DefaultValue = "CURRENT_TIMESTAMP" }
            $ob_column.IsIdentity      = [bool]$row["IS_IDENTITY"]
            $ob_column.OrdinalPosition = [int]$row["ORDINAL_POSITION"]
            $ob_table.Columns.Add($ob_column) | Out-Null

        }
        
        # All Done
        return $ob_table
        
    } catch { 
        throw 
    }
}

function ps_generate_table_alter_script { param(
    [Parameter(Mandatory=$true)] $ip_ob_table_db,
    [Parameter(Mandatory=$true)] $ip_ob_table_tx,
    [Parameter(Mandatory=$true)] $ip_nm_database_target,
    [Parameter(Mandatory=$true)] $ip_nm_schema,
    [Parameter(Mandatory=$true)] $ip_nm_table,
    [Parameter(Mandatory=$true)] $ip_ni_build,
    [Parameter(Mandatory=$true)] $ip_fp_build
  ) try {

    # Set Various Variables
    $emp             = ""
    $nwl             = "`n"
    $tx_sql_create   = $ip_ob_table_tx.tx_object
    $nm_table_target = "$($ip_nm_database_target)$($ip_nm_schema)_$($ip_nm_table)"
    $nm_table_rename = "$($nm_table_target)_renamed"
    $ls_column       = ""; foreach ($c in $ip_ob_table_tx.ob_table.Columns) { $comma = if ($ls_column -eq "") { "" } else { "," }; $ls_column += "$($comma) $($c.ColumnName)" }
    $ls_select       = ""; foreach ($c in $ip_ob_table_tx.ob_table.Columns) {
      
      # Determine if 1st column if not add "comma" and  "newline"
      $comma = $(if ($ls_select -eq "") { "" } else { "," }) +"`n";
      
      # if the column is "new" the default value must be used if NOT nullable
      $e = $ip_ob_table_db.ob_table.Columns | Where-Object { $_.ColumnName -eq $c.ColumnName }

      if ( $null -ne $e ) { # Column existed, so CAST with "new" datatype

        # Check if Datatype Are equal
        if ($c.Datatype -eq $e.Datatype) { $value = "src.$($c.ColumnName)" } else { # --> Datatypes are not Equal !!!
          
          # Assesment of Conversion
          $ob_source_datatype = [PSCustomObject]@{
            datatype  = $e.Datatype
            maxlength = $e.MaxLength
            precision = $e.precision
            scale     = $e.scale
          }
          $ob_target_datatype = [PSCustomObject]@{
            datatype  = $c.Datatype
            maxlength = $c.MaxLength
            precision = $c.precision
            scale     = $c.scale
          }

          # assesment of Conversion
          $conversion = ps_assesment_of_conversion -ip_source_datatype $ob_source_datatype  -ip_target_datatype $ob_target_datatype
          if ($false -eq $conversion.IsAllowed) { throw $conversion.Recommendation }

          # Conversion Seems to be Allowed or is of low risk
          $value = "CAST(src.$($c.ColumnName) AS $($c.DataType)) AS $($c.ColumnName)"

        }
        
      } 
      else { # Column is New
        if ($true -eq $c.IsNullable) { $value = "CAST(NULL AS $($c.DataType)) AS $($c.ColumnName)" }
        else { # is not NULLABLE use default value
          if ($null -eq $c.DefaultValue) { throw "Column ``$($c.ColumnName)`` is NOT Nullable and has NO ``DEFAULT`` Assigned!!!" }
          else { $value = "CAST($($c.DefaultValue) AS $($c.DataType)) AS $($c.ColumnName)" }
        }
        
      }

      # Extrent the SELECT-Clause "new"-column value
      $ls_select += "$($comma)  $($value)"

    }

    $tx_sql = "RENAME TABLE $nm_table_target TO $nm_table_rename;"
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-A-Rename-$nm_table_target-to-$nm_table_rename.sql" -Encoding UTF8 
    
    $tx_sql = $tx_sql_create
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-B-(Re)deploy-$nm_table_target.sql" -Encoding UTF8 

    $tx_sql  = $emp + "INSERT INTO $nm_table_target ( $ls_column )"
    $tx_sql += $nwl + "SELECT" + $ls_select
    $tx_sql += $nwl + "FROM $nm_table_rename AS src;"
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-C-Load-existing-Data-into-$nm_table_target.sql" -Encoding UTF8 
    
    $tx_sql = "DROP TABLE $nm_table_rename;" 
    $tx_sql | Out-File -FilePath "$ip_fp_build\$($ip_ni_build.ToString("000"))-D-Drop-Renamed-Table-$nm_table_rename.sql" -Encoding UTF8 

  }
  catch {
    $tx_error  = "!!!" + "!" * 80
    $tx_error += "Failed to Generate alter script for ``$ip_nm_schema``_``$ip_nm_table``!!"
    $tx_error += "`n$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    $tx_error += "`n$($_.Exception.Message)"               # -> Error message
    $tx_error += "`n$($_.Exception.GetType().FullName)"    # -> Error type
    $tx_error += "`n$($_.ScriptStackTrace)"                # -> Stack trace
    $tx_error += "`n$($_.InvocationInfo.ScriptLineNumber)" # -> Line number where error occurred
    $tx_error += "`nSQL:`n$tx_sql"
    $tx_error += "!!!" + "!" * 80
    Write-Host $tx_error -BackgroundColor White -ForegroundColor DarkRed
  }
}

function ps_assesment_of_conversion { [CmdletBinding()] param(
    [Parameter(Mandatory = $true)] $ip_source_datatype,
    [Parameter(Mandatory = $true)] $ip_target_datatype
  )
  
    <#
      .SYNOPSIS
          Determines if a SQL column datatype conversion is allowed and likely to succeed.
      
      .DESCRIPTION
          Evaluates whether converting from one SQL datatype to another is safe and supported.
          Handles precision and scale for numeric types, length for string types, and precision for datetime types.
      
      .PARAMETER SourceDataType
          The current datatype of the column
      
      .PARAMETER TargetDataType
          The desired datatype to convert to
      
      .PARAMETER SourceLength
          Optional. The current length/size (for varchar, nvarchar, char, nchar, binary, varbinary)
      
      .PARAMETER TargetLength
          Optional. The target length/size
      
      .PARAMETER SourcePrecision
          Optional. The current precision (for decimal, numeric, datetime2, datetimeoffset, time)
      
      .PARAMETER TargetPrecision
          Optional. The target precision
      
      .PARAMETER SourceScale
          Optional. The current scale (for decimal, numeric)
      
      .PARAMETER TargetScale
          Optional. The target scale
      
      .EXAMPLE
          Test-SqlDatatypeConversion -SourceDataType "decimal" -TargetDataType "decimal" -SourcePrecision 18 -SourceScale 2 -TargetPrecision 10 -TargetScale 2
      
      .EXAMPLE
          Test-SqlDatatypeConversion -SourceDataType "decimal" -TargetDataType "int" -SourcePrecision 18 -SourceScale 4
      
      .EXAMPLE
          Test-SqlDatatypeConversion -SourceDataType "datetime2" -TargetDataType "datetime2" -SourcePrecision 7 -TargetPrecision 3
    #>

    # Extraction of Parameters
    $SourceDataType  = $ip_source_datatype.Datatype
    $SourceLength    = $ip_source_datatype.maxlength
    $SourcePrecision = $ip_source_datatype.precision
    $SourceScale     = $ip_source_datatype.scale
    $TargetDataType  = $ip_target_datatype.Datatype
    $TargetLength    = $ip_target_datatype.maxlength
    $TargetPrecision = $ip_target_datatype.precision
    $TargetScale     = $ip_target_datatype.scale

    # Strip Datatype of length, precision and/or scale info
    $SourceDataType = $($SourceDataType.Split("(")[0]).trim()
    $TargetDataType = $($TargetDataType.Split("(")[0]).trim()

    # Normalize datatypes to lowercase
    $source = $SourceDataType.ToLower().Trim()
    $target = $TargetDataType.ToLower().Trim()
    
    # Define datatype categories
    $numericTypes = @('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney')
    $precisionScaleTypes = @('decimal', 'numeric')
    $precisionTypes = @('datetime2', 'datetimeoffset', 'time')
    $lengthTypes = @('varchar', 'nvarchar', 'char', 'nchar', 'binary', 'varbinary')
    $stringTypes = @('varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext')
    $dateTypes = @('datetime', 'datetime2', 'date', 'time', 'smalldatetime', 'datetimeoffset', 'timestamp')
    $binaryTypes = @('binary', 'varbinary', 'image')
    
    # Define default precision/scale values for SQL datatypes
    $defaultPrecisionScale = @{
        'decimal' = @{Precision=18; Scale=0; Max=38}
        'numeric' = @{Precision=18; Scale=0; Max=38}
        'datetime2' = @{Precision=7; Max=7}
        'datetimeoffset' = @{Precision=7; Max=7}
        'time' = @{Precision=7; Max=7}
        'float' = @{Precision=53}
        'real' = @{Precision=24}
    }
    
    # Define numeric type ranges and precision
    $numericRanges = @{
        'tinyint' = @{Min=0; Max=255; Precision=3; Scale=0}
        'smallint' = @{Min=-32768; Max=32767; Precision=5; Scale=0}
        'int' = @{Min=-2147483648; Max=2147483647; Precision=10; Scale=0}
        'bigint' = @{Min=[Int64]::MinValue; Max=[Int64]::MaxValue; Precision=19; Scale=0}
        'money' = @{Precision=19; Scale=4}
        'smallmoney' = @{Precision=10; Scale=4}
    }
    
    # Initialize result object
    $result = [PSCustomObject]@{
        IsAllowed = $false
        ConversionType = ''
        RiskLevel = ''
        RequiresDataValidation = $false
        PotentialIssues = @()
        Recommendation = ''
        PrecisionScaleCheck = $null
        LengthCheck = $null
        SourceDefinition = ''
        TargetDefinition = ''
    }
    
    # Build source definition string
    $result.SourceDefinition = Get-DatatypeDefinition -DataType $source -Length $SourceLength -Precision $SourcePrecision -Scale $SourceScale
    $result.TargetDefinition = Get-DatatypeDefinition -DataType $target -Length $TargetLength -Precision $TargetPrecision -Scale $TargetScale
    
    # Apply defaults if not specified
    if ($precisionScaleTypes -contains $source -and -not $SourcePrecision) {
        $SourcePrecision = $defaultPrecisionScale[$source].Precision
        $SourceScale = if (-not $SourceScale) { $defaultPrecisionScale[$source].Scale } else { $SourceScale }
    }
    
    if ($precisionScaleTypes -contains $target -and -not $TargetPrecision) {
        $TargetPrecision = $defaultPrecisionScale[$target].Precision
        $TargetScale = if (-not $TargetScale) { $defaultPrecisionScale[$target].Scale } else { $TargetScale }
    }
    
    if ($precisionTypes -contains $source -and -not $SourcePrecision) {
        $SourcePrecision = $defaultPrecisionScale[$source].Precision
    }
    
    if ($precisionTypes -contains $target -and -not $TargetPrecision) {
        $TargetPrecision = $defaultPrecisionScale[$target].Precision}
    
    # Check if same datatype
    if ($source -eq $target) {
        $result.IsAllowed = $true
        $result.ConversionType = 'SameType'
        $result.RiskLevel = 'None'
        $result.Recommendation = 'No conversion needed - datatypes are identical.'
        
        # Check precision/scale for decimal/numeric types
        if ($precisionScaleTypes -contains $source) {
            $precisionScaleResult = Test-PrecisionScaleChange -SourcePrecision $SourcePrecision -SourceScale $SourceScale `
                                                              -TargetPrecision $TargetPrecision -TargetScale $TargetScale `
                                                              -DataType $source
            
            $result.PrecisionScaleCheck = $precisionScaleResult.Status
            $result.RiskLevel = $precisionScaleResult.RiskLevel
            $result.RequiresDataValidation = $precisionScaleResult.RequiresValidation
            
            if ($precisionScaleResult.Issues.Count -gt 0) {
                $result.PotentialIssues += $precisionScaleResult.Issues
            }
            
            if ($precisionScaleResult.RiskLevel -ne 'None') {
                $result.Recommendation = $precisionScaleResult.Recommendation
            }
        }
        
        # Check precision for datetime types
        if ($precisionTypes -contains $source) {
            $precisionResult = Test-PrecisionChange -SourcePrecision $SourcePrecision -TargetPrecision $TargetPrecision -DataType $source
            
            $result.PrecisionScaleCheck = $precisionResult.Status
            $result.RiskLevel = $precisionResult.RiskLevel
            $result.RequiresDataValidation = $precisionResult.RequiresValidation
            
            if ($precisionResult.Issues.Count -gt 0) {
                $result.PotentialIssues += $precisionResult.Issues
            }
        }
        
        # Check length change for string/binary types
        if ($lengthTypes -contains $source) {
            if ($SourceLength -and $TargetLength) {
                if ($TargetLength -lt $SourceLength) {
                    $result.RiskLevel = 'Medium'
                    $result.RequiresDataValidation = $true
                    $result.PotentialIssues += "Reducing length from $SourceLength to $TargetLength may cause data truncation."
                    $result.LengthCheck = 'Truncation Risk'
                    $result.Recommendation = "Validate that no data exceeds the new length of $TargetLength before converting."
                } elseif ($TargetLength -gt $SourceLength) {
                    $result.LengthCheck = 'Safe - Expanding'
                } else {
                    $result.LengthCheck = 'No Change'
                }
            } elseif ($TargetLength -eq -1 -or ($target -like '*max*')) {
                $result.LengthCheck = 'Safe - Converting to MAX'
            }
        }
        
        return $result
    }
    
    # Define safe conversions with precision/scale considerations
    $safeConversions = @{
        'tinyint' = @('smallint', 'int', 'bigint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney', 'varchar', 'nvarchar', 'char', 'nchar')
        'smallint' = @('int', 'bigint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney', 'varchar', 'nvarchar', 'char', 'nchar')
        'int' = @('bigint', 'decimal', 'numeric', 'float', 'real', 'money', 'varchar', 'nvarchar', 'char', 'nchar')
        'bigint' = @('decimal', 'numeric', 'float', 'real', 'varchar', 'nvarchar', 'char', 'nchar')
        'decimal' = @('float', 'real', 'varchar', 'nvarchar', 'char', 'nchar', 'numeric')
        'numeric' = @('float', 'real', 'varchar', 'nvarchar', 'char', 'nchar', 'decimal')
        'float' = @('real', 'varchar', 'nvarchar', 'char', 'nchar')
        'real' = @('float', 'varchar', 'nvarchar', 'char', 'nchar')
        'money' = @('varchar', 'nvarchar', 'char', 'nchar', 'decimal', 'numeric')
        'smallmoney' = @('money', 'varchar', 'nvarchar', 'char', 'nchar', 'decimal', 'numeric')
        
        'varchar' = @('nvarchar', 'text', 'ntext')
        'char' = @('varchar', 'nchar', 'nvarchar', 'text', 'ntext')
        'nchar' = @('nvarchar', 'ntext')
        'nvarchar' = @('ntext')
        'text' = @('ntext', 'varchar', 'nvarchar')
        
        'date' = @('timestamp', 'datetime', 'datetime2', 'varchar', 'nvarchar', 'char', 'nchar')
        'time' = @('timestamp', 'datetime2', 'varchar', 'nvarchar', 'char', 'nchar')
        'smalldatetime' = @('datetime', 'datetime2', 'varchar', 'nvarchar', 'char', 'nchar')
        'datetime' = @('datetime2', 'varchar', 'nvarchar', 'char', 'nchar')
        'datetime2' = @('varchar', 'nvarchar', 'char', 'nchar')
        'datetimeoffset' = @('datetime2', 'varchar', 'nvarchar', 'char', 'nchar')
        
        'binary' = @('varbinary', 'image')
        'varbinary' = @('image')
        
        'bit' = @('tinyint', 'smallint', 'int', 'bigint', 'varchar', 'nvarchar', 'char', 'nchar')
        'uniqueidentifier' = @('varchar', 'nvarchar', 'char', 'nchar')
    }
    
    # Define conversions with potential data loss
    $riskyConversions = @{
        'bigint' = @('int', 'smallint', 'tinyint', 'money', 'smallmoney', 'decimal', 'numeric')
        'int' = @('smallint', 'tinyint', 'smallmoney', 'decimal', 'numeric')
        'smallint' = @('tinyint', 'decimal', 'numeric')
        'float' = @('decimal', 'numeric', 'real', 'int', 'bigint', 'smallint', 'tinyint', 'money', 'smallmoney')
        'real' = @('decimal', 'numeric', 'int', 'bigint', 'smallint', 'tinyint', 'money', 'smallmoney')
        'decimal' = @('int', 'bigint', 'smallint', 'tinyint', 'money', 'smallmoney')
        'numeric' = @('int', 'bigint', 'smallint', 'tinyint', 'money', 'smallmoney')
        'money' = @('int', 'smallmoney', 'decimal', 'numeric')
        
        'nvarchar' = @('varchar', 'char', 'nchar')
        'nchar' = @('char', 'varchar')
        'ntext' = @('text', 'varchar', 'nvarchar')
        'varchar' = @('char', 'int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'datetime', 'datetime2', 'date', 'time')
        'char' = @('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'datetime', 'datetime2', 'date', 'time')
        
        'datetime' = @('date', 'time', 'smalldatetime')
        'datetime2' = @('datetime', 'date', 'time', 'smalldatetime')
        'datetimeoffset' = @('datetime', 'date', 'time', 'smalldatetime', 'datetime2')
        
        'varbinary' = @('binary')
        'image' = @('binary', 'varbinary')
    }
    
    # Check for safe conversions
    if ($safeConversions.ContainsKey($source) -and $safeConversions[$source] -contains $target) {
        $result.IsAllowed = $true
        $result.ConversionType = 'Safe'
        $result.RiskLevel = 'Low'
        $result.Recommendation = "Conversion from $($result.SourceDefinition) to $($result.TargetDefinition) is generally safe."
        
        # Special handling for decimal/numeric to decimal/numeric
        if ($precisionScaleTypes -contains $source -and $precisionScaleTypes -contains $target) {
            $precisionScaleResult = Test-PrecisionScaleChange -SourcePrecision $SourcePrecision -SourceScale $SourceScale `
                                                              -TargetPrecision $TargetPrecision -TargetScale $TargetScale `
                                                              -DataType $target
            
            $result.PrecisionScaleCheck = $precisionScaleResult.Status
            
            if ($precisionScaleResult.RiskLevel -ne 'None') {
                $result.RiskLevel = $precisionScaleResult.RiskLevel
                $result.RequiresDataValidation = $precisionScaleResult.RequiresValidation
                $result.PotentialIssues += $precisionScaleResult.Issues
                $result.Recommendation = $precisionScaleResult.Recommendation
            }
        }
        
        # Converting from integer to decimal/numeric - check if target can hold the values
        if ($numericRanges.ContainsKey($source) -and $precisionScaleTypes -contains $target) {
            $sourceMaxDigits = $numericRanges[$source].Precision
            $targetWholeDigits = $TargetPrecision - $TargetScale
            
            if ($targetWholeDigits -lt $sourceMaxDigits) {
                $result.RiskLevel = 'High'
                $result.RequiresDataValidation = $true
                $result.PotentialIssues += "Target decimal($TargetPrecision,$TargetScale) may not accommodate all $source values. Maximum $source needs $sourceMaxDigits digits, but target only allows $targetWholeDigits whole digits."
                $result.Recommendation = "Consider using decimal($($sourceMaxDigits + $TargetScale),$TargetScale) or higher to safely convert all $source values."
            }
        }
        
        # Converting from decimal/numeric to integer - check precision/scale
        if ($precisionScaleTypes -contains $source -and $numericRanges.ContainsKey($target)) {
            if ($SourceScale -gt 0) {
                $result.RiskLevel = 'High'
                $result.RequiresDataValidation = $true
                $result.PotentialIssues += "Source has scale of $SourceScale. Decimal places will be truncated when converting to $target."
            }
            
            $targetMaxDigits = $numericRanges[$target].Precision
            $sourceWholeDigits = $SourcePrecision - $SourceScale
            
            if ($sourceWholeDigits -gt $targetMaxDigits) {
                $result.RiskLevel = 'High'
                $result.RequiresDataValidation = $true
                $result.PotentialIssues += "Source can have up to $sourceWholeDigits whole digits, but $target can only hold up to $targetMaxDigits digits. Values may be out of range."
            }
        }
        
        # Check string length
        if ($stringTypes -contains $source -and $stringTypes -contains $target) {
            if ($SourceLength -and $TargetLength -and $TargetLength -lt $SourceLength) {
                $result.RiskLevel = 'Medium'
                $result.RequiresDataValidation = $true
                $result.PotentialIssues += "Target length ($TargetLength) is smaller than source length ($SourceLength). Data may be truncated."
                $result.LengthCheck = 'Truncation Risk'
            }
        }
        
        # Unicode consideration
        if ($source -eq 'nvarchar' -and $target -eq 'varchar') {
            $result.PotentialIssues += "Converting from nvarchar to varchar may lose Unicode characters."
            $result.RequiresDataValidation = $true
            $result.RiskLevel = 'Medium'
        }
        
        # DateTime precision check
        if ($precisionTypes -contains $source -and $precisionTypes -contains $target) {
            $precisionResult = Test-PrecisionChange -SourcePrecision $SourcePrecision -TargetPrecision $TargetPrecision -DataType $target
            
            $result.PrecisionScaleCheck = $precisionResult.Status
            
            if ($precisionResult.RiskLevel -ne 'None') {
                $result.RiskLevel = $precisionResult.RiskLevel
                $result.RequiresDataValidation = $precisionResult.RequiresValidation
                $result.PotentialIssues += $precisionResult.Issues
            }
        }
        
        return $result
    }
    
    # Check for risky conversions
    if ($riskyConversions.ContainsKey($source) -and $riskyConversions[$source] -contains $target) {
        $result.IsAllowed = $true
        $result.ConversionType = 'Risky'
        $result.RiskLevel = 'High'
        $result.RequiresDataValidation = $true
        $result.Recommendation = "Conversion from $($result.SourceDefinition) to $($result.TargetDefinition) may cause data loss. Validate data before conversion."
        
        # Decimal/Numeric specific precision/scale checks
        if ($precisionScaleTypes -contains $source -and $precisionScaleTypes -contains $target) {
            $precisionScaleResult = Test-PrecisionScaleChange -SourcePrecision $SourcePrecision -SourceScale $SourceScale `
                                                              -TargetPrecision $TargetPrecision -TargetScale $TargetScale `
                                                              -DataType $target
            
            $result.PrecisionScaleCheck = $precisionScaleResult.Status
            $result.PotentialIssues += $precisionScaleResult.Issues
            
            if ($precisionScaleResult.Recommendation) {
                $result.Recommendation = $precisionScaleResult.Recommendation
            }
        }
        
        # Decimal to integer conversion
        if ($precisionScaleTypes -contains $source -and $numericRanges.ContainsKey($target)) {
            if ($SourceScale -gt 0) {
                $result.PotentialIssues += "Source decimal($SourcePrecision,$SourceScale) has fractional part. All decimal places will be truncated."
            }
            
            $targetMax = $numericRanges[$target].Precision
            $sourceWholeDigits = $SourcePrecision - $SourceScale
            
            if ($sourceWholeDigits -gt $targetMax) {
                $result.PotentialIssues += "Source can have up to $sourceWholeDigits whole digits, but $target maximum is $targetMax digits. Values will be out of range."
            }
            
            $result.Recommendation += " Check: MAX(ABS($($ColumnName))) to ensure all values fit within $target range."
        }
        
        # Other numeric conversions
        if ($numericTypes -contains $source -and $numericTypes -contains $target) {
            $result.PotentialIssues += "Numeric precision or range may be reduced. Out-of-range values will cause errors."
        }
        
        if ($stringTypes -contains $source -and $numericTypes -contains $target) {
            $result.PotentialIssues += "String to numeric conversion requires all values to be valid numbers."
        }
        
        if ($dateTypes -contains $source -and $dateTypes -contains $target) {
            $result.PotentialIssues += "Date/time precision may be reduced."
        }
        
        return $result
    }
    
    # Check for incompatible conversions
    $result.IsAllowed = $false
    $result.ConversionType = 'Incompatible'
    $result.RiskLevel = 'Blocked'
    $result.Recommendation = "Direct conversion from $($result.SourceDefinition) to $($result.TargetDefinition) is not supported or highly risky. Consider converting to an intermediate datatype first (e.g., to varchar/nvarchar)."
    $result.PotentialIssues += "Datatypes are incompatible for direct conversion."
    
    return $result
}

# Helper function to test precision and scale changes
function Test-PrecisionScaleChange {
    param(
        [int]$SourcePrecision,
        [int]$SourceScale,
        [int]$TargetPrecision,
        [int]$TargetScale,
        [string]$DataType
    )
    
    $result = @{
        Status = 'No Change'
        RiskLevel = 'None'
        RequiresValidation = $false
        Issues = @()
        Recommendation = ''
    }
    
    # Calculate whole number digits
    $sourceWholeDigits = $SourcePrecision - $SourceScale
    $targetWholeDigits = $TargetPrecision - $TargetScale
    
    # Check if precision or scale is decreasing
    $precisionDecreasing = $TargetPrecision -lt $SourcePrecision
    $scaleDecreasing = $TargetScale -lt $SourceScale
    $wholeDigitsDecreasing = $targetWholeDigits -lt $sourceWholeDigits
    
    if ($TargetPrecision -gt 38) {
        $result.Status = 'Invalid'
        $result.RiskLevel = 'Blocked'
        $result.Issues += "Target precision $TargetPrecision exceeds maximum allowed value of 38 for $DataType."
        return $result
    }
    
    if ($TargetScale -gt $TargetPrecision) {
        $result.Status = 'Invalid'
        $result.RiskLevel = 'Blocked'
        $result.Issues += "Target scale $TargetScale cannot exceed target precision $TargetPrecision."
        return $result
    }
    
    # Reducing scale
    if ($scaleDecreasing) {
        $result.Status = 'Scale Reduction'
        $result.RiskLevel = 'Medium'
        $result.RequiresValidation = $true
        $lostDigits = $SourceScale - $TargetScale
        $result.Issues += "Reducing scale from $SourceScale to $TargetScale will truncate or round $lostDigits decimal place(s)."
        $result.Recommendation = "Decimal values will be rounded. Validate if precision loss is acceptable."
    }
    
    # Reducing whole number capacity
    if ($wholeDigitsDecreasing) {
        $result.Status = 'Precision Reduction'
        $result.RiskLevel = 'High'
        $result.RequiresValidation = $true
        $result.Issues += "Reducing whole number capacity from $sourceWholeDigits to $targetWholeDigits digits. Values may overflow."
        $result.Recommendation = "Check maximum values: SELECT MAX(ABS(column)) to ensure they fit within $targetWholeDigits digits."
    }
    
    # Increasing scale but decreasing whole digits
    if ($TargetScale -gt $SourceScale -and $wholeDigitsDecreasing) {
        $result.Status = 'Scale Increase with Precision Loss'
        $result.RiskLevel = 'High'
        $result.RequiresValidation = $true
        $result.Issues += "Increasing scale from $SourceScale to $TargetScale while reducing whole digits from $sourceWholeDigits to $targetWholeDigits. This will cause overflow for large values."
        $result.Recommendation = "Consider using $DataType($($sourceWholeDigits + $TargetScale),$TargetScale) instead to preserve all whole digits."
    }
    
    # Safe expansion
    if ($TargetPrecision -ge $SourcePrecision -and $TargetScale -ge $SourceScale -and $targetWholeDigits -ge $sourceWholeDigits) {
        $result.Status = 'Safe Expansion'
        $result.RiskLevel = 'None'
        $result.Recommendation = "Conversion is safe - expanding precision/scale."
    }
    
    return $result
}

# Helper function to test precision changes for datetime types
function Test-PrecisionChange {
    param(
        [int]$SourcePrecision,
        [int]$TargetPrecision,
        [string]$DataType
    )
    
    $result = @{
        Status = 'No Change'
        RiskLevel = 'None'
        RequiresValidation = $false
        Issues = @()
    }
    
    $maxPrecision = 7
    
    if ($TargetPrecision -gt $maxPrecision) {
        $result.Status = 'Invalid'
        $result.RiskLevel = 'Blocked'
        $result.Issues += "Target precision $TargetPrecision exceeds maximum allowed value of $maxPrecision for $DataType."
        return $result
    }
    
    if ($TargetPrecision -lt $SourcePrecision) {
        $result.Status = 'Precision Reduction'
        $result.RiskLevel = 'Low'
        $result.RequiresValidation = $true
        $lostPrecision = $SourcePrecision - $TargetPrecision
        $result.Issues += "Reducing fractional seconds precision from $SourcePrecision to $TargetPrecision. $lostPrecision digit(s) of sub-second precision will be lost (rounded)."
    }
    elseif ($TargetPrecision -gt $SourcePrecision) {
        $result.Status = 'Safe Expansion'
        $result.RiskLevel = 'None'
    }
    
    return $result
}

# Helper function to build datatype definition string
function Get-DatatypeDefinition {
    param(
        [string]$DataType,
        [int]$Length,
        [int]$Precision,
        [int]$Scale
    )
    
    $precisionScaleTypes = @('decimal', 'numeric')
    $precisionTypes = @('datetime2', 'datetimeoffset', 'time')
    $lengthTypes = @('varchar', 'nvarchar', 'char', 'nchar', 'binary', 'varbinary')
    
    if ($precisionScaleTypes -contains $DataType) {
        if ($Precision -and $Scale -ge 0) {
            return "${DataType}($Precision,$Scale)"
        }
        elseif ($Precision) {
            return "${DataType}($Precision,0)"
        }
        else {
            return "${DataType}(18,0)"
        }
    }
    elseif ($precisionTypes -contains $DataType) {
        if ($Precision) {
            return "${DataType}($Precision)"
        }
        else {
            return "${DataType}(7)"
        }
    }
    elseif ($lengthTypes -contains $DataType) {
        if ($Length -eq -1) {
            return "${DataType}(MAX)"
        }
        elseif ($Length) {
            return "${DataType}($Length)"
        }
        else {
            return $DataType
        }
    }
    
    return $DataType
}
