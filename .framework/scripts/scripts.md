# Documentation: `scripts` [back](./../.framework.md)

## Introduction

This framework is a collection of PowerShell scripts designed to automate database deployments for Teradata environments. It is used by data engineers to compare SQL object definitions (stored as files) against what currently exists in the database, generate the necessary SQL change scripts, and optionally execute those changes — all in a controlled and repeatable way.

The framework supports four environments: Development (O), Test (T), Acceptance (A), and Production (P). It handles three types of database objects: **tables**, **views**, and **stored procedures**.

The framework consists of five scripts that work together:

- **`.load_modules.ps1`** — The entry point that loads all other scripts into the session.
- **`classes.ps1`** — Defines data structures used to represent database tables and columns in memory.
- **`functions.ps1`** — Contains all core logic: reading SQL files, querying the database, comparing structures, generating scripts, and executing deployments.
- **`build_and_publish.ps1`** — Orchestrates the build and deployment process using the functions defined in `functions.ps1`.
- **`process_data.ps1`** — Executes stored procedures to process CSV data (ingestion, transformation, preparation) and validates the outcome via log table inspection.

The typical workflow is: load modules → compare file definitions to database → generate SQL change scripts → (optionally) execute those scripts → process data.

---

## Hierarchical Structure

### Level 1 — Entry Point

#### `.load_modules.ps1`

Initialises the framework by dot-sourcing all required scripts into the current PowerShell session. This makes all classes, functions, and logic available for use. It must be run first.

---

### Level 2 — Data Structures

#### `classes.ps1`

Defines two PowerShell classes used as in-memory data structures:

- **`cl_column`** — Represents a single database column (name, data type, length, precision, scale, nullability, default value, identity flag, ordinal position).
- **`cl_table`** — Represents a full table (database, schema, table name) containing collections of columns, indexes, and constraints.

**Example:**

```powershell
$col = [cl_column]::new()
$col.ColumnName     = "customer_id"
$col.DataType       = "INT"
$col.IsNullable     = $false
$col.IsIdentity     = $true
$col.OrdinalPosition = 1
```

---

### Level 3 — Core Functions

#### `functions.ps1`

Contains all reusable functions grouped by responsibility:

**Schema Inventory**
- `ps_get_sql_file_inventory` — Scans folders for SQL files and builds an inventory of object definitions.
- `ps_get_sql_objt_inventory` — Queries the database for existing objects and compares modification dates with local files.

**Schema Comparison & Script Generation**
- `ps_generate_table_alter_script` — Generates a four-step ALTER sequence (rename → recreate → copy data → drop old) when a table structure has changed.
- `ps_assesment_of_conversion` — Validates whether a data type change is safe, risky, or blocked before generating a conversion script.

**Example — safe conversion check:**

```powershell
$source = [PSCustomObject]@{ datatype="VARCHAR"; maxlength=100; precision=0; scale=0 }
$target = [PSCustomObject]@{ datatype="VARCHAR"; maxlength=200; precision=0; scale=0 }
$result = ps_assesment_of_conversion -ip_source_datatype $source -ip_target_datatype $target
# $result.RiskLevel => "None" (safe expansion)
```

**Database Connectivity**
- `ps_sql_connection` — Opens an ODBC connection to Teradata with retry logic (max 3 attempts).
- `ps_sql_command` — Creates a configured SQL command object with no timeout.
- `ps_exec_sql_query_statement` — Executes a SELECT query and returns results as a DataTable.
- `ps_exec_sql_non_query_statement` — Executes DDL/DML statements (CREATE, ALTER, DROP, INSERT) with retry logic.
- `ps_exec_sql_query_to_file` — Streams large query results directly to a delimited file row-by-row.

**SQL Text Processing**
- `ps_remove_comments` — Strips `--` and `/* */` comments from SQL while preserving quoted strings.
- `ps_minify_sql` — Compresses SQL by removing whitespace and comments for comparison purposes.
- `ps_get_sql_statements` — Reads generated SQL files from the build folder for execution.
- `ps_get_table_def_from_sql_statement` — Parses a CREATE TABLE statement into a `cl_table` object.
- `ps_get_table_def_from_sql_database` — Queries `DBC.ColumnsV` to retrieve a table's structure as a `cl_table` object.

**Credential Management & Logging**
- `get_credentials` — Securely stores and retrieves database credentials using encrypted XML in the user profile.
- `ps_log_error` — Appends detailed error information (message, type, stack trace, SQL) to a log file.

---

### Level 4 — Orchestration

#### `build_and_publish.ps1`

Contains two functions that orchestrate the deployment:

- **`ps_build_and_publish`** — The main function. Compares file definitions to the database, generates SQL scripts for tables (CREATE/ALTER), views, and procedures, and optionally executes them. Supports flags to exclude object types or skip DROP statements.
- **`ps_publish`** — Executes the generated SQL scripts from the build folder sequentially, with retry logic and progress tracking.

**Example call:**

```powershell
ps_build_and_publish -ip_cd_environment "T" -ip_publish -ip_excl_drop_objects
# Deploys to Test environment, executes scripts, skips DROP statements
```

---

### Level 5 — Data Processing

#### `process_data.ps1`

Contains one function:

- **`ps_process_data`** — Connects to the target database, executes `generic_usp_process_group_all(1)` to trigger all ingestion, transformation, and preparation stored procedures, then queries the log table to check for errors. Halts execution if errors are found.

**Example call:**

```powershell
ps_process_data -ip_cd_environment "A"
# Runs full data processing pipeline in Acceptance environment
```

---

## Key Features

| Feature | Description |
|---|---|
| **Multi-environment support** | Targets O/T/A/P environments via a single parameter |
| **File-to-database comparison** | Compares local SQL definitions against live database objects |
| **Safe ALTER generation** | Four-step rename/recreate/copy/drop pattern prevents data loss during table changes |
| **Data type conversion validation** | Assesses risk (None/Low/Medium/High/Blocked) before allowing type changes |
| **Retry logic** | All database operations retry up to 3 times with progressive delays |
| **Credential security** | Credentials are encrypted and stored locally; never hardcoded |
| **Large dataset streaming** | Results are streamed row-by-row to file, avoiding memory overload |
| **Error logging** | All failures are logged with full context (SQL, stack trace, timestamp) |
| **Selective deployment** | Flags allow excluding tables, views, procedures, or DROP statements |
| **Post-deployment validation** | Log table is queried after data processing to confirm success |

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-2-powershell-summery.txt](./../.ai_prompts/level-2-powershell-summery.txt)

*end of document*
