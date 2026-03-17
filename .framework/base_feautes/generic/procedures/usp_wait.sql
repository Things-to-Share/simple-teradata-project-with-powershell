REPLACE PROCEDURE ${nm_database_target}generic_usp_wait (
  --
  -- /* Input Parameters */
  IN ni_wait_in_seconds INT
  ---
)
BEGIN
  --
  -- Local Variable
  DECLARE dt_start TIMESTAMP;
  DECLARE dt_next  TIMESTAMP;
  DECLARE ni_start INT;
  DECLARE ni_next  INT;
  DECLARE ni_diff  INT;
  --
  -- Set Start
  SET dt_start = CURRENT_TIMESTAMP;
  SET ni_start = EXTRACT(DAY    FROM dt_start) * 3600 * 24
               + EXTRACT(HOUR   FROM dt_start) * 3600
               + EXTRACT(MINUTE FROM dt_start) * 60
               + EXTRACT(SECOND FROM dt_start);
  --
  -- Loop until "ni_diff" is greater then "ni_wait_in_seconds"
  SET ni_diff = 0; WHILE ( ni_diff <= ni_wait_in_seconds) DO
    BEGIN
      --
      -- Set "Next" 
      SET dt_next = CURRENT_TIMESTAMP;
      SET ni_next = EXTRACT(DAY    FROM dt_next) * 3600 * 24
                  + EXTRACT(HOUR   FROM dt_next) * 3600
                  + EXTRACT(MINUTE FROM dt_next) * 60
                  + EXTRACT(SECOND FROM dt_next);
      --
      -- Calculate the Difference between "dt_start" and "dt_next"
      SET ni_diff = (ni_next - ni_start);
      --
    END;
  END WHILE;
  --
END;