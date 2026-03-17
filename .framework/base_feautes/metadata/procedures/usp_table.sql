REPLACE PROCEDURE ${nm_database_target}metadata_usp_table (
  IN ip_nm_schema VARCHAR(128),
  IN ip_nm_table  VARCHAR(128),
  IN fn_table     VARCHAR(128),
  IN fd_table     VARCHAR(1024)
)
BEGIN
  DECLARE l_id_table    CHAR(64);
  DECLARE l_nm_database VARCHAR(128);
  
  -- Determine Database
  SET l_nm_database = (SELECT DISTINCT DataBaseName FROM DBC.TablesV WHERE DataBaseName || '.'|| TableName LIKE '${nm_database_target}%');
  
  -- Generate unique ID for the table (using HASHROW for consistency)
  SET l_id_table = CAST(SYSUDTLIB.HASH_SHA256(CONCAT( -- AS id_table,
  '|', l_nm_database,
  '|', ip_nm_schema,
  '|', ip_nm_table,
  '|')) AS CHAR(64)) ;
  
  -- Update existing metadata record
  UPDATE ${nm_database_target}metadata_tbl_table 
  SET 
    nm_schema = ip_nm_schema,
    nm_table = ip_nm_table,
    fn_table = fn_table,
    fd_table = fd_table
  WHERE 
    id_table = l_id_table;
  
END;