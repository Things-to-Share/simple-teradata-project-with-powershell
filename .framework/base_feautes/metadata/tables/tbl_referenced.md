# Functional Description of `metadata_tbl_referenced`

## Purpose

The `metadata_tbl_referenced` table serves as a metadata repository within the metadata functional schema to track table dependencies and references. This table maintains relationships between tables by storing which tables are referenced by other tables, creating a dependency mapping system. It enables the identification of table hierarchies, supports impact analysis, and helps in understanding data lineage across the database environment.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|---------------|------|----------|-------------|-------------|
| 1 | Yes | id_table | CHAR(64) | No | Identifier of the table that references another table, part of composite primary key |
| 2 | Yes | id_table_referenced | VARCHAR(128) | Yes | Identifier of the table being referenced, part of composite primary key |
| 3 | No | meta_dt_created_at | TIMESTAMP | No | Timestamp when the reference relationship was created, defaults to current timestamp |

## Usage

• Table dependency mapping and relationship tracking
• Data lineage analysis and impact assessment for schema changes
• Supporting ETL process sequencing based on table dependencies
• Identifying circular references and dependency loops
• Database documentation and metadata management
• Change impact analysis for table modifications or deletions
• Supporting automated processing order determination

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