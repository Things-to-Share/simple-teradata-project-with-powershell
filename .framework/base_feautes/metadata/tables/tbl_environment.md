# Documentation: `tbl_environment.sql` [Back](./../metadata.md)

## Description

Stores environment-level metadata for each deployment target within the data platform. Each record uniquely identifies an environment by its code and descriptive name, and links it to the physical database name and database target prefix. The table is populated from `viw_environment` and acts as the top-level reference for environment-aware processing across the metadata framework.

## Table Structure

| Order | Is Primary Key | Name                  | Datatype     | Is Nullable | Functional Description                                                                    |
|------:|:--------------:|:----------------------|:-------------|:-----------:|:------------------------------------------------------------------------------------------|
|     1 | Yes            | `id_environment`      | CHAR(64)     | No          | Unique environment identifier; SHA-256 hash of the environment code.                      |
|     2 | No             | `cd_environment`      | VARCHAR(32)  | No          | Short environment code (e.g. `DEV`, `TST`, `PRD`).                                        |
|     3 | No             | `nm_environment`      | VARCHAR(128) | No          | Full descriptive name of the environment.                                                 |
|     4 | No             | `tx_git_remote`       | VARCHAR(999) | Yes         | URL of the Git remote repository associated with this environment.                        |
|     5 | No             | `nm_database`         | VARCHAR(128) | No          | Physical database name (resolved from DBC catalog) for this environment.                  |
|     6 | No             | `nm_database_target`  | VARCHAR(128) | No          | Database target prefix used to scope all objects in this environment.                     |
|     7 | No             | `meta_dt_created_at`  | TIMESTAMP    | Yes         | Record creation timestamp; defaults to `CURRENT_TIMESTAMP`.                               |

## Example in Utilization of this Table

<details>
<summary>Example 1 – Retrieve all registered environments</summary>

```sql
-- Example 1: List all environments with their database mapping
SELECT
    env.cd_environment,
    env.nm_environment,
    env.nm_database,
    env.nm_database_target,
    env.tx_git_remote,
    env.meta_dt_created_at
FROM  ${nm_database_target}metadata_tbl_environment AS env
ORDER BY env.cd_environment;
```

</details>

<details>
<summary>Example 2 – Look up a specific environment by code</summary>

```sql
-- Example 2: Retrieve the environment record for a specific environment code
SELECT
    env.id_environment,
    env.cd_environment,
    env.nm_environment,
    env.nm_database,
    env.nm_database_target,
    env.tx_git_remote
FROM  ${nm_database_target}metadata_tbl_environment AS env
WHERE env.cd_environment = 'PRD';
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.md](./../ai_prompts/documentation-sql-related/level-1-a-of-sql-table-or-view-definition.md)

*end of document*
