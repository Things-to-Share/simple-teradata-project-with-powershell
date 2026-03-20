# Documentation: `tbl_table.sql` [Back](./../metadata.md)

## Description

Central metadata catalogue table for all tracked tables within the target database. Each record represents one physical table, storing its functional schema, name, functional name and description, the name of the corresponding population view, and the full SQL text of that view. The view SQL is used by `viw_referenced` to detect upstream dependencies. Populated from `viw_table`.

## Table Structure

| Order | Is Primary Key | Name                 | Datatype      | Is Nullable | Functional Description                                                                              |
|------:|:--------------:|:---------------------|:--------------|:-----------:|:----------------------------------------------------------------------------------------------------|
|     1 | Yes            | `id_table`           | CHAR(64)      | No          | Unique table identifier; SHA-256 hash of database + table name.                                     |
|     2 | No             | `nm_schema`          | VARCHAR(128)  | Yes         | Functional schema name (e.g. `inbound`, `intermediate`, `delivery`).                                |
|     3 | No             | `nm_table`           | VARCHAR(128)  | No          | Physical table name within the schema (e.g. `tbl_customer`).                                        |
|     4 | No             | `fn_table`           | VARCHAR(128)  | Yes         | Functional (business) name of the table. Sourced from JSON comment on the table object.             |
|     5 | No             | `fd_table`           | VARCHAR(1024) | Yes         | Functional description of the table's business meaning. Sourced from JSON comment on the table.     |
|     6 | No             | `nm_view`            | VARCHAR(128)  | No          | Name of the view used to populate this table (derived by replacing `_tbl_` with `_viw_`).           |
|     7 | No             | `tx_view`            | VARCHAR(25000)| No          | Full SQL text of the population view; used by `viw_referenced` for dependency detection.            |
|     8 | No             | `meta_dt_created_at` | TIMESTAMP     | Yes         | Record creation timestamp; defaults to `CURRENT_TIMESTAMP`.                                         |

## Example in Utilization of this Table

<details>
<summary>Example 1 – List all tables with their functional names per schema</summary>

```sql
-- Example 1: Retrieve all tracked tables with functional metadata, ordered by schema and table
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    tbl.fn_table,
    tbl.fd_table,
    tbl.nm_view
FROM  ${nm_database_target}metadata_tbl_table AS tbl
ORDER BY tbl.nm_schema,
         tbl.nm_table;
```

</details>

<details>
<summary>Example 2 – Look up the view SQL for a specific table</summary>

```sql
-- Example 2: Retrieve the population view SQL for a specific table
SELECT
    tbl.nm_schema,
    tbl.nm_table,
    tbl.nm_view,
    tbl.tx_view
FROM  ${nm_database_target}metadata_tbl_table AS tbl
WHERE tbl.nm_schema = 'inbound'
AND   tbl.nm_table  = 'tbl_customer';
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.md](./../ai_prompts/documentation-sql-related/level-1-a-of-sql-table-or-view-definition.md)

*end of document*
