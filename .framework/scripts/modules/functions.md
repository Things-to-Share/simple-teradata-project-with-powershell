# Documentation `functions.ps1` [back](./../scripts.md)

## Brief Overview

This script automates SQL database deployment and management for Teradata environments. It reads SQL definitions from files, compares them with existing database objects, generates ALTER scripts for schema changes, and executes deployments. The script handles table structure modifications, manages credentials securely, and provides progress tracking throughout the deployment process.

---

## Functions

### 1. `ps_get_sql_file_inventory`

#### Overview

Scans specified folders for SQL files, reads their content, processes environment variables, and builds a structured inventory of SQL objects (tables, views, procedures) with their definitions and metadata.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_nm_database_target` | Target Database Name | The database where objects will be deployed |
| `ip_environment` | Environment Configuration | Object containing environment-specific settings (cd_environment, nm_environment, nm_database, parameters) |

#### Output Parameters

Returns an array of PSCustomObjects containing:

- `ni_ordering`: Sequential order number
- `fp_relative`: Relative file path
- `nm_grouping`: Grouping category from folder structure
- `nm_schema`: Schema name extracted from path
- `nm_object`: Object name
- `cd_type`: Object type (tables/views/procedures)
- `tx_object`: SQL statement text
- `ob_table`: Table definition object (for tables only)
- `dt_modified`: Last modification timestamp

#### Dependencies

- `ps_remove_comments` - Removes SQL comments from statements
- `ps_get_table_def_from_sql_statement` - Parses CREATE TABLE statements
- Global variable: `$global:fp_root` - Root folder path

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize ordering counter] --> B[2. Define folder paths to scan]
    B --> C[3. Get all SQL files from folders recursively]
    C --> D[4. Loop through each SQL file]
    D --> E[5. Calculate relative file path]
    E --> F[6. Determine last modification date]
    F --> G[7. Read SQL file content]
    G --> H[8. Remove comments from SQL]
    H --> I[9. Replace environment placeholders]
    I --> J[10. Replace parameter placeholders]
    J --> K[11. Extract path components for grouping, schema, type, object name]
    K --> L{12. Is object type 'tables'?}
    L -->|Yes| M[13. Parse table definition from SQL]
    L -->|No| N[14. Skip table parsing]
    M --> O[15. Create object with all properties]
    N --> O
    O --> P[16. Add object to results collection]
    P --> Q{17. More files?}
    Q -->|Yes| D
    Q -->|No| R[18. Sort results by ordering]
    R --> S[19. Return sorted results]
```

---

### 2. `ps_get_sql_objt_inventory`

#### Overview

Queries the Teradata database to retrieve existing objects (tables, views, procedures), compares modification dates with local definitions, and builds an inventory using either database metadata or local file definitions based on which is newer.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_nm_database_target` | Target Database Name | Database to query for existing objects |
| `ip_nm_dsn` | Data Source Name | ODBC DSN for database connection |
| `ip_environment` | Environment Configuration | Environment settings object |
| `ip_excl_tables` | Exclude Tables Flag | Boolean to exclude tables from inventory |
| `ip_excl_views` | Exclude Views Flag | Boolean to exclude views from inventory |
| `ip_excl_procedures` | Exclude Procedures Flag | Boolean to exclude stored procedures from inventory |
| `ip_objects_tx` | Text Objects Collection | Collection of objects from file inventory |

#### Output Parameters

Returns an array of PSCustomObjects with the same structure as `ps_get_sql_file_inventory`.

#### Dependencies

- `ps_sql_connection` - Establishes database connection
- `ps_exec_sql_query_statement` - Executes SQL queries
- `ps_get_table_def_from_sql_database` - Retrieves table structure from database
- Write-Progress (PowerShell built-in) - Displays progress bars

#### Process Flow

```mermaid
flowchart TD
    A[1. Open SQL connection to DBC database] --> B[2. Initialize ordering counter and objects collection]
    B --> C[3. Build SQL query to get database objects with schema extraction logic]
    C --> D[4. Add WHERE clause filtering by database name and object types]
    D --> E[5. Execute query to retrieve objects]
    E --> F[6. Initialize progress bar variables]
    F --> G[7. Loop through each database object]
    G --> H[8. Extract object metadata: schema, name, type, modified date]
    H --> I[9. Find matching object in local file definitions]
    I --> J{10. Compare modification dates}
    J -->|DB newer| K[11. Use database definition - retrieve table structure from DB]
    J -->|File newer| L[12. Use file definition - copy from ip_objects_tx]
    K --> M[13. Update progress bars]
    L --> M
    M --> N[14. Create object with metadata and definition]
    N --> O[15. Add object to collection]
    O --> P{16. More objects?}
    P -->|Yes| G
    P -->|No| Q[17. Remove progress bars]
    Q --> R[18. Sort and return objects]
```

---

### 3. `ps_generate_table_alter_script`

#### Overview

Generates a four-step ALTER script sequence for modifying table structures: rename existing table, recreate with new structure, copy data with type conversions, and drop old table. Validates that data type conversions are safe before generating scripts.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_ob_table_db` | Database Table Object | Current table structure from database |
| `ip_ob_table_tx` | Text Table Object | Desired table structure from file |
| `ip_nm_database_target` | Target Database Name | Database containing the table |
| `ip_nm_schema` | Schema Name | Schema of the table |
| `ip_nm_table` | Table Name | Name of the table |
| `ip_ni_build` | Build Number | Sequential number for script ordering |
| `ip_fp_build` | Build Folder Path | Folder path for output scripts |

