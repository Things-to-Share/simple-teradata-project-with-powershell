REPLACE VIEW ${nm_database_target}metadata_viw_column AS WITH 
cte_md AS (
    SELECT CAST(LOWER(c.DatabaseName) AS VARCHAR(128)) AS nm_database,
           CAST(LOWER(c.TableName)    AS VARCHAR(128)) AS nm_database_table,
           c.ColumnName    AS nm_column,
           NEW JSON('{ "empty" : true }') AS metadata,
           --NEW JSON(NVL(CommentString,'{ "empty" : true }')) AS metadata,
           CASE WHEN c.nullable = 'Y' THEN 1 ELSE 0 END AS is_nullable,
           ROW_NUMBER() OVER (PARTITION BY c.TableName ORDER BY c.ColumnId ASC) AS ni_ordering,
           CASE 
              WHEN c.ColumnType = 'CV' THEN 'VARCHAR(' || TRIM(ColumnLength) || ')'
              WHEN c.ColumnType = 'CF' THEN 'CHAR(' || TRIM(ColumnLength) || ')'
              WHEN c.ColumnType = 'I'  THEN 'INTEGER'
              WHEN c.ColumnType = 'I1' THEN 'BYTEINT'
              WHEN c.ColumnType = 'I2' THEN 'SMALLINT'
              WHEN c.ColumnType = 'I8' THEN 'BIGINT'
              WHEN c.ColumnType = 'D'  THEN 'DECIMAL(' || TRIM(DecimalTotalDigits) || ',' || TRIM(DecimalFractionalDigits) || ')'
              WHEN c.ColumnType = 'F'  THEN 'FLOAT'
              WHEN c.ColumnType = 'DA' THEN 'DATE'
              WHEN c.ColumnType = 'TS' THEN 'TIMESTAMP'
              WHEN c.ColumnType = 'TM' THEN 'TIME'
              ELSE c.ColumnType
          END AS cd_datatype
    FROM DBC.ColumnsV AS c
    JOIN DBC.TablesV AS t 
    ON  t.DataBaseName = c.DataBaseName 
    AND t.TableName    = c.TableName
    AND t.TableKind    = 'T'
    WHERE c.DataBaseName || '.' || c.TableName LIKE '${nm_database_target}%'
    AND   c.ColumnName NOT LIKE 'meta_%'
),
cte_businesskeys AS (
  SELECT 
    DatabaseName AS nm_database,
    TableName    AS nm_database_table,
    ColumnName   AS nm_column
  FROM DBC.IndicesV AS ix
  JOIN cte_md AS md
  ON  md.nm_database       = ix.DatabaseName
  AND md.nm_database_table = ix.TableName
  AND ix.IndexType = 'P'  -- P = Primary Index
),
src AS (
  SELECT 
    CAST(SYSUDTLIB.HASH_SHA256(CONCAT( -- AS id_table,
      '|', md.nm_database,
      '|', md.nm_database_table,
      '|')
    ) AS CHAR(64)) AS id_table,
    SYSUDTLIB.HASH_SHA256(CONCAT( --      AS id_column,
      '|', md.nm_database,
      '|', md.nm_database_table,
      '|', md.nm_column,
      '|')
    ) AS id_column,
    md.nm_column                                     AS nm_column, 
    NVL(md.metadata.JSONExtractValue('$.fn'),'n/a')  AS fn_column,
    NVL(md.metadata.JSONExtractValue('$.fd'),'n/a')  AS fd_column,
    md.cd_datatype                                   AS cd_datatype,
    md.ni_ordering                                   AS ni_ordering,
    md.is_nullable                                   AS is_nullable,
    CASE WHEN bk.nm_column IS NULL THEN 0 ELSE 1 END AS is_businesskey
  FROM cte_md AS md
  LEFT JOIN cte_businesskeys AS bk 
  ON  bk.nm_column         = md.nm_column
  AND bk.nm_database       = md.nm_database
  AND bk.nm_database_table = md.nm_database_table
)
SELECT * FROM src
;