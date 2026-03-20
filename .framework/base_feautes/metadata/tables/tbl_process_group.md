# Documentation: `tbl_process_group.sql` [Back](./../metadata.md)

## Description

Stores the computed process group assignment and circular reference flag for each tracked table. Process group numbers are derived from dependency depth — tables with no upstream dependencies are group 0, and each additional dependency level increments the group. This enables ordered, dependency-safe execution of ETL loads. Populated from `viw_process_group`.

## Table Structure

| Order | Is Primary Key | Name                    | Datatype     | Is Nullable | Functional Description                                                                         |
|------:|:--------------:|:------------------------|:-------------|:-----------:|:-----------------------------------------------------------------------------------------------|
|     1 | Yes            | `id_table`              | CHAR(64)     | No          | Foreign key to `metadata_tbl_table`; SHA-256 hash of database + table name.                    |
|     2 | No             | `nm_schema`             | VARCHAR(128) | Yes         | Functional schema name of the table (e.g. `inbound`, `intermediate`).                          |
|     3 | No             | `nm_table`              | VARCHAR(128) | No          | Physical table name within the schema.                                                         |
|     4 | No             | `ni_process_group`      | INT          | Yes         | Numeric process group; higher values indicate deeper dependency chains. NULL if undetermined.  |
|     5 | No             | `is_circular_referenced`| INT          | Yes         | Circular reference flag: `1` = circular dependency detected, `0` = none, `NULL` = unknown.     |
|     6 | No             | `meta_dt_created_at`    | TIMESTAMP    | Yes         | Record creation timestamp; defaults to `CURRENT_TIMESTAMP`.                                    |

## Example in Utilization of this Table

<details>
<summary>Example 1 – List all tables ordered by process group</summary>

```sql
-- Example 1: Retrieve all tables with their process group, ordered for sequential execution
SELECT
    pg.nm_schema,
    pg.nm_table,
    pg.ni_process_group,
    pg.is_circular_referenced
FROM  ${nm_database_target}metadata_tbl_process_group AS pg
ORDER BY pg.ni_process_group,
         pg.nm_schema,
         pg.nm_table;
```

</details>

<details>
<summary>Example 2 – Identify tables with circular references</summary>

```sql
-- Example 2: Find all tables flagged as circularly referenced
SELECT
    pg.nm_schema,
    pg.nm_table,
    pg.ni_process_group,
    pg.is_circular_referenced
FROM  ${nm_database_target}metadata_tbl_process_group AS pg
WHERE pg.is_circular_referenced = 1
ORDER BY pg.nm_schema,
         pg.nm_table;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.md](./../ai_prompts/documentation-sql-related/level-1-a-of-sql-table-or-view-definition.md)

*end of document*
