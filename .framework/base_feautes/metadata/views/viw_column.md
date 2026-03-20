# Documentation: `viw_column.sql` [Back](./../metadata.md)

## Description

Extracts column-level metadata from the Teradata system catalog (`DBC.ColumnsV`, `DBC.TablesV`) for all non-metadata columns within the target database. Computes human-readable data type labels, nullability, ordinal position, and business key membership by cross-referencing the Primary Index definition (`DBC.IndicesV`). Generates SHA-256 hash identifiers for both table and column. Used to populate `metadata_tbl_column`.

## Output Columns

| Order | Is Primary Key | Name             | Datatype      | Is Nullable | Functional Description                                                                              |
|------:|:--------------:|:-----------------|:--------------|:-----------:|:----------------------------------------------------------------------------------------------------|
|     1 | -              | `id_table`       | CHAR(64)      | No          | SHA-256 hash of database + table name. Logical foreign key to `tbl_table`.                          |
|     2 | -              | `id_column`      | CHAR(64)      | No          | SHA-256 hash of database + table + column name. Uniquely identifies the column.                     |
|     3 | -              | `nm_column`      | VARCHAR(128)  | No          | Physical column name as registered in the database catalog.                                         |
|     4 | -              | `fn_column`      | VARCHAR(128)  | No          | Functional name; sourced from JSON comment (`$.fn`). Defaults to `'n/a'`.                           |
|     5 | -              | `fd_column`      | VARCHAR(1024) | No          | Functional description; sourced from JSON comment (`$.fd`). Defaults to `'n/a'`.                    |
|     6 | -              | `cd_datatype`    | VARCHAR(32)   | No          | Human-readable data type string (e.g. `VARCHAR(128)`, `INTEGER`, `DATE`) derived from type codes.   |
|     7 | -              | `ni_ordering`    | INT           | No          | Ordinal column position within the parent table.                                                    |
|     8 | -              | `is_nullable`    | INT           | No          | Nullability flag: `1` = nullable, `0` = not nullable.                                               |
|     9 | -              | `is_businesskey` | INT           | No          | Business key flag: `1` = part of Primary Index, `0` = not.                                          |

## Example in Utilization of this View

<details>
<summary>Example 1 – Retrieve all columns for a specific table</summary>

```sql
-- Example 1: List all columns for a specific table with metadata, ordered by position
SELECT
    col.nm_column,
    col.fn_column,
    col.fd_column,
    col.cd_datatype,
    col.ni_ordering,
    col.is_nullable,
    col.is_businesskey
FROM  ${nm_database_target}metadata_viw_column AS col
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
<summary>Example 2 – List all business key columns across all tables</summary>

```sql
-- Example 2: Retrieve all business key columns joined with their parent table context
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    col.nm_column,
    col.fn_column,
    col.cd_datatype,
    col.ni_ordering
FROM      ${nm_database_target}metadata_viw_column AS col
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
**Prompt Used:** [level-1-b-of-sql-view-definition.md](./../../../ai_prompts/documentation-sql-related/level-1-b-of-sql-view-definition.md)

*end of document*