#### Output Parameters

Generates four SQL script files:

- `{build}-A-Rename-{table}-to-{table}_renamed.sql`
- `{build}-B-(Re)deploy-{table}.sql`
- `{build}-C-Load-existing-Data-into-{table}.sql`
- `{build}-D-Drop-Renamed-Table-{table}_renamed.sql`

#### Dependencies

- `ps_assesment_of_conversion` - Validates data type conversions
- Out-File (PowerShell built-in) - Writes scripts to files

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize variables: table names, column list, select clause] --> B[2. Loop through new table columns]
    B --> C{3. Does column exist in old table?}
    C -->|Yes| D{4. Are data types identical?}
    D -->|Yes| E[5. Use direct column reference]
    D -->|No| F[6. Assess conversion safety]
    F --> G{7. Is conversion allowed?}
    G -->|No| H[8. Throw error with recommendation]
    G -->|Yes| I[9. Add CAST to target data type]
    C -->|No| J{10. Is column nullable?}
    J -->|Yes| K[11. Use CAST NULL AS datatype]
    J -->|No| L{12. Has default value?}
    L -->|No| M[13. Throw error: not nullable without default]
    L -->|Yes| N[14. Use CAST default AS datatype]
    E --> O[15. Add column to SELECT clause]
    I --> O
    K --> O
    N --> O
    O --> P{16. More columns?}
    P -->|Yes| B
    P -->|No| Q[17. Generate RENAME TABLE script file A]
    Q --> R[18. Generate CREATE TABLE script file B]
    R --> S[19. Generate INSERT INTO with SELECT script file C]
    S --> T[20. Generate DROP TABLE script file D]
```

---

### 4. `get_credentials`

#### Overview

Manages secure credential storage and retrieval for database connections. Prompts for credentials on first use or when requested, encrypts and stores them in user profile, and retrieves stored credentials for subsequent use.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_prompt_for_override` | Prompt Override Flag | "y" to prompt for re-entering credentials, otherwise use stored |

#### Output Parameters

Returns a `PSCredential` object containing encrypted username and password.

#### Dependencies

- Export-Clixml (PowerShell built-in) - Encrypts and exports credentials
- Import-Clixml (PowerShell built-in) - Imports encrypted credentials
- Read-Host (PowerShell built-in) - Prompts for user input
- Environment variable: `$env:USERPROFILE` - User profile directory

#### Process Flow

```mermaid
flowchart TD
    A[1. Define credential file path in user profile] --> B{2. Does credential file exist?}
    B -->|Yes| C{3. Is override prompt flag set to 'y'?}
    C -->|Yes| D[4. Ask user if they want to re-enter credentials]
    D --> E{5. User response yes?}
    E -->|Yes| F[6. Set flag to force new credentials]
    E -->|No| G[7. Keep existing credentials flag]
    B -->|No| H[8. Display no credentials found message]
    H --> F
    C -->|No| G
    F --> I[9. Prompt for username]
    I --> J[10. Prompt for password as secure string]
    J --> K[11. Create PSCredential object]
    K --> L[12. Export encrypted credentials to XML file]
    L --> M[13. Display credentials saved message]
    M --> N[14. Return credential object]
    G --> O[15. Import credentials from XML file]
    O --> P{16. Import successful?}
    P -->|Yes| N
    P -->|No| Q[17. Display error and prompt for new credentials]
    Q --> I
```

---

### 5. `ps_sql_connection`

#### Overview

Establishes a connection to a Teradata database using ODBC with retry logic. Retrieves credentials securely, builds connection string, and attempts connection up to three times with progressive delays on failure.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_nm_dsn` | Data Source Name | ODBC DSN name configured for Teradata |
| `ip_nm_database` | Database Name | Initial database to connect to |

#### Output Parameters

Returns an open `OdbcConnection` object ready for executing queries.

#### Dependencies

- `get_credentials` - Retrieves database credentials
- System.Data.Odbc.OdbcConnection (.NET class) - ODBC connection object
- Start-Sleep (PowerShell built-in) - Delays between retries

#### Process Flow

```mermaid
flowchart TD
    A[1. Get credentials without prompting] --> B[2. Extract username and password]
    B --> C[3. Build ODBC connection string with DSN, credentials, database]
    C --> D[4. Initialize retry counter and success flag]
    D --> E[5. Create new ODBC connection object]
    E --> F[6. Set connection string]
    F --> G[7. Attempt to open connection]
    G --> H{8. Connection successful?}
    H -->|Yes| I[9. Set success flag to true]
    I --> J[10. Return connection object]
    H -->|No| K[11. Increment retry counter]
    K --> L[12. Dispose failed connection object]
    L --> M{13. Retry count less than max 3?}
    M -->|Yes| N[14. Calculate progressive wait time: retry * 2 seconds]
    N --> O[15. Wait before retry]
    O --> E
    M -->|No| P[16. Display error message]
    P --> Q[17. Throw exception: connection failed after 3 attempts]
```

---

### 6. `ps_sql_command`

#### Overview

Creates a configured SQL command object from a connection and SQL text. Sets command type to Text, disables timeout for long-running queries, and prepares the command for execution.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_ob_sql_connection` | SQL Connection Object | Open ODBC connection |
| `ip_tx_sql` | SQL Statement Text | SQL query or command to execute |

