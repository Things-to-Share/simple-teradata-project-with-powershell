# Functional Description of `metadata_tbl_process_group`

## Purpose

The `metadata_tbl_process_group` table serves as a metadata repository within the metadata functional schema to manage and track table groupings for processing purposes. This table maintains information about database tables, their schema associations, and assigns them to specific process groups for organized batch processing or ETL operations. It also tracks circular reference indicators to help identify potential dependency issues during processing workflows.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|---------------|------|----------|-------------|-------------|
| 1 | Yes | id_table | CHAR(64) | No | Unique identifier for the table record, used as primary key |
| 2 | No | nm_schema | VARCHAR(128) | Yes | Name of the database schema containing the table |
| 3 | No | nm_table | VARCHAR(128) | No | Name of the database table |
| 4 | No | ni_process_group | INT | Yes | Numeric identifier for the process group assignment |
| 5 | No | is_circular_referenced | INT | Yes | Flag indicating if the table has circular references (0/1 or NULL) |
| 6 | No | meta_dt_created_at | TIMESTAMP | No | Timestamp when the record was created, defaults to current timestamp |

## Usage

• Process group management for batch processing and ETL workflow organization
• Table dependency tracking and circular reference detection
• Schema and table catalog maintenance within processing frameworks
• Supporting data lineage and impact analysis operations
• Enabling parallel processing by grouping tables into logical processing units
• Audit trail maintenance for process group assignments and modifications

---

**Utilized ASN GPT Prompt**

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "Table" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_tbl_" is the functional schema name

Prompt:
Act like a Teradat SQL expert: 
- Provide functional descption of the "Table" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_tbl_" is the functional schema name

Can you create short functional description of the following table definition, Handlingthe following topics
title should follow the this template "Functional Description of `<name-of-the-table>`".

- The document structure handle the following topic, in the given order
  - Purpose (Short description of table purpos, max 200 words, DO NOT make it longer then needed)
  - Structure (present in table format with column for Order, Is Primarykey, Name, Datatype, Is Nullable, Description)
  - Usage (bullet points on utilization of the table)
- At the End of the document after the Examples, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - calapsable text block with the used ASN GPT prompt, title "the prompt" without everthing after "Table definition:"
  - Add final blank line
  - Add the text "*end of document*"
  - Add final blank line

</details>

*end of document*