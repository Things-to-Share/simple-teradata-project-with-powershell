# Documentation: `viw_process_group.sql` [Back](./../metadata.md)

## Description

Computes the process group number and circular reference flag for each tracked table by traversing the dependency graph stored in `tbl_referenced` up to 15 levels deep. A process group of `0` indicates no upstream dependencies; each additional dependency level adds `1`. Tables that reference themselves anywhere through the chain are flagged with `is_circular_referenced = 1`. Used to populate `metadata_tbl_process_group`, which drives ordered ETL execution.

## Output Columns

| Order | Is Primary Key | Name                     | Datatype     | Is Nullable | Functional Description                                                                          |
|------:|:--------------:|:-------------------------|:-------------|:-----------:|:------------------------------------------------------------------------------------------------|
|     1 | -              | `id_table`               | CHAR(64)     | No          | SHA-256 identifier of the table. Sources from `tbl_table`.                                      |
|     2 | -              | `nm_schema`              | VARCHAR(128) | Yes         | Functional schema name of the table (e.g. `inbound`, `intermediate`).                           |
|     3 | -              | `nm_table`               | VARCHAR(128) | No          | Physical table name within the schema.                                                          |
|     4 | -              | `ni_process_group`       | INT          | Yes         | Dependency depth: `0` = no upstream deps, increments per level. MAX taken across all paths.     |
|     5 | -              | `is_circular_referenced` | INT          | Yes         | `1` if a circular dependency is detected across any traversal path, `0` otherwise.              |

## Example in Utilization of this View

<details>
<summary>Example 1 – List all tables ordered by process group</summary>

```sql
-- Example 1: Retrieve all tables with their computed process group for ETL sequencing
SELECT
    pg.nm_schema,
    pg.nm_table,
    pg.ni_process_group,
    pg.is_circular_referenced
FROM  ${nm_database_target}metadata_viw_process_group AS pg
ORDER BY pg.ni_process_group,
         pg.nm_schema,
         pg.nm_table;
```

</details>

<details>
<summary>Example 2 – Identify tables with circular references</summary>

```sql
-- Example 2: List all tables flagged as having a circular dependency
SELECT
    pg.nm_schema,
    pg.nm_table,
    pg.ni_process_group,
    pg.is_circular_referenced
FROM  ${nm_database_target}metadata_viw_process_group AS pg
WHERE pg.is_circular_referenced = 1
ORDER BY pg.nm_schema,
         pg.nm_table;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-b-of-sql-table-or-view-definition.md](./../.ai_prompts/documentation-sql-related/level-1-b-of-sql-view-or-view-definition.md)

*end of document*



```sql
