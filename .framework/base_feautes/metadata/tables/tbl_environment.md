# Functional Description of `metadata_tbl_environment`

## Purpose

The `metadata_tbl_environment` table serves as a reference table within the metadata functional schema to store information about different database environments. This table maintains a catalog of environments with their unique identifiers, codes, descriptive names, and associated database names. It acts as a central registry for environment management, enabling consistent identification and referencing of various database environments across the system.

## Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Description |
|-------|---------------|------|----------|-------------|-------------|
| 1 | Yes | id_environment | CHAR(64) | No | Unique identifier for the environment, used as primary key |
| 2 | No | cd_environment | VARCHAR(32) | No | Environment code, typically a short abbreviation |
| 3 | No | nm_environment | VARCHAR(128) | No | Full descriptive name of the environment |
| 4 | No | nm_database | VARCHAR(128) | No | Name of the database associated with this environment |
| 5 | No | meta_dt_created_at | TIMESTAMP | No | Timestamp indicating when the record was created, defaults to current timestamp |

## Usage

• Environment catalog management and lookup operations
• Reference table for mapping environment codes to descriptive names
• Database environment identification in data lineage and metadata processes
• Supporting environment-specific configurations and deployments
• Audit trail maintenance through creation timestamp tracking
• Cross-referencing environments in ETL processes and data governance workflows

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
  -