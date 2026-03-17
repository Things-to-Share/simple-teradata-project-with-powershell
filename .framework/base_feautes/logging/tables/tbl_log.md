# Functional Description of `logging_tbl_log` [back](../../../.base_feautes.md)

## Purpose

The `logging_tbl_log` table is designed to store comprehensive logging information for application processes and procedures. It captures detailed data about each log entry, including unique identifiers, procedure names, messages, start and end times, error information, and dynamic SQL execution. This table is crucial for monitoring, debugging, and auditing application activities, providing a centralized repository for tracking the execution flow and performance of various procedures.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|----------------|------|----------|-------------|-------------|
| 1 | Yes | id_log | CHAR(64) | No | Unique identifier for each log entry |
| 2 | No | id_log_parent | CHAR(64) | Yes | Identifier of the parent log entry, for nested logging |
| 3 | No | procedure_code | VARCHAR(128) | Yes | Name or code of the procedure being logged |
| 4 | No | message_text | VARCHAR(999) | Yes | Descriptive message for the log entry |
| 5 | No | log_start | TIMESTAMP | Yes | Start time of the logged procedure |
| 6 | No | log_ended | TIMESTAMP | Yes | End time of the logged procedure |
| 7 | No | affected | INT | Yes | Number of rows or items affected by the procedure |
| 8 | No | error_text | VARCHAR(2000) | Yes | Error message if the procedure encountered an error |
| 9 | No | dynamic_sql_text | VARCHAR(32000) | Yes | Dynamic SQL executed by the procedure, if applicable |
| 10 | No | meta_dt_created_at | TIMESTAMP | Yes | Timestamp of when the log entry was created, defaults to current time |

## Usage

- Track the execution of procedures and processes within the application
- Monitor the duration of procedures using start and end timestamps
- Identify and analyze errors occurring during procedure execution
- Audit the impact of procedures through the 'affected' count
- Facilitate debugging by storing dynamic SQL statements executed
- Support hierarchical logging with parent-child relationships between log entries
- Provide a historical record of application activities for performance analysis and optimization
- Aid in system diagnostics and troubleshooting by offering detailed execution context

---

**Utilized ASN GPT Prompt**

<details>
<summary>The prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "View" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_tbl_" is the functional schema name

Can you create short functional description of the following table definition, Handlingthe following topics
title should follow the this template "Functional Description of `<name-of-the-table>`".

- The document structure handle the following topic, in the given order
  - Purpose (Short description of table purpos, max 200 words, DO NOT make it longer then needed)
  - Structure (present in table format with column for Order, Is Primarykey, Name, Datatype, Is Nullable, Description)
  - Usage (bullet points on utilization of the table)

</details>

*end of document*