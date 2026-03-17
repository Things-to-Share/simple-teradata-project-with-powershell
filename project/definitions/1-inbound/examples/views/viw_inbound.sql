REPLACE VIEW ${nm_database_target}examples_viw_inbound AS WITH 
src_fake AS (
  SELECT
    CAST(1            AS BIGINT)        AS id, --> Businesskey Attributes
    CAST('text'       AS VARCHAR(255) ) AS tx,
    CAST('1970-01-01' AS DATE)          AS dt
),
src AS (
  SELECT
    --
    -- Data Attributes
    src.id, --> Businesskey Attributes
    src.tx,
    src.dt,
    --
    -- Metadata Attributes
    CAST(CURRENT_TIMESTAMP            AS TIMESTAMP) AS meta_dt_tech_valid_start,
    CAST('9999-12-31 23:59:59.999999' AS TIMESTAMP) AS meta_dt_tech_valid_ended,
    CAST(1                            AS INT)       AS meta_is_actual,
    CAST(SYSUDTLIB.HASH_SHA256(CONCAT(
      '|', NVL(CAST(src.id      AS VARCHAR(255)), 'n/a'),
      '|', NVL(CAST(src.tx      AS VARCHAR(255)), 'n/a'),
      '|', NVL(CAST(src.dt      AS VARCHAR(255)), 'n/a'),
      '|')) AS char(64)) AS meta_ch_rh,
    CAST(SYSUDTLIB.HASH_SHA256(CONCAT(
      '|', NVL(CAST(src.id AS VARCHAR(255)), 'n/a'), --> Businesskey Attributes
      '|')) AS char(64)) AS meta_ch_bk,
    ROW_NUMBER() OVER (PARTITION BY meta_ch_bk ORDER BY meta_ch_bk) as meta_ni_rn,
    CAST(SYSUDTLIB.HASH_SHA256(CONCAT( '|', meta_ch_bk, '|', CAST(meta_ni_rn AS VARCHAR(32)), '|', CAST(meta_dt_tech_valid_start AS VARCHAR(32)), '|')) AS CHAR(64)) AS meta_ch_pk
    --
  FROM src_fake AS src
)
SELECT * FROM src
;