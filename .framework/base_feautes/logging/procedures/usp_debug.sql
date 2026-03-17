REPLACE PROCEDURE ${nm_database_target}logging_usp_debug (
  --
  -- Input Parameters
  IN ip_tx_message   VARCHAR(32000),
  IN ip_is_debugging INT
  --
)
BEGIN
  --
  -- Local Variables
  DECLARE l_id INT;
  --
  IF (ip_is_debugging = 1) THEN
    --
    -- Get latest id
    SET l_id = (SELECT NVL(MAX(de.id)+1,1) FROM ${nm_database_target}logging_tbl_debug AS de);
    --
    -- Insert text message
    INSERT INTO ${nm_database_target}logging_tbl_debug (id, tx_message) VALUES (l_id, ip_tx_message);
    --
  END IF;
  --
END;