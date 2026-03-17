# Documentation: `viw_inbound.sql` ([Back](../../examples.md))

---

## 1. Description

The `viw_inbound` view is part of the **examples** schema and serves as an inbound staging view. It generates a single hardcoded fake source record and enriches it with standardized metadata attributes. These metadata attributes include technical validity timestamps, an actuality indicator, and cryptographic hash keys (row hash, business key hash, and primary key hash) based on SHA-256 hashing. This pattern is typically used as a template or baseline example for inbound data ingestion views, demonstrating how raw source data should be structured and enriched before further processing in the data pipeline.

---

## 2. Table Structure

| Order | Is Primary Key | Name | Datatype | Is Nullable | Functional Description |
|-------|---------------|------|----------|-------------|----------------------|
| 1 | Yes | `id` | `BIGINT` | No | Business key attribute; unique identifier of the record |
| 2 | No | `tx` | `VARCHAR(255)` | Yes | Text attribute; descriptive text field |
| 3 | No | `dt` | `DATE` | Yes | Date attribute; business date of the record |
| 4 | No | `meta_dt_tech_valid_start` | `TIMESTAMP` | No | Technical validity start timestamp; set to current timestamp at load time |
| 5 | No | `meta_dt_tech_valid_ended` | `TIMESTAMP` | No | Technical validity end timestamp; default set to far future (`9999-12-31 23:59:59.999999`) indicating an active record |
| 6 | No | `meta_is_actual` | `INT` | No | Actuality flag; `1` = current/active record |
| 7 | No | `meta_ch_rh` | `CHAR(64)` | No | Row hash; SHA-256 hash of all data attributes combined, used for change detection |
| 8 | No | `meta_ch_bk` | `CHAR(64)` | No | Business key hash; SHA-256 hash of business key attribute(s), used for record identification |
| 9 | No | `meta_ni_rn` | `INTEGER` | No | Row number; sequence number partitioned by business key hash |
| 10 | No | `meta_ch_pk` | `CHAR(64)` | No | Primary key hash; SHA-256 hash combining business key hash, row number, and technical valid start timestamp |

---

## 3. Example in Utilization of this View

### Example 1 — Select all records from the view

<details>
<summary>Click to expand — Example 1</summary>

```sql
-- ============================================================
-- Example 1: Select all records from viw_inbound
-- ============================================================
-- Use find & replace to set ${nm_database_target} in DBeaver
-- ============================================================

SELECT *
FROM   ${nm_database_target}examples_viw_inbound
;
```

</details>

---

### Example 2 — Select a specific record by Business Key

<details>
<summary>Click to expand — Example 2</summary>

```sql
-- ============================================================
-- Example 2: Filter on business key and active records only
-- ============================================================
-- Use find & replace to set ${nm_database_target} in DBeaver
-- ============================================================

SELECT
    id,
    tx,
    dt,
    meta_dt_tech_valid_start,
    meta_dt_tech_valid_ended,
    meta_is_actual,
    meta_ch_rh,
    meta_ch_bk,
    meta_ni_rn,
    meta_ch_pk
FROM   ${nm_database_target}examples_viw_inbound
WHERE  id             = 1
AND    meta_is_actual = 1
;
```

</details>

---

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-1-a-of-sql-table-or-view-definition.txt](./../.ai_prompts/level-1-a-of-sql-table-or-view-definition.txt)

*end of document*
