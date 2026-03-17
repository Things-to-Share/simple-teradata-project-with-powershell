# Functional Description of `metadata_tbl_table`

## Purpose

The metadata_tbl_table serves as a central metadata repository within the MBDT database system. This table stores comprehensive information about database tables and their associated views, acting as a data catalog that maintains both technical specifications and functional descriptions. It captures essential metadata including table identifiers, schema information, functional names and descriptions, along with the complete SQL definitions of views used to populate tables. This enables effective data governance, lineage tracking, and impact analysis across the database ecosystem.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|----------------|------|----------|-------------|-------------|
| 1 | Yes | id_table | CHAR(64) | No | Hash (SHA256) of the nm_table |
| 2 | No | nm_schema | VARCHAR(128) | Yes | Technical Name of the (virtual) Schema |
| 3 | No | nm_table | VARCHAR(128) | No | Technical Name of the Table |
| 4 | No | fn_table | VARCHAR(128) | Yes | Functional Name of the Table |
| 5 | No | fd_table | VARCHAR(1024) | Yes | Functional Description of the Table |
| 6 | No | nm_view | VARCHAR(128) | No | Technical name of the View that is used to populate the table |
| 7 | No | tx_view | VARCHAR(25000) | No | The SQL Create Statement of the View, will be used to determine the references |
| 8 | No | meta_dt_created_at | TIMESTAMP | No | Timestamp when the record was created (defaults to current timestamp) |

## Usage

- Serves as a central metadata catalog for all tables within the MBDT database system
- Stores both technical and functional information to support data governance initiatives
- Maintains SQL view definitions for comprehensive data lineage and dependency analysis
- Enables automated documentation generation and database object discovery
- Supports impact analysis by storing complete view SQL statements
- Facilitates schema management and understanding of data relationships
- Provides audit trail through creation timestamps for metadata changes
- Acts as a reference point for data stewards and analysts to understand table purposes and origins

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