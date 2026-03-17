REPLACE VIEW ${nm_database_target}metadata_viw_environment AS WITH
cte_database AS (
  -- Extraction of the (physical) Database Name
  SELECT DISTINCT tb.DatabaseName AS nm_database, '${nm_database_target}' AS nm_database_target
  FROM ${nm_database_target}metadata_tbl_table AS md
  JOIN DBC.TablesV AS tb
  ON  tb.TableName = md.nm_schema || '_' || md.nm_table
  AND '${nm_database_target}' LIKE tb.DatabaseName || '%'
),
src AS (
  SELECT
    CAST(SYSUDTLIB.HASH_SHA256(CONCAT('|','${cd_environment}','|')) AS CHAR(64)) AS id_environment,
    CAST('${cd_environment}' AS VARCHAR(32))                                     AS cd_environment,
    CAST('${nm_environment}' AS VARCHAR(128))                                    AS nm_environment,
    CAST('https://gitlab.com/devolksbank/teams/denr-loantapes/dd-osx-team-code-base/-/tree/main/mbdt?ref_type=heads' AS VARCHAR(128)) AS tx_git_remote,
    dbs.nm_database,
    dbs.nm_database_target
  FROM cte_database AS dbs
)
SELECT * FROM src
;