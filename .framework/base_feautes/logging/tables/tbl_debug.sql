CREATE MULTISET TABLE ${nm_database_target}logging_tbl_debug (
    --
    -- Data Attributes
    id         INT            NOT NULL,
    dt         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tx_message VARCHAR(32000) NOT NULL
)
--
-- Index(es)
PRIMARY INDEX (id);