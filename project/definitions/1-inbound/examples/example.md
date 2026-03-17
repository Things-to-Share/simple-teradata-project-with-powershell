# Documentation: `examples`-schema ([Back](../../examples.md))

---

## Introduction

The `examples` virtual schema provides a lightweight inbound staging pattern for capturing and managing raw incoming data records. It combines a staging table and a view to support bi-temporal data management, including technical validity tracking, record hashing, and auditability. The schema enables tracking of current and historical record states using metadata attributes.

---

## SQL Objects

| SQL Object Type | Name | Description |
|----------------|------|-------------|
| Table | [`examples_tbl_inbound`](./examples/tables/tblinbound.md) | Inbound staging table capturing raw records with full bi-temporal metadata support |
| View | [`examples_viw_inbound`](./examples/views/viwinbound.md) | Inbound view generating staged records with hashing, row numbering, and temporal metadata |

---

## Key Features

- **Bi-temporal Data Management:** Records are tracked using `meta_dt_tech_valid_start` and `meta_dt_tech_valid_ended`, enabling full historical and current state querying.
- **Record Hashing:** Three hash columns (`meta_ch_rh`, `meta_ch_bk`, `meta_ch_pk`) provide row-level, business key-level, and primary key-level integrity using SHA-256.
- **Current State Flagging:** The `meta_is_actual` flag (1=actual, 0=historical) allows efficient filtering of current records.
- **Auditing Support:** The `meta_dt_ceated_at` timestamp captures the technical insertion moment of each record.
- **Partitioned Row Numbering:** `meta_ni_rn` provides row numbering within business key partitions, supporting deduplication and versioning logic.

---

## Practical Coding Examples

### Example 1: Retrieve All Current/Actual Records

```sql
-- Retrieve only the current/active records from the inbound staging table
SELECT
     id
    ,tx
    ,dt
    ,meta_dt_tech_valid_start
    ,meta_dt_tech_valid_ended
    ,meta_is_actual
    ,meta_ch_rh
    ,meta_ch_bk
    ,meta_ch_pk
    ,meta_dt_ceated_at
FROM
    ${nm_database_target}examples_tbl_inbound
WHERE
    meta_is_actual = 1
;
```

---

### Example 2: Retrieve Full History for a Specific Business Key

```sql
-- Retrieve the full temporal history for a specific business key (id)
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
    id = :l_id
ORDER BY
    meta_dt_tech_valid_start ASC
;
```

---

### Example 3: Load Staged Records from View into Inbound Table

```sql
-- Insert staged records from the inbound view into the inbound staging table
INSERT INTO ${nm_database_target}examples_tbl_inbound (
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
)
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
FROM
    ${nm_database_target}examples_viw_inbound
;
```

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-2-of-sql-schema.txt](./../.ai_prompts/level-2-of-sql-schema.txt)

*end of document*
