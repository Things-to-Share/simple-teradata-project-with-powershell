CREATE MULTISET TABLE ${nm_database_target}metadata_tbl_process_group (
    --
    -- Data Attributes
    id_table               CHAR(64)       NOT NULL,
    nm_schema              VARCHAR(128)       NULL,
    nm_table               VARCHAR(128)   NOT NULL,
    ni_process_group       INT                NULL,
    is_circular_referenced INT                NULL,
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
) 
--
-- Index(es)
PRIMARY INDEX (id_table);