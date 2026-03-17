REPLACE VIEW ${nm_database_target}metadata_viw_table AS WITH
cte_md AS (
    SELECT NEW JSON(t.CommentString)                              AS metadata,
           OREPLACE(t.TableName, '_tbl_', '_viw_')                AS nm_view,
           NVL(t.RequestText,'')                                  AS tx_view,
           CASE WHEN t.TableKind = 'V' THEN 1 ELSE 0 END          AS is_view,
           CAST(LOWER(t.DatabaseName) AS VARCHAR(128))            AS nm_database,
           CAST(LOWER(t.TableName)    AS VARCHAR(128))            AS nm_database_table,
           CAST(t.DataBaseName||'.'||t.TableName AS VARCHAR(255)) AS nm_database_object,
           LENGTH('${nm_database_target}')                        AS ni_database_target,
           --
           -- Schema + Table
           LENGTH(nm_database_object) - ni_database_target                   AS ni_schema_table,
           SUBSTR(nm_database_object, ni_database_target+1, ni_schema_table) AS nm_schema_table,
           --
           -- Schema
           CASE WHEN t.TableKind = 'T' THEN POSITION('_tbl' IN nm_schema_table)
                WHEN t.TableKind = 'V' THEN POSITION('_viw' IN nm_schema_table)
                ELSE 0 
           END AS ni_schema,
           SUBSTR(nm_schema_table, 1, ni_schema-1) AS nm_schema,
           --
           -- Table
           CASE WHEN t.TableKind = 'T' THEN 'tbl_'
                WHEN t.TableKind = 'V' THEN 'viw_'
                ELSE 0 
           END || SUBSTR(nm_schema_table, ni_schema+5, LENGTH(nm_schema_table) - (ni_schema+3)) AS nm_table
           --*/
    FROM DBC.TablesV  AS t
    WHERE nm_database_object     LIKE '${nm_database_target}%'
    AND   nm_database_object NOT LIKE '${nm_database_target}tmp_%'
    AND   t.TableKind IN ('T', 'V')
),
src AS (
  SELECT CAST(SYSUDTLIB.HASH_SHA256(CONCAT( 
           '|', md.nm_database,
           '|', md.nm_database_table,
           '|')
         ) AS CHAR(64)) AS id_table,
         md.nm_schema   AS nm_schema,
         md.nm_table    AS nm_table,
         NVL(md.metadata.JSONExtractValue('$.fn'),'n/a') AS fn_table,
         NVL(md.metadata.JSONExtractValue('$.fd'),'n/a') AS fd_table,
         NVL(vw.nm_view, 'n/a')                          AS nm_view,
         NVL(vw.tx_view, 'n/a')                          AS tx_view
  FROM cte_md AS md LEFT JOIN cte_md As vw 
  ON    vw.is_view = 1 AND OREPLACE(vw.nm_view, '_viw_', '_tbl_') = md.nm_database_table
  WHERE md.is_view = 0
)
SELECT * FROM src
;