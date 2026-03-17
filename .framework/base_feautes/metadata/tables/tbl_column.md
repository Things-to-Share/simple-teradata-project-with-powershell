# Functional Description of `metadata_tbl_column`

## Purpose

The metadata_tbl_column table serves as a detailed column-level metadata repository within the MBDT database system. This table stores comprehensive information about individual columns across all tables, including technical specifications, functional descriptions, data types, and business classifications. It acts as a complementary catalog to the metadata_tbl_table, providing granular column-level metadata that supports data governance, documentation, and analytical activities by maintaining both technical and business context for each column.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|----------------|------|----------|-------------|-------------|
| 1 | Yes | id_table | CHAR(64) | No | Foreign key reference to the parent table identifier |
| 2 | Yes | id_column | CHAR(64) | No | Unique identifier for the column |
| 3 | No | nm_column | VARCHAR(128) | No | Technical name of the column |
| 4 | No | fn_column | VARCHAR(128) | No | Functional name of the column |
| 5 | No | fd_column | VARCHAR(1024) | No | Functional description of the column |
| 6 | No | cd_datatype | VARCHAR(32) | No | Data type code of the column |
| 7 | No | ni_ordering | INT | No | Ordering number/position of the column within the table |
| 8 | No | is_nullable | INT | No | Flag indicating if the column allows null values (0/1) |
| 9 | No | is_businesskey | INT | No | Flag indicating if the column is part of a business key (0/1) |
| 10 | No | meta_dt_created_at | TIMESTAMP | No | Timestamp when the record was created (defaults to current timestamp) |

## Usage

- Provides detailed column-level metadata for all tables within the MBDT database system
- Supports data discovery and understanding through functional names and descriptions
- Enables data governance through comprehensive column documentation
- Facilitates data quality assessments by tracking nullable and business key classifications
- Supports automated data lineage and impact analysis at the column level
- Assists in data modeling and schema design activities
- Provides reference information for data analysts and developers
- Enables automated documentation generation for database schemas
- Supports data dictionary creation and maintenance

---

**Utilized ASN GPT Prompt**

<details>
<summary>The prompt</summary>

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