#### Output Parameters

Returns an `OdbcCommand` object configured and ready for execution.

#### Dependencies

- OdbcConnection.CreateCommand() method - Creates command from connection

#### Process Flow

```mermaid
flowchart TD
    A[1. Create command object from connection] --> B[2. Set CommandText property to SQL statement]
    B --> C[3. Set CommandType to Text for direct SQL execution]
    C --> D[4. Set CommandTimeout to 0 for no timeout limit]
    D --> E[5. Return configured command object]
```

---

### 7. `ps_exec_sql_query_statement`

#### Overview

Executes a SQL query and returns results as a DataTable. Implements retry logic with automatic reconnection on failure. Uses data adapters to efficiently fill datasets with query results.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_ob_sql_connection` | SQL Connection Object | Open ODBC connection |
| `ip_tx_sql` | SQL Query Text | SELECT query to execute |
| `ip_nm_dsn` | Data Source Name | DSN for reconnection attempts |

#### Output Parameters

Returns a `DataTable` containing query results with columns and rows.

#### Dependencies

- `ps_sql_command` - Creates command object
- `ps_sql_connection` - Reconnects on failure
- System.Data.Odbc.OdbcDataAdapter (.NET class) - Executes query and fills dataset
- System.Data.DataSet (.NET class) - Holds query results

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize retry counter and return flag] --> B[2. Create SQL command object]
    B --> C[3. Create ODBC data adapter with command]
    C --> D[4. Create new dataset object]
    D --> E[5. Execute query and fill dataset via adapter]
    E --> F{6. Execution successful?}
    F -->|Yes| G[7. Extract result table from dataset]
    G --> H[8. Return result table]
    F -->|No| I[9. Increment retry counter]
    I --> J{10. Retry count less than 3?}
    J -->|Yes| K[11. Close existing connection]
    K --> L[12. Reconnect to database]
    L --> B
    J -->|No| M[13. Log error details]
    M --> N[14. Return empty DataTable]
    N --> O[15. Dispose adapter and dataset in finally block]
    O --> P[16. Clear sensitive variables]
    P --> Q[17. Force garbage collection]
    H --> O
```

---

### 8. `ps_exec_sql_non_query_statement`

#### Overview

Executes SQL statements that don't return results (INSERT, UPDATE, DELETE, CREATE, DROP). Implements three-attempt retry logic with automatic reconnection on failure and error logging.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_nm_dsn` | Data Source Name | DSN for reconnection |
| `ip_ob_sql_connection` | SQL Connection Object | Open ODBC connection |
| `ip_tx_sql` | SQL Statement Text | DML/DDL statement to execute |

#### Output Parameters

Returns boolean: `$true` if execution succeeded, `$false` if failed after retries.

#### Dependencies

- `ps_sql_command` - Creates command object
- `ps_log_error` - Logs errors to file
- `ps_sql_connection` - Reconnects on failure
- Global variable: `$Global:fp_event_log` - Event log file path

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize retry counter and return flag] --> B[2. Create SQL command object]
    B --> C[3. Execute non-query command via ExecuteNonQuery]
    C --> D{4. Execution successful and result not null?}
    D -->|Yes| E[5. Set return flag to true]
    E --> F[6. Return true]
    D -->|No| G[7. Increment retry counter]
    G --> H{8. Retry count less than 3?}
    H -->|Yes| I[9. Close existing connection if open]
    I --> J[10. Reconnect to database]
    J --> B
    H -->|No| K[11. Log error to event log file]
    K --> L[12. Return false]
```

---

### 9. `ps_remove_comments`

#### Overview

Removes SQL comments (single-line `--` and multi-line `/* */`) from SQL statements while preserving comments inside quoted strings. Cleans up excessive blank lines for readable output.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_tx_sql_statement` | SQL Statement Text | SQL text containing comments |

#### Output Parameters

Returns cleaned SQL text string with comments removed.

#### Dependencies

- None (uses PowerShell built-in string operations and regex)

#### Process Flow

```mermaid
flowchart TD
    A[1. Remove all multi-line comments using regex pattern] --> B[2. Split SQL into individual lines]
    B --> C[3. Initialize cleaned lines array]
    C --> D[4. Loop through each line]
    D --> E[5. Initialize quote tracking: inQuote flag and quoteChar]
    E --> F[6. Scan line character by character]
    F --> G{7. Is character a quote?}
    G -->|Yes| H{8. Currently in quote?}
    H -->|No| I[9. Set inQuote flag and store quote character]
    H -->|Yes| J{10. Matching quote character?}
    J -->|Yes| K[11. Clear inQuote flag]
    J -->|No| L[12. Continue scanning]
    G -->|No| M{13. Is double-dash and not in quote?}
    M -->|Yes| N[14. Mark comment position and break loop]
    M -->|No| L
    I --> L
    K --> L
    N --> O[15. Remove comment portion from line]
    O --> P{16. Is trimmed line non-empty?}
    P -->|Yes| Q[17. Add line to cleaned lines array]
    P -->|No| R{18. More lines?}
    Q --> R
    R -->|Yes| D
    R -->|No| S[19. Join cleaned lines with newlines]
    S --> T[20. Remove excessive blank lines using regex]
    T --> U[21. Trim result and return]
```

---

### 10. `ps_minify_sql`

#### Overview

