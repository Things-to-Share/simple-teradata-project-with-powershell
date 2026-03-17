# Documentation: `inbound`-layer ([Back](../../project.md))

---

## Introduction

The `examples` virtual schema implements a lightweight inbound staging pattern built on Teradata SQL. It consists of two core SQL objects: a staging table (`examples_tbl_inbound`) and a view (`examples_viw_inbound`), working together to capture, hash, and track raw incoming data records.

The schema applies bi-temporal data management, meaning each record carries both a technical validity start and end timestamp. This allows querying of both current and historical record states. Record integrity is enforced through three SHA-256 hash columns operating at row, business key, and primary key level.

The pattern supports auditability, deduplication, and versioning through metadata attributes appended to each record.

---

## Hierarchical Structure

### Level 1 — Virtual Schema: `examples`

Top-level logical container grouping the staging table and view into a single inbound staging pattern.

---

### Level 2 — SQL Objects

#### `examples_tbl_inbound` (Table)

Persistent staging table storing raw inbound records enriched with bi-temporal metadata, hash columns, and audit timestamps.

```sql
SELECT id, tx, dt, meta_is_actual
FROM ${nm_database_target}examples_tbl_inbound
WHERE meta_is_actual = 1;
```

---

#### `examples_viw_inbound` (View)

Generates staged records with computed hashing, row numbering, and temporal metadata. Acts as the source for loading the staging table.

```sql
INSERT INTO ${nm_database_target}examples_tbl_inbound (
     id, tx, dt
    ,meta_dt_tech_valid_start, meta_dt_tech_valid_ended
    ,meta_is_actual
    ,meta_ch_rh, meta_ch_bk, meta_ni_rn, meta_ch_pk
)
SELECT
     id, tx, dt
    ,meta_dt_tech_valid_start, meta_dt_tech_valid_ended
    ,meta_is_actual
    ,meta_ch_rh, meta_ch_bk, meta_ni_rn, meta_ch_pk
FROM ${nm_database_target}examples_viw_inbound;
```

---

### Level 3 — Metadata Attributes

| Attribute | Description |
|---|---|
| `meta_dt_tech_valid_start` | Technical validity start timestamp |
| `meta_dt_tech_valid_ended` | Technical validity end timestamp |
| `meta_is_actual` | Current state flag (1=actual, 0=historical) |
| `meta_ch_rh` | SHA-256 row hash |
| `meta_ch_bk` | SHA-256 business key hash |
| `meta_ch_pk` | SHA-256 primary key hash |
| `meta_ni_rn` | Row number within business key partition |
| `meta_dt_ceated_at` | Technical insertion timestamp |

---

## Key Features

- **Bi-temporal Tracking:** Full historical and current state querying via validity timestamps.
- **SHA-256 Hashing:** Row, business key, and primary key integrity enforcement.
- **Current State Flagging:** Efficient filtering using `meta_is_actual`.
- **Auditability:** Insertion moment captured via `meta_dt_ceated_at`.
- **Deduplication Support:** Partitioned row numbering via `meta_ni_rn`.

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-2-of-sql-schema.txt](./../.ai_prompts/level-2-of-sql-schema.txt)

*end of document*
