CREATE MULTISET TABLE ${nm_database_target}metadata_tbl_environment (
    --
    -- Data Attributes
    id_environment         CHAR(64)       NOT NULL,
    cd_environment         VARCHAR(32)    NOT NULL,
    nm_environment         VARCHAR(128)   NOT NULL,
    tx_git_remote          VARCHAR(999)       NULL,
    nm_database            VARCHAR(128)   NOT NULL,
    nm_database_target     VARCHAR(128)   NOT NULL,
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
) 
--
-- Index(es)
PRIMARY INDEX (id_environment);