REPLACE VIEW ${nm_database_target}metadata_viw_process_group AS WITH
cte_node AS (
  SELECT id_table, nm_schema, nm_table, id_table AS id_table_referenced
  FROM ${nm_database_target}metadata_tbl_table
),
cte_edge AS (
  SELECT id_table, id_table_referenced
  FROM ${nm_database_target}metadata_tbl_referenced
  WHERE LENGTH(id_table_referenced)>0
),
cte_referenced AS(
  SELECT 
    e00.id_table, e00.nm_schema, e00.nm_table,
    --
    -- Connect 15 Level depth the Edges if is found add 1 to ni_process_group
    ( CASE WHEN e01.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e02.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e03.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e04.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e05.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e06.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e07.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e08.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e09.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e10.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e11.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e12.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e13.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e14.id_table_referenced IS NULL THEN 0 ELSE 1 END
    + CASE WHEN e15.id_table_referenced IS NULL THEN 0 ELSE 1 END
    ) AS ni_process_group,
    CASE 
      WHEN e01.id_table_referenced = e00.id_table THEN 1
      WHEN e02.id_table_referenced = e00.id_table THEN 1
      WHEN e03.id_table_referenced = e00.id_table THEN 1
      WHEN e04.id_table_referenced = e00.id_table THEN 1
      WHEN e05.id_table_referenced = e00.id_table THEN 1
      WHEN e06.id_table_referenced = e00.id_table THEN 1
      WHEN e07.id_table_referenced = e00.id_table THEN 1
      WHEN e08.id_table_referenced = e00.id_table THEN 1
      WHEN e09.id_table_referenced = e00.id_table THEN 1
      WHEN e10.id_table_referenced = e00.id_table THEN 1
      WHEN e11.id_table_referenced = e00.id_table THEN 1
      WHEN e12.id_table_referenced = e00.id_table THEN 1
      WHEN e13.id_table_referenced = e00.id_table THEN 1
      WHEN e14.id_table_referenced = e00.id_table THEN 1
      WHEN e15.id_table_referenced = e00.id_table THEN 1 
      ELSE 0 
    END AS is_circular_referenced
    --
  FROM      cte_node AS e00
  LEFT JOIN cte_edge AS e01 ON e01.id_table = e00.id_table_referenced
  LEFT JOIN cte_edge AS e02 ON e02.id_table = e01.id_table_referenced
  LEFT JOIN cte_edge AS e03 ON e03.id_table = e02.id_table_referenced
  LEFT JOIN cte_edge AS e04 ON e04.id_table = e03.id_table_referenced
  LEFT JOIN cte_edge AS e05 ON e05.id_table = e04.id_table_referenced
  LEFT JOIN cte_edge AS e06 ON e06.id_table = e05.id_table_referenced
  LEFT JOIN cte_edge AS e07 ON e07.id_table = e06.id_table_referenced
  LEFT JOIN cte_edge AS e08 ON e08.id_table = e07.id_table_referenced
  LEFT JOIN cte_edge AS e09 ON e09.id_table = e08.id_table_referenced
  LEFT JOIN cte_edge AS e10 ON e10.id_table = e09.id_table_referenced
  LEFT JOIN cte_edge AS e11 ON e11.id_table = e10.id_table_referenced
  LEFT JOIN cte_edge AS e12 ON e12.id_table = e11.id_table_referenced
  LEFT JOIN cte_edge AS e13 ON e13.id_table = e12.id_table_referenced
  LEFT JOIN cte_edge AS e14 ON e14.id_table = e13.id_table_referenced
  LEFT JOIN cte_edge AS e15 ON e15.id_table = e14.id_table_referenced
),
src AS (
  SELECT pgp.id_table, pgp.nm_schema, pgp.nm_table, MAX(pgp.ni_process_group) AS ni_process_group, MAX(pgp.is_circular_referenced) AS is_circular_referenced
  FROM cte_referenced AS pgp
  GROUP BY pgp.id_table, pgp.nm_schema, pgp.nm_table
)
SELECT * FROM src
;