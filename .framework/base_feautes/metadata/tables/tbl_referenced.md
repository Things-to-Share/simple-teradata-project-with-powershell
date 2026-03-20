# Documentation: `tbl_referenced.sql` [Back](./../metadata.md)

## Description

Stores the directed dependency edges between tracked tables. Each record links a table (`id_table`) to another table it depends on (`id_table_referenced`), as detected from the view SQL text by `viw_referenced`. This edge list is the input for process group calculation in `viw_process_group` and enables data lineage and impact analysis across the metadata framework.

## Table Structure

| Order | Is Primary Key | Name                   | Datatype     | Is Nullable | Functional Description                                                                        |
|------:|:--------------:|:-----------------------|:-------------|:-----------:|:----------------------------------------------------------------------------------------------|
|     1 | Yes            | `id_table`             | CHAR(64)     | No          | SHA-256 hash identifier of the dependent table (the table that references another).           |
|     2 | Yes            | `id_table_referenced`  | VARCHAR(128) | Yes         | SHA-256 hash identifier of the upstream table being referenced. NULL if no dependency found.  |
|     3 | No             | `meta_dt_created_at`   | TIMESTAMP    | Yes         | Record creation timestamp; defaults to `CURRENT_TIMESTAMP`.                                   |

## Example in Utilization of this Table

<details>
<summary>Example 1 – List all dependency edges</summary>

```sql
-- Example 1: Show all table-to-table dependency relationships
SELECT
    ref.id_table,
    tbl.nm_schema          AS nm_schema,
    tbl.nm_table           AS nm_table,
    ref.id_table_referenced,
    up.nm_schema           AS nm_schema_referenced,
    up.nm_table            AS nm_table_referenced
FROM      ${nm_database_target}metadata_tbl_referenced AS ref
JOIN      ${nm_database_target}metadata_tbl_table      AS tbl
ON        tbl.id_table = ref.id_table
LEFT JOIN ${nm_database_target}metadata_tbl_table      AS up
ON        up.id_table  = ref.id_table_referenced
ORDER BY  tbl.nm_schema,
          tbl.nm_table;
```

</details>

<details>
<summary>Example 2 – Find all tables that depend on a specific table</summary>

```sql
-- Example 2: Identify all tables that reference a specific upstream table
SELECT
    tbl.nm_schema  AS nm_schema_dependent,
    tbl.nm_table   AS nm_table_dependent,
    up.nm_schema   AS nm_schema_upstream,
    up.nm_table    AS nm_table_upstream
FROM      ${nm_database_target}metadata_tbl_referenced AS ref
JOIN      ${nm_database_target}metadata_tbl_table      AS tbl
ON        tbl.id_table  = ref.id_table
JOIN      ${nm_database_target}metadata_tbl_table      AS up
ON        up.id_table   = ref.id_table_referenced
WHERE     up.nm_schema  = 'inbound'
AND       up.nm_table   = 'tbl_customer'
ORDER BY  tbl.nm_schema,
          tbl.nm_table;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.md](./../ai_prompts/documentation-sql-related/level-1-a-of-sql-table-or-view-definition.md)

*end of document*
