CREATE MULTISET TABLE ${nm_database_target}logging_tbl_log (
    --
    -- Data Attributes
    id_log           CHAR(64) NOT NULL,
    id_log_parent    CHAR(64)     NULL,
    procedure_code   VARCHAR(128),
    message_text     VARCHAR(999),
    log_start        TIMESTAMP,
    log_ended        TIMESTAMP,
    affected         INT,
    error_text       VARCHAR(2000),
    dynamic_sql_text VARCHAR(32000),
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
)
--
-- Index(es)
PRIMARY INDEX (id_log);
