CREATE MULTISET TABLE ${nm_database_target}metadata_tbl_referenced (
    --
    -- Data Attributes
    id_table            CHAR(64)       NOT NULL,
    id_table_referenced VARCHAR(128)       NULL,
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
) 
--
-- Index(es)
PRIMARY INDEX (id_table, id_table_referenced);