Compresses SQL statements by removing comments, extra whitespace, and line breaks while preserving string literals. Optionally keeps newlines after major keywords for readability. Reduces SQL file size for storage or transmission.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `SqlQuery` | SQL Query Text | SQL statement to minify (accepts pipeline input) |
| `PreserveComments` | Keep Comments Flag | Switch to retain comments in output |
| `KeepNewlinesAfterKeywords` | Format Keywords Flag | Switch to add newlines after major SQL keywords |

#### Output Parameters

Returns minified SQL text string.

#### Dependencies

- None (uses PowerShell built-in regex and string operations)

#### Process Flow

```mermaid
flowchart TD
    A[1. Remove single-line comments unless preserving] --> B[2. Remove multi-line comments unless preserving]
    B --> C[3. Normalize all line breaks to spaces]
    C --> D[4. Replace multiple consecutive spaces with single space]
    D --> E[5. Remove spaces around operators and punctuation]
    E --> F[6. Add space after commas for readability]
    F --> G[7. Extract string literals using regex]
    G --> H[8. Replace each string with placeholder token]
    H --> I[9. Store original strings with index mapping]
    I --> J{10. KeepNewlinesAfterKeywords flag set?}
    J -->|Yes| K[11. Add newline before major keywords: SELECT, FROM, WHERE, etc]
    J -->|No| L[12. Skip keyword formatting]
    K --> M[13. Loop through placeholders]
    L --> M
    M --> N[14. Replace each placeholder with original string literal]
    N --> O{15. More placeholders?}
    O -->|Yes| M
    O -->|No| P[16. Trim final whitespace]
    P --> Q[17. Return minified SQL]
```

---

### 11. `ps_log_error`

#### Overview

Formats and logs detailed error information to a file. Captures exception message, type, stack trace, line number, and SQL statement. Optionally displays error on console.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_fp_event_log` | Event Log File Path | Full path to error log file |
| `ip_tx_sql_statement` | SQL Statement Text | SQL that caused the error |
| `ip_feedback` | Display Feedback Switch | Switch to display error on console |

#### Output Parameters

None (writes to file and optionally to console).

#### Dependencies

- Out-File (PowerShell built-in) - Appends to log file
- Automatic variable: `$_` - Current error object

#### Process Flow

```mermaid
flowchart TD
    A[1. Build error header with exclamation marks] --> B[2. Add current timestamp to log]
    B --> C[3. Extract and add exception message]
    C --> D[4. Add exception type full name]
    D --> E[5. Add script stack trace]
    E --> F[6. Add line number where error occurred]
    F --> G[7. Add SQL statement that failed]
    G --> H[8. Add closing delimiter line]
    H --> I[9. Append formatted error to log file in UTF8]
    I --> J{10. Is feedback switch set?}
    J -->|Yes| K[11. Display error text on console]
    J -->|No| L[12. Skip console display]
    K --> M[13. Complete logging]
    L --> M
```

---

### 12. `ps_get_sql_statements`

#### Overview

Reads all SQL files from a build folder recursively, loads their content, and returns a collection of statements with metadata. Used to load generated deployment scripts for execution.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_fp_build` | Build Folder Path | Folder containing SQL script files |

#### Output Parameters

Returns array of PSCustomObjects with properties:

- `tx_sql`: SQL statement text
- `fp_build`: File base name without extension

#### Dependencies

- Test-Path (PowerShell built-in) - Validates folder exists
- Get-ChildItem (PowerShell built-in) - Lists SQL files
- Get-Content (PowerShell built-in) - Reads file content

#### Process Flow

```mermaid
flowchart TD
    A[1. Validate build folder path exists] --> B{2. Does folder exist?}
    B -->|No| C[3. Throw exception: build file not found]
    B -->|Yes| D[4. Get all SQL files recursively from folder]
    D --> E[5. Loop through each file]
    E --> F[6. Read entire file content as raw text]
    F --> G[7. Create PSCustomObject with tx_sql and fp_build properties]
    G --> H[8. Add object to statements collection]
    H --> I{9. More files?}
    I -->|Yes| E
    I -->|No| J[10. Display count of found statements]
    J --> K[11. Return statements array]
    C --> L[12. Return empty array on error]
```

---

### 13. `ps_exec_sql_query_to_file`

#### Overview

Streams SQL query results directly to a file row-by-row to handle large datasets efficiently. Supports custom delimiters, encoding, headers, and row numbering. Displays progress every 10,000 rows.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_ob_sql_connection` | SQL Connection Object | Open ODBC connection |
| `ip_tx_sql` | SQL Query Text | SELECT query to execute |
| `ip_nm_dsn` | Data Source Name | DSN for reconnection |
| `ip_output_file` | Output File Path | Full path for result file |
| `ip_delimiter` | Column Delimiter | Delimiter between columns (default: pipe) |
| `ip_encoding` | File Encoding | Text encoding (default: UTF8) |
| `ip_include_headers` | Include Headers Flag | Boolean to include column headers (default: true) |
| `ip_add_row_number` | Add Row Number Flag | Boolean to prefix rows with number (default: true) |

#### Output Parameters

Creates a delimited text file with query results.

#### Dependencies

- `ps_sql_command` - Creates command object
- `ps_sql_connection` - Reconnects on failure
- System.IO.StreamWriter (.NET class) - Efficient file writing
- OdbcCommand.ExecuteReader() method - Streams results

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize retry counter and success flag] --> B[2. Ensure output directory exists]
    B --> C[3. Create directory if needed]
    C --> D[4. Create SQL command object]
    D --> E[5. Execute query and get DataReader]
    E --> F[6. Create StreamWriter for output file]
    F --> G[7. Get column names from reader]
    G --> H{8. Include headers flag set?}
    H -->|Yes| I[9. Write column names as header line]
    H -->|No| J[10. Skip header]
    I --> K[11. Initialize row counter]
    J --> K
    K --> L{12. Read next row from DataReader}
    L -->|More rows| M[13. Loop through columns and extract values]
    M --> N[14. Handle NULL values as empty strings]
    N --> O{15. Add row number flag set?}
    O -->|Yes| P[16. Prefix row with counter]
    O -->|No| Q[17. Skip row number]
    P --> R[18. Join values with delimiter and add CRLF]
    Q --> R
    R --> S[19. Write row to file]
    S --> T{20. Row count divisible by 10000?}
    T -->|Yes| U[21. Display progress message]
    T -->|No| V[22. Continue]
    U --> W[23. Flush buffer to disk]
    W --> L
    V --> L
    L -->|No more rows| X[24. Display total rows written]
    X --> Y[25. Close and dispose StreamWriter]
    Y --> Z{26. Execution successful?}
    Z -->|Yes| AA[27. Set success flag and return]
    Z -->|No| AB{28. Retry count less than 3?}
    AB -->|Yes| AC[29. Close resources and reconnect]
    AC --> D
    AB -->|No| AD[30. Delete partial file and throw error]
```

---

### 14. `ps_get_table_def_from_sql_statement`

#### Overview

Parses a CREATE TABLE SQL statement using regex to extract table structure including columns, data types, lengths, precision, scale, nullability, defaults, and ordinal positions. Builds a structured table definition object.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_tx_sql_statement` | SQL Statement Text | CREATE TABLE statement to parse |
| `ip_nm_database` | Database Name | Target database name |
| `ip_nm_schema` | Schema Name | Schema name |
| `ip_nm_table` | Table Name | Table name |

#### Output Parameters

Returns a `cl_table` object containing:

- `Database`: Database name
- `SchemaName`: Schema name
- `TableName`: Table name
- `Columns`: ArrayList of `cl_column` objects with full column definitions

#### Dependencies

- Class definitions: `cl_table`, `cl_column`
- Regex (.NET) - Pattern matching for SQL parsing

#### Process Flow

```mermaid
flowchart TD
    A[1. Create new cl_table object] --> B[2. Set Database, SchemaName, TableName properties]
    B --> C[3. Define regex pattern for column definitions]
    C --> D[4. Execute regex match on SQL statement]
    D --> E[5. Initialize ordinal position counter]
    E --> F[6. Loop through regex matches]
    F --> G[7. Create new cl_column object]
    G --> H[8. Extract column name from match group 1]
    H --> I[9. Set ordinal position and increment counter]
    I --> J[10. Parse data type from match group 2]
    J --> K{11. Does data type have parameters?}
    K -->|Yes| L{12. Is string type with length?}
    L -->|Yes| M[13. Extract MaxLength]
    L -->|No| N{14. Is numeric with precision/scale?}
    N -->|Yes| O[15. Extract Precision and Scale]
    N -->|No| P[16. Extract only Precision]
    K -->|No| Q[17. Use data type without parameters]
    M --> R[18. Build complete DDL datatype string]
    O --> R
    P --> R
    Q --> R
    R --> S[19. Parse nullable from match group 3]
    S --> T{20. Has default value in match group 4?}
    T -->|Yes| U[21. Store default value]
    T -->|No| V[22. Leave default empty]
    U --> W[23. Add column object to table Columns collection]
    V --> W
    W --> X{24. More matches?}
    X -->|Yes| F
    X -->|No| Y[25. Return completed table object]
```

---

### 15. `ps_get_table_def_from_sql_database`

#### Overview

Queries Teradata system tables (DBC.ColumnsV) to retrieve complete table structure metadata including all columns with their data types, lengths, precision, scale, nullability, defaults, and ordinal positions.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_ob_sql_connection` | SQL Connection Object | Open ODBC connection |
| `ip_nm_database` | Database Name | Target database name |
| `ip_nm_schema` | Schema Name | Schema name |
| `ip_nm_table` | Table Name | Table name |
| `ip_nm_dsn` | Data Source Name | DSN for query execution |

#### Output Parameters

Returns a `cl_table` object with complete column definitions from database metadata.

#### Dependencies

- `ps_exec_sql_query_statement` - Executes metadata query
- Class definitions: `cl_table`, `cl_column`

#### Process Flow

