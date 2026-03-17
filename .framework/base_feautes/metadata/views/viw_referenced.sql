REPLACE VIEW ${nm_database_target}metadata_viw_referenced AS WITH
cte_database AS (
  -- Extraction of the (physical) Database Name
  SELECT DISTINCT tb.DatabaseName AS nm_database, '${nm_database_target}' AS nm_database_target
  FROM ${nm_database_target}metadata_tbl_table AS md
  JOIN DBC.TablesV AS tb
  ON  tb.TableName = md.nm_schema || '_' || md.nm_table
  AND '${nm_database_target}' LIKE tb.DatabaseName || '%'
),
cte_table AS (
  -- Mapping id_table to (physical) Table Names.
  SELECT id_table, TRIM(LOWER(nm_database_target || nm_schema || '_' || nm_table)) AS tx_search, tx_view
  FROM ${nm_database_target}metadata_tbl_table
  CROSS JOIN cte_database AS db
),
src AS (
  -- Finding referenced Tables in the Views (that populate the tables)
  SELECT t.id_table AS id_table, r.id_table AS id_table_referenced
  FROM cte_table AS t LEFT JOIN cte_table AS r
  ON t.tx_view LIKE '%' || r.tx_search||'%'
)
SELECT * FROM src
;