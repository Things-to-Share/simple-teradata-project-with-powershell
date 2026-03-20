# Documentation: `tbl_column.sql` [Back](./../metadata.md)

## Description

Stores column-level metadata for all tracked tables within the target database. Each record describes a single column, capturing its physical name, functional name, description, data type, ordinal position, nullability, and business key membership. The table is populated from the corresponding metadata view (`viw_column`) and is a core part of the metadata framework used for data lineage and data catalogue purposes.

## Table Structure

| Order | Is Primary Key | Name                  | Datatype      | Is Nullable | Functional Description                                                          |
|------:|:--------------:|:----------------------|:--------------|:-----------:|:--------------------------------------------------------------------------------|
|     1 | Yes            | `id_table`            | CHAR(64)      | No          | Foreign key to `metadata_tbl_table`; SHA-256 hash of database + table name.     |
|     2 | Yes            | `id_column`           | CHAR(64)      | No          | Unique column identifier; SHA-256 hash of database + table + column name.       |
|     3 | No             | `nm_column`           | VARCHAR(128)  | No          | Physical column name as registered in the database.                             |
|     4 | No             | `fn_column`           | VARCHAR(128)  | No          | Functional (business) name of the column.                                       |
|     5 | No             | `fd_column`           | VARCHAR(1024) | No          | Functional description of the column's business meaning.                        |
|     6 | No             | `cd_datatype`         | VARCHAR(32)   | No          | Column data type code (e.g. `VARCHAR(128)`, `INTEGER`, `DATE`).                 |
|     7 | No             | `ni_ordering`         | INT           | No          | Ordinal position of the column within its parent table.                         |
|     8 | No             | `is_nullable`         | INT           | No          | Nullability flag: `1` = nullable, `0` = not nullable.                           |
|     9 | No             | `is_businesskey`      | INT           | No          | Business key flag: `1` = part of business key, `0` = not.                       |
|    10 | No             | `meta_dt_created_at`  | TIMESTAMP     | Yes         | Record creation timestamp; defaults to `CURRENT_TIMESTAMP`.                     |

## Example in Utilization of this Table

<details>
<summary>Example 1 – Retrieve all column metadata for a specific table</summary>

```sql
-- Example 1: Retrieve all columns for a specific table, ordered by position
SELECT
    col.id_table,
    col.id_column,
    col.nm_column,
    col.fn_column,
    col.fd_column,
    col.cd_datatype,
    col.ni_ordering,
    col.is_nullable,
    col.is_businesskey,
    col.meta_dt_created_at
FROM  ${nm_database_target}metadata_tbl_column AS col
WHERE col.id_table = (
    SELECT id_table
    FROM   ${nm_database_target}metadata_tbl_table
    WHERE  nm_schema = 'inbound'
    AND    nm_table  = 'tbl_customer'
)
ORDER BY col.ni_ordering;
```

</details>

<details>
<summary>Example 2 – Retrieve all business key columns with their table context</summary>

```sql
-- Example 2: List all business key columns joined with their parent table
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    col.nm_column,
    col.fn_column,
    col.cd_datatype,
    col.ni_ordering
FROM      ${nm_database_target}metadata_tbl_column AS col
JOIN      ${nm_database_target}metadata_tbl_table  AS tbl
ON        tbl.id_table       = col.id_table
WHERE     col.is_businesskey = 1
ORDER BY  tbl.nm_schema,
          tbl.nm_table,
          col.ni_ordering;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.md](./../ai_prompts/documentation-sql-related/level-1-a-of-sql-table-or-view-definition.md)

*end of document*