```mermaid
flowchart TD
    A[1. Build DatabaseNameTableName string] --> B[2. Construct SQL query selecting from DBC.ColumnsV]
    B --> C[3. Add CASE statement to translate Teradata column type codes to readable types]
    C --> D[4. Map codes: I=INT, D=DEC, CF=CHAR, CV=VARCHAR, DA=DATE, TS=TIMESTAMP, etc]
    D --> E[5. Add WHERE clause filtering by database and table name]
    E --> F[6. Add ORDER BY for DatabaseName, TableName, ColumnId]
    F --> G[7. Execute query to retrieve column metadata]
    G --> H[8. Create new cl_table object]
    H --> I[9. Set Database, SchemaName, TableName properties]
    I --> J[10. Loop through query result rows]
    J --> K[11. Create new cl_column object for each row]
    K --> L[12. Extract base data type from DATA_TYPE column]
    L --> M[13. Get MaxLength, Precision, Scale from result]
    M --> N{14. Switch on base data type}
    N -->|INTEGER| O[15. Build datatype as INT]
    N -->|DECIMAL/DEC| P[16. Build DEC with precision and scale]
    N -->|CHAR/VARCHAR| Q[17. Build with MaxLength parameter]
    N -->|BYTE/VARBYTE| R[18. Build with MaxLength parameter]
    N -->|Other| S[19. Use base data type as-is]
    O --> T{20. Is datatype BIGINT or DEC?}
    P --> T
    Q --> T
    R --> T
    S --> T
    T -->|Yes| U[21. Override MaxLength to 0]
    T -->|No| V[22. Keep MaxLength]
    U --> W[23. Set all column properties: DataType, MaxLength, Precision, Scale, IsNullable, DefaultValue]
    V --> W
    W --> X[24. Handle special default value: Current TimeStamp]
    X --> Y[25. Set IsIdentity and OrdinalPosition]
    Y --> Z[26. Add column to table Columns collection]
    Z --> AA{27. More rows?}
    AA -->|Yes| J
    AA -->|No| AB[28. Return completed table object]
```

---

### 16. `ps_assesment_of_conversion`

#### Overview

Evaluates whether converting from one SQL data type to another is safe, allowed, or risky. Analyzes precision, scale, and length changes for numeric, string, and datetime types. Provides detailed risk assessment and recommendations.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_source_datatype` | Source Data Type Object | Object with datatype, maxlength, precision, scale properties |
| `ip_target_datatype` | Target Data Type Object | Object with target datatype parameters |

#### Output Parameters

Returns a PSCustomObject with properties:

- `IsAllowed`: Boolean indicating if conversion is permitted
- `ConversionType`: Type category (SameType/Safe/Risky/Incompatible)
- `RiskLevel`: None/Low/Medium/High/Blocked
- `RequiresDataValidation`: Boolean if data validation needed
- `PotentialIssues`: Array of issue descriptions
- `Recommendation`: Suggested action or alternative approach
- `PrecisionScaleCheck`: Status of precision/scale validation
- `LengthCheck`: Status of length validation
- `SourceDefinition`: Full source datatype string
- `TargetDefinition`: Full target datatype string

#### Dependencies

- Helper function: `Test-PrecisionScaleChange` - Validates precision/scale changes
- Helper function: `Test-PrecisionChange` - Validates datetime precision changes
- Helper function: `Get-DatatypeDefinition` - Formats datatype strings

#### Process Flow

```mermaid
flowchart TD
    A[1. Extract and normalize source and target datatypes] --> B[2. Strip length, precision, scale from type names]
    B --> C[3. Define datatype category arrays: numeric, string, date, binary, etc.]
    C --> D[4. Define default precision/scale values for types]
    D --> E[5. Define numeric type ranges and maximum values]
    E --> F[6. Initialize result object with default values]
    F --> G[7. Build source and target definition strings]
    G --> H[8. Apply default precision/scale if not specified]
    H --> I{9. Are source and target same datatype?}
    I -->|Yes| J[10. Set ConversionType to SameType]
    J --> K{11. Is precision/scale type?}
    K -->|Yes| L[12. Call Test-PrecisionScaleChange helper]
    L --> M[13. Update result with precision/scale check status]
    K -->|No| N{14. Is datetime precision type?}
    N -->|Yes| O[15. Call Test-PrecisionChange helper]
    O --> M
    N -->|No| P{16. Is length-based type?}
    P -->|Yes| Q{17. Is target length smaller?}
    Q -->|Yes| R[18. Set risk to Medium: truncation risk]
    Q -->|No| S[19. Set risk to None: safe or no change]
    P -->|No| S
    R --> T[20. Return result object]
    S --> T
    I -->|No| U{21. Is conversion in safe conversions list?}
    U -->|Yes| V[22. Set ConversionType to Safe]
    V --> W{23. Both numeric with precision/scale?}
    W -->|Yes| X[24. Validate precision/scale compatibility]
    W -->|No| Y{25. Integer to decimal conversion?}
    Y -->|Yes| Z[26. Check if target precision can hold source range]
    Y -->|No| AA{27. Decimal to integer conversion?}
    AA -->|Yes| AB[28. Check for fractional loss and range overflow]
    AA -->|No| AC{29. String length change?}
    AC -->|Yes| AD{30. Target length smaller?}
    AD -->|Yes| AE[31. Set truncation risk]
    AD -->|No| AF[32. Safe expansion]
    AC -->|No| AG{33. Unicode to non-Unicode?}
    AG -->|Yes| AH[34. Warn about Unicode character loss]
    AG -->|No| AI{35. Datetime precision change?}
    AI -->|Yes| AJ[36. Validate datetime precision]
    AI -->|No| AF
    X --> AK[37. Return result with risk assessment]
    Z --> AK
    AB --> AK
    AE --> AK
    AH --> AK
    AJ --> AK
    AF --> AK
    U -->|No| AL{38. Is conversion in risky conversions list?}
    AL -->|Yes| AM[39. Set ConversionType to Risky]
    AM --> AN[40. Set RiskLevel to High]
    AN --> AO[41. Set RequiresDataValidation to true]
    AO --> AP[42. Add detailed warnings based on type combination]
    AP --> AK
    AL -->|No| AQ[43. Set ConversionType to Incompatible]
    AQ --> AR[44. Set RiskLevel to Blocked]
    AR --> AS[45. Recommend intermediate conversion]
    AS --> AK
