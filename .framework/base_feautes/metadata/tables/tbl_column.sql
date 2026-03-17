CREATE MULTISET TABLE ${nm_database_target}metadata_tbl_column (
    --
    -- Foreignkey(s)
    id_table          CHAR(64)      NOT NULL, 
    --
    -- Data Attributes
    id_column         CHAR(64)      NOT NULL,
    nm_column         VARCHAR(128)  NOT NULL,
    fn_column         VARCHAR(128)  NOT NULL,
    fd_column         VARCHAR(1024) NOT NULL,
    cd_datatype       VARCHAR(32)   NOT NULL,
    ni_ordering       INT           NOT NULL,
    is_nullable       INT           NOT NULL,
    is_businesskey    INT           NOT NULL,
    --
    -- Metadata Attribute(s)
    meta_dt_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --
) 
--
-- Index(es)
PRIMARY INDEX (id_table, id_column);