# Documentation: `viw_environment.sql` [Back](./../metadata.md)

## Description

Constructs a single-row environment record by combining deployment parameters with the physical database name resolved from `DBC.TablesV`. Maps the configured environment code, name, and Git remote URL alongside the resolved database name and target prefix. Used to populate `metadata_tbl_environment`.

## Output Columns

| Order | Is Primary Key | Name                  | Datatype     | Is Nullable | Functional Description                                                                     |
|------:|:--------------:|:----------------------|:-------------|:-----------:|:-------------------------------------------------------------------------------------------|
|     1 | -              | `id_environment`      | CHAR(64)     | No          | SHA-256 hash of `${cd_environment}`. Unique environment identifier.                        |
|     2 | -              | `cd_environment`      | VARCHAR(32)  | No          | Environment code from deployment parameter `${cd_environment}` (e.g. `DEV`, `PRD`).        |
|     3 | -              | `nm_environment`      | VARCHAR(128) | No          | Full environment name from deployment parameter `${nm_environment}`.                       |
|     4 | -              | `tx_git_remote`       | VARCHAR(128) | No          | Git remote URL for the source code repository associated with this environment.            |
|     5 | -              | `nm_database`         | VARCHAR(128) | No          | Physical database name resolved from `DBC.TablesV` matching the target prefix.             |
|     6 | -              | `nm_database_target`  | VARCHAR(128) | No          | Database target prefix from deployment parameter `${nm_database_target}`.                  |

## Example in Utilization of this View

<details>
<summary>Example 1 – Retrieve the current environment record</summary>

```sql
-- Example 1: Query the environment view to inspect the current deployment environment
SELECT
    env.id_environment,
    env.cd_environment,
    env.nm_environment,
    env.nm_database,
    env.nm_database_target,
    env.tx_git_remote
FROM  ${nm_database_target}metadata_viw_environment AS env;
```

</details>

<details>
<summary>Example 2 – Compare view output against the stored environment table</summary>

```sql
-- Example 2: Validate that the view output matches what is stored in the environment table
SELECT
    vw.cd_environment   AS vw_cd_environment,
    tbl.cd_environment  AS tbl_cd_environment,
    vw.nm_environment   AS vw_nm_environment,
    tbl.nm_environment  AS tbl_nm_environment,
    vw.nm_database      AS vw_nm_database,
    tbl.nm_database     AS tbl_nm_database
FROM      ${nm_database_target}metadata_viw_environment  AS vw
LEFT JOIN ${nm_database_target}metadata_tbl_environment  AS tbl
ON        tbl.id_environment = vw.id_environment;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-b-of-sql-view-definition.md](./../../../ai_prompts/documentation-sql-related/level-1-b-of-sql-view-definition.md)

*end of document*
