CREATE MULTISET TABLE ${nm_database_target}metadata_tbl_table (
    --
    -- Data Attributes
    id_table         CHAR(64)       NOT NULL,
    nm_schema        VARCHAR(128)       NULL,
    nm_table         VARCHAR(128)   NOT NULL,
    fn_table         VARCHAR(128)       NULL,
    fd_table         VARCHAR(1024)      NULL,
    nm_view          VARCHAR(128)   NOT NULL,
    tx_view          VARCHAR(25000) NOT NULL,
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
) 
--
-- Index(es)
PRIMARY INDEX (id_table);