```

---

### Helper Function: `Test-PrecisionScaleChange`

#### Overview

Validates precision and scale changes for DECIMAL/NUMERIC types. Calculates whole number digits, detects truncation risks, checks for overflows, and provides detailed recommendations for safe conversions.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `SourcePrecision` | Source Precision | Total digits in source |
| `SourceScale` | Source Scale | Decimal places in source |
| `TargetPrecision` | Target Precision | Total digits in target |
| `TargetScale` | Target Scale | Decimal places in target |
| `DataType` | Data Type Name | Type being converted (decimal/numeric) |

#### Output Parameters

Returns hashtable with:

- `Status`: Description of change type
- `RiskLevel`: None/Low/Medium/High/Blocked
- `RequiresValidation`: Boolean
- `Issues`: Array of issue descriptions
- `Recommendation`: Suggested action

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize result hashtable] --> B[2. Calculate source whole digits: precision minus scale]
    B --> C[3. Calculate target whole digits: precision minus scale]
    C --> D{4. Is target precision greater than 38?}
    D -->|Yes| E[5. Set status Invalid: exceeds max]
    D -->|No| F{6. Is target scale greater than target precision?}
    F -->|Yes| G[7. Set status Invalid: scale cannot exceed precision]
    F -->|No| H{8. Is target scale less than source scale?}
    H -->|Yes| I[9. Set Status to Scale Reduction]
    I --> J[10. Calculate lost decimal digits]
    J --> K[11. Set RiskLevel to Medium]
    K --> L[12. Add issue: decimal places will be rounded]
    H -->|No| M{13. Are target whole digits less than source?}
    M -->|Yes| N[14. Set Status to Precision Reduction]
    N --> O[15. Set RiskLevel to High]
    O --> P[16. Add issue: values may overflow]
    P --> Q[17. Recommend checking maximum values]
    M -->|No| R{18. Scale increasing AND whole digits decreasing?}
    R -->|Yes| S[19. Set Status to Scale Increase with Precision Loss]
    S --> T[20. Set RiskLevel to High]
    T --> U[21. Add issue: large values will overflow]
    U --> V[22. Recommend higher precision to preserve whole digits]
    R -->|No| W{23. Both precision and scale expanding?}
    W -->|Yes| X[24. Set Status to Safe Expansion]
    X --> Y[25. Set RiskLevel to None]
    W -->|No| L
    L --> Z[26. Return result hashtable]
    Q --> Z
    V --> Z
    Y --> Z
    E --> Z
    G --> Z
```

---

### Helper Function: `Test-PrecisionChange`

#### Overview

Validates precision changes for datetime types (DATETIME2, DATETIMEOFFSET, TIME). Checks maximum allowed precision (7) and assesses impact of reducing fractional seconds precision.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `SourcePrecision` | Source Precision | Fractional seconds digits in source |
| `TargetPrecision` | Target Precision | Fractional seconds digits in target |
| `DataType` | Data Type Name | Datetime type being converted |

#### Output Parameters

Returns hashtable with:

- `Status`: Description of change
- `RiskLevel`: None/Low/Blocked
- `RequiresValidation`: Boolean
- `Issues`: Array of issues

#### Process Flow

```mermaid
flowchart TD
    A[1. Initialize result hashtable with No Change status] --> B[2. Set maximum precision to 7]
    B --> C{3. Does target precision exceed maximum 7?}
    C -->|Yes| D[4. Set status to Invalid]
    D --> E[5. Set RiskLevel to Blocked]
    E --> F[6. Add issue: exceeds maximum precision]
    F --> G[7. Return result]
    C -->|No| H{8. Is target precision less than source?}
    H -->|Yes| I[9. Set Status to Precision Reduction]
    I --> J[10. Set RiskLevel to Low]
    J --> K[11. Set RequiresValidation to true]
    K --> L[12. Calculate lost precision digits]
    L --> M[13. Add issue: sub-second precision will be lost with rounding]
    M --> G
    H -->|No| N{14. Is target precision greater than source?}
    N -->|Yes| O[15. Set Status to Safe Expansion]
    O --> P[16. Set RiskLevel to None]
    P --> G
    N -->|No| G
```

---

### Helper Function: `Get-DatatypeDefinition`

#### Overview

Formats a datatype with its parameters (length, precision, scale) into a complete DDL-ready string representation. Handles string types, numeric types, and datetime types appropriately.

#### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `DataType` | Data Type Name | Base datatype name |
| `Length` | Length Parameter | Length for string/binary types |
| `Precision` | Precision Parameter | Precision for numeric/datetime types |
| `Scale` | Scale Parameter | Scale for numeric types |

#### Output Parameters

Returns formatted datatype string (e.g., "VARCHAR(100)", "DECIMAL(18,2)", "DATETIME2(7)").

#### Process Flow

