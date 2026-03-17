# Documentation `build_and_publish.ps1` [back](./../scripts.md)

## Brief Overview

This script automates database deployment for different environments (O/T/A/P). It compares SQL object definitions from files against actual database objects, generates ALTER/CREATE/DROP statements for tables, views, and procedures, and optionally executes these changes. The script maintains metadata and provides detailed logging of all deployment activities with progress tracking.

---

## Function: ps_build_and_publish

### Overview

Main orchestration function that builds deployment scripts by comparing file definitions with database objects, generates necessary SQL statements (CREATE, ALTER, DROP), and optionally publishes changes to the target database environment.

### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_cd_environment` | Environment Code | Mandatory parameter accepting O/T/A/P to specify target environment |
| `ip_publish` | Publish Flag | Switch to execute generated SQL scripts immediately |
| `ip_excl_drop_objects` | Exclude Drop Objects | Switch to skip generating DROP statements for obsolete objects |
| `ip_excl_tables` | Exclude Tables | Switch to skip table-related changes |
| `ip_excl_views` | Exclude Views | Switch to skip view-related changes |
| `ip_excl_procedures` | Exclude Procedures | Switch to skip procedure-related changes |
| `ip_is_override` | Override Flag | Switch to force replacement of all views/procedures regardless of changes |

### Output Parameters

Returns boolean indicating successful metadata update and sets `$ni_failed` variable with count of failed deployments.

### Dependencies

- `ps_get_sql_file_inventory` - Loads SQL definitions from files
- `ps_get_sql_objt_inventory` - Retrieves database objects
- `ps_generate_table_alter_script` - Creates ALTER TABLE statements
- `ps_minify_sql` - Normalizes SQL for comparison
- `ps_publish` - Executes deployment scripts
- `ps_sql_connection` - Establishes database connection
- `ps_exec_sql_non_query_statement` - Executes SQL statements
- `ps_log_error` - Error logging functionality

### Process Flow

```mermaid
graph TD
    A[1. Start Process] --> B[2. Initialize build directory and clear previous files]
    B --> C[3. Select environment configuration based on input parameter]
    C --> D[4. Load SQL object definitions from file system]
    D --> E[5. Load existing database objects and compare with definitions]
    E --> F{6. Exclude drop objects?}
    F -->|No| G[7. Generate DROP statements for objects not in definitions]
    F -->|Yes| H[8. Skip to table processing]
    G --> H
    H --> I{9. Exclude tables?}
    I -->|No| J[10. Compare table definitions and generate CREATE/ALTER statements]
    I -->|Yes| K[11. Skip to view processing]
    J --> K
    K --> L{12. Exclude views?}
    L -->|No| M[13. Compare view definitions and generate REPLACE statements if changed]
    L -->|Yes| N[14. Skip to procedure processing]
    M --> N
    N --> O{15. Exclude procedures?}
    O -->|No| P[16. Compare procedure definitions and generate REPLACE statements if changed]
    O -->|Yes| Q[17. Check if publish flag is set]
    P --> Q
    Q -->|Yes| R[18. Execute ps_publish to deploy generated SQL files]
    Q -->|No| S[19. Skip publishing]
    R --> T[20. Update metadata by calling metadata stored procedure]
    S --> T
    T --> U[21. Report deployment status and completion]
```

---

## Function: ps_publish

### Overview

Executes SQL deployment scripts from build directory in sequential order. Provides progress tracking, retry logic for failed statements, and comprehensive error logging for all deployment activities.

### Input Parameters

| Technical Name | Functional Name | Description |
| --- | --- | --- |
| `ip_fp_build` | Build Folder Path | Mandatory path to directory containing generated SQL scripts |
| `ip_nm_dsn` | DSN Name | Mandatory data source name for database connection |
| `ip_nm_database` | Database Name | Mandatory target database name for execution |

### Output Parameters

Returns integer count of failed SQL statement executions (`$stats.ni_failed`).

### Dependencies

- `ps_get_sql_statements` - Reads SQL files from build directory
- `ps_sql_connection` - Creates database connection
- `ps_exec_sql_non_query_statement` - Executes individual SQL statements
- `ps_log_error` - Logs execution errors
- `Write-Progress` - PowerShell cmdlet for progress display

### Process Flow

```mermaid
graph TD
    A[1. Start Publish Process] --> B[2. Set start datetime and initialize event log file]
    B --> C[3. Load all SQL statements from build directory files]
    C --> D{4. Are statements found?}
    D -->|No| E[5. Exit with success message]
    D -->|Yes| F[6. Initialize statistics counters and progress tracking]
    F --> G[7. Establish database connection]
    G --> H[8. Loop through each SQL statement]
    H --> I[9. Initialize retry counter for current statement]
    I --> J{10. Retry less than max?}
    J -->|Yes| K[11. Execute SQL statement via connection]
    K --> L{12. Execution successful?}
    L -->|Yes| M[13. Update done counter and progress bar]
    L -->|No| N[14. Increment retry counter and log error]
    N --> J
    J -->|No| O[15. Mark statement as failed permanently]
    M --> P{16. More statements?}
    O --> P
    P -->|Yes| H
    P -->|No| Q[17. Close progress bars]
    Q --> R[18. Display success and failure summary statistics]
    R --> S[19. Return failed statement count]
```

---

## Code Outside Functions

No executable code exists outside the function definitions in this script. All logic is encapsulated within the two functions described above.

---

**Utilized ASN GPT Prompt**

> **LLM Used:** Claude (Anthropic)
> **Prompt Used:** [level-1-powershell-script](./../.ai_prompts/documentation-related-to-powershell/level-1-powershell-script.tx)

*end of document*
