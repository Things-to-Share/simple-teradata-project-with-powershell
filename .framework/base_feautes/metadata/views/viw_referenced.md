# Documentation: `viw_referenced.sql` [Back](./../metadata.md)

## Description

Detects upstream table dependencies by scanning the view SQL text stored in `tbl_table`. For each table, checks all other tracked table names against the view body using `LIKE` pattern matching. Returns directed dependency edges (dependent → referenced). Used to populate `metadata_tbl_referenced`, which in turn feeds `viw_process_group` for process group calculation.

## Output Columns

| Order | Is Primary Key | Name                    | Datatype  | Is Nullable | Functional Description                                                                               |
|------:|:--------------:|:------------------------|:----------|:-----------:|:-----------------------------------------------------------------------------------------------------|
|     1 | -              | `id_table`              | CHAR(64)  | Yes         | SHA-256 identifier of the dependent (referencing) table.                                             |
|     2 | -              | `id_table_referenced`   | CHAR(64)  | Yes         | SHA-256 identifier of the upstream table found in the view SQL. NULL if no reference found.          |

## Example in Utilization of this View

<details>
<summary>Example 1 – List all detected dependency edges</summary>

```sql
-- Example 1: Show all table-to-table dependency relationships with human-readable names
SELECT
    tbl.nm_schema          AS nm_schema_dependent,
    tbl.nm_table           AS nm_table_dependent,
    up.nm_schema           AS nm_schema_upstream,
    up.nm_table            AS nm_table_upstream
FROM      ${nm_database_target}metadata_viw_referenced AS ref
JOIN      ${nm_database_target}metadata_tbl_table      AS tbl
ON        tbl.id_table  = ref.id_table
LEFT JOIN ${nm_database_target}metadata_tbl_table      AS up
ON        up.id_table   = ref.id_table_referenced
WHERE     ref.id_table_referenced IS NOT NULL
ORDER BY  tbl.nm_schema,
          tbl.nm_table;
```

</details>

<details>
<summary>Example 2 – Find all tables that depend on a specific upstream table</summary>

```sql
-- Example 2: Identify all tables whose view SQL references a specific upstream table
SELECT
    tbl.nm_schema  AS nm_schema_dependent,
    tbl.nm_table   AS nm_table_dependent,
    up.nm_schema   AS nm_schema_upstream,
    up.nm_table    AS nm_table_upstream
FROM      ${nm_database_target}metadata_viw_referenced AS ref
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
**Prompt Used:** [level-1-b-of-sql-table-or-view-definition.md](./../.ai_prompts/documentation-sql-related/level-1-b-of-sql-view-or-view-definition.md)

*end of document*



```sql