```mermaid
flowchart TD
    A[1. Define precision/scale types array: decimal, numeric] --> B[2. Define precision types array: datetime2, datetimeoffset, time]
    B --> C[3. Define length types array: varchar, nvarchar, char, etc.]
    C --> D{4. Is datatype in precision/scale types?}
    D -->|Yes| E{5. Has precision and scale?}
    E -->|Yes| F[6. Return datatype with precision and scale]
    E -->|No| G{7. Has precision only?}
    G -->|Yes| H[8. Return datatype with precision and scale 0]
    G -->|No| I[9. Return datatype with default 18 comma 0]
    D -->|No| J{10. Is datatype in precision types?}
    J -->|Yes| K{11. Has precision specified?}
    K -->|Yes| L[12. Return datatype with precision]
    K -->|No| M[13. Return datatype with default precision 7]
    J -->|No| N{14. Is datatype in length types?}
    N -->|Yes| O{15. Is length -1 indicating MAX?}
    O -->|Yes| P[16. Return datatype with MAX]
    O -->|No| Q{17. Has length specified?}
    Q -->|Yes| R[18. Return datatype with length]
    Q -->|No| S[19. Return datatype without parameters]
    N -->|No| S
    F --> T[20. Return formatted string]
    H --> T
    I --> T
    L --> T
    M --> T
    P --> T
    R --> T
    S --> T
```

---

## Code Outside Functions

### Overview

The main execution code handles the complete deployment workflow: loads configurations, builds object inventories from files and database, compares structures, generates ALTER scripts for changed tables, and optionally executes the deployment. Provides user prompts for credential management and deployment confirmation.

### Input Parameters

This code uses predefined configuration variables and prompts the user for deployment confirmation. Key inputs:

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| (User prompt) | Credential Override | User confirms whether to re-enter database credentials |
| (User prompt) | Deployment Confirmation | User confirms whether to execute generated SQL scripts |
| `$global:fp_root` | Root Folder Path | Base directory containing SQL definitions |
| `$ip_environment` | Environment Configuration | Environment settings loaded from configuration |

### Output Parameters

The code produces:

- Build folder with numbered SQL deployment scripts
- Event log file with execution details
- Console output showing progress and results
- Deployed database objects (if execution confirmed)

### Dependencies

- All functions defined earlier in the script
- Global variables: `$global:fp_root`, `$global:fp_event_log`
- Configuration file: "teradata_config.json" (assumed to exist)

### Process Flow

```mermaid
flowchart TD
    A[1. Prompt user to re-enter database credentials] --> B[2. Call get_credentials function]
    B --> C[3. Define target database name from configuration]
    C --> D[4. Set exclusion flags for tables, views, procedures]
    D --> E[5. Define build folder path with timestamp]
    E --> F[6. Create build directory if not exists]
    F --> G[7. Define event log file path]
    G --> H[8. Display deployment start message with timestamp]
    H --> I[9. Call ps_get_sql_file_inventory to load SQL definitions from files]
    I --> J[10. Display count of found SQL file objects]
    J --> K[11. Open database connection via ps_sql_connection]
    K --> L[12. Call ps_get_sql_objt_inventory to load database objects]
    L --> M[13. Display count of found database objects]
    M --> N[14. Initialize build script counter]
    N --> O[15. Loop through file inventory objects]
    O --> P{16. Is object type tables?}
    P -->|Yes| Q[17. Find matching object in database inventory]
    Q --> R{18. Database object found?}
    R -->|Yes| S[19. Compare file and database table structures]
    S --> T{20. Are structures different?}
    T -->|Yes| U[21. Display table has changes message]
    U --> V[22. Increment build counter]
    V --> W[23. Call ps_generate_table_alter_script]
    W --> X[24. Catch and display any errors]
    T -->|No| Y[25. Display table unchanged message]
    R -->|No| Z[26. Display table is new message]
    Z --> AA[27. Increment build counter]
    AA --> AB[28. Write CREATE TABLE script to build folder]
    P -->|No| AC{29. Is object type views or procedures?}
    AC -->|Yes| AD[30. Increment build counter]
    AD --> AE[31. Write CREATE VIEW/PROCEDURE script to build folder]
    AC -->|No| AF[32. Skip object]
    Y --> AG{33. More objects in file inventory?}
    X --> AG
    AB --> AG
    AE --> AG
    AF --> AG
    AG -->|Yes| O
    AG -->|No| AH[34. Display build generation complete message]
    AH --> AI[35. Call ps_get_sql_statements to load generated scripts]
    AI --> AJ[36. Display count of found SQL statements]
    AJ --> AK[37. Prompt user: Execute deployment yes or no?]
    AK --> AL{38. User confirmed deployment?}
    AL -->|Yes| AM[39. Display execution start message]
    AM --> AN[40. Loop through SQL statements]
    AN --> AO[41. Display executing script message]
    AO --> AP[42. Call ps_exec_sql_non_query_statement]
    AP --> AQ{43. Execution successful?}
    AQ -->|Yes| AR[44. Display success message]
    AQ -->|No| AS[45. Display failure message and log error]
    AR --> AT{46. More statements?}
    AS --> AT
    AT -->|Yes| AN
    AT -->|No| AU[47. Display deployment complete message]
    AL -->|No| AV[48. Display deployment cancelled message]
    AU --> AW[49. Close database connection]
    AV --> AW
    AW --> AX[50. Display script end timestamp]
```

---

**Utilized ASN GPT Prompt**

> **LLM Used:** Claude (Anthropic)
> **Prompt Used:** [level-1-powershell-script](./../.ai_prompts/documentation-related-to-powershell/level-1-powershell-script.tx)

*end of document*
