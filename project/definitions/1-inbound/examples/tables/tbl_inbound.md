# Documentation: `tbl_inbound.md` ([Back](../../examples.sql))

---

## 1. Description

The `examples_tbl_inbound` table serves as an inbound staging table within the `examples` schema. It is designed to capture incoming raw data records, storing both functional data attributes (`id`, `tx`, `dt`) and a comprehensive set of metadata attributes to support temporal validity tracking, record hashing, and auditing. The metadata columns enable bi-temporal data management patterns, allowing tracking of when records were technically valid and whether they represent the current state.

---

## 2. Table Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Functional Description |
|-------|---------------|------|----------|-------------|----------------------|
| 1 | ✅ | `id` | `BIGINT` | YES | Business identifier of the record |
| 2 | ❌ | `tx` | `VARCHAR(255)` | YES | Textual data attribute |
| 3 | ❌ | `dt` | `DATE` | YES | Date data attribute |
| 4 | ✅ | `meta_dt_tech_valid_start` | `TIMESTAMP` | NO | Technical valid start timestamp of the record |
| 5 | ❌ | `meta_dt_tech_valid_ended` | `TIMESTAMP` | NO | Technical valid end timestamp of the record |
| 6 | ❌ | `meta_is_actual` | `INT` | NO | Flag indicating if the record is the current/actual version (1=actual, 0=historical) |
| 7 | ❌ | `meta_ch_rh` | `CHAR(64)` | NO | Hash of the full record row |
| 8 | ❌ | `meta_ch_bk` | `CHAR(64)` | NO | Hash of the business key attributes |
| 9 | ❌ | `meta_ni_rn` | `INT` | NO | Row number within a business key partition |
| 10 | ❌ | `meta_ch_pk` | `CHAR(64)` | NO | Hash representing the primary key of the record |
| 11 | ❌ | `meta_dt_ceated_at` | `TIMESTAMP` | NO | Technical timestamp of when the record was inserted, defaults to current timestamp |

---

## 3. Example in Utilization of this Table

<details>
<summary>Example 1: Select current/actual records</summary>

```sql
-- Use find and replace to set: ${nm_database_target}
-- Example: retrieving all actual/current records from the inbound table

SELECT
     id
    ,tx
    ,dt
    ,meta_dt_tech_valid_start
    ,meta_dt_tech_valid_ended
    ,meta_is_actual
    ,meta_ch_rh
    ,meta_ch_bk
    ,meta_ni_rn
    ,meta_ch_pk
    ,meta_dt_ceated_at
FROM
    ${nm_database_target}examples_tbl_inbound
WHERE
    meta_is_actual = 1
;
```

</details>

<details>
<summary>Example 2: Select full history for a specific business key</summary>

```sql
-- Use find and replace to set: ${nm_database_target}
-- Example: retrieving full temporal history for a specific business key id

DECLARE l_id BIGINT DEFAULT 123456789;

SELECT
     id
    ,tx
    ,dt
    ,meta_dt_tech_valid_start
    ,meta_dt_tech_valid_ended
    ,meta_is_actual
    ,meta_ch_rh
    ,meta_ch_bk
    ,meta_ni_rn
    ,meta_ch_pk
    ,meta_dt_ceated_at
FROM
    ${nm_database_target}examples_tbl_inbound
WHERE
    id                       = :l_id
ORDER BY
    meta_dt_tech_valid_start ASC
;
```

</details>

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.txt](./../.ai_prompts/level-1-a-of-sql-table-or-view-definition.txt)

*end of document*
