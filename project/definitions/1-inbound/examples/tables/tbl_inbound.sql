CREATE MULTISET TABLE ${nm_database_target}examples_tbl_inbound (
  --
  -- Data Attributes
  id    BIGINT       NULL,
  tx    VARCHAR(255) NULL,
  dt    DATE         NULL,
  --
  -- Metadata Attributes
  meta_dt_tech_valid_start TIMESTAMP    NOT NULL,
  meta_dt_tech_valid_ended TIMESTAMP    NOT NULL,
  meta_is_actual           INT          NOT NULL,
  meta_ch_rh               CHAR(64)     NOT NULL,
  meta_ch_bk               CHAR(64)     NOT NULL,
  meta_ni_rn               INT          NOT NULL,
  meta_ch_pk               CHAR(64)     NOT NULL,
  meta_dt_ceated_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
  --
)
-- The `Attributes` in the `Primary Index` are marked as `Businesskeys` in the metadata_tbl_column-table
PRIMARY INDEX (
  --
  -- Businesskey(s)
  id,
  --
  -- Metadata for technical valid start of record.
  meta_dt_tech_valid_start
);