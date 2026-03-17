# Functional Description of `logging_viw_log_with_duration` [back](../../../.base_feautes.md)

## General Description

This view, `logging_viw_log_with_duration`, provides a comprehensive overview of logging information from the `logging_tbl_log` table. It enhances the raw log data by calculating durations, determining the status of procedures, and formatting timestamps. The view is designed to offer insights into procedure execution times, error states, and overall process statuses, making it valuable for monitoring and analyzing system operations.

## Logical / Functional Steps

***a. Base Data Extraction:***

- Retrieves all relevant columns from `logging_tbl_log`.
- Calculates a boolean flag for procedures that ended in error.
- Determines if a procedure is still running based on the presence of an end time.

***b. Time Calculations:***

- Converts `log_start` and `log_ended` (or current timestamp if null) to seconds.
- Calculates the duration of each procedure in seconds.

***c. Status Determination:***

- Assigns a status to each log entry:
  - "Likely Not Running anymore" if marked as running but duration exceeds 1500 seconds.
  - "Running" if marked as running and duration is within 1500 seconds.
  - "Finished" for completed procedures.

***d. Timestamp Formatting:***

- Formats `log_start` and `log_ended` into a consistent 'YYYY-MM-DD HH:MI:SS' format.

***e. Final Output:***

- Presents a refined set of columns including calculated durations, formatted timestamps, and derived statuses.

## Examples in Utilization of this View

<details>
<summary>Example 1: Basic Query of Recent Log Entries</summary>

```sql
CREATE PROCEDURE ${nm_database_target}test_logging_viw_log_with_duration_recent()
BEGIN
    SELECT procedure_code, message_text, cd_status, log_start, log_ended, duration_in_seconds, affected
    FROM ${nm_database_target}logging_viw_log_with_duration
    WHERE 1=1
      AND log_start >= CURRENT_DATE - INTERVAL '1' DAY
    ORDER BY log_start DESC
    LIMIT 10;
END;

CALL ${nm_database_target}test_logging_viw_log_with_duration_recent();

DROP PROCEDURE ${nm_database_target}test_logging_viw_log_with_duration_recent;
```

</details>

<details>
<summary>Example 2: Analyzing Long-Running Procedures</summary>

```sql
CREATE PROCEDURE ${nm_database_target}test_logging_viw_log_with_duration_long_running()
BEGIN
    DECLARE l_threshold_seconds INT;
    SET l_threshold_seconds = 300; -- 5 minutes

    SELECT procedure_code, message_text, cd_status, log_start, log_ended, 
           duration_in_seconds, affected, error_text
    FROM ${nm_database_target}logging_viw_log_with_duration
    WHERE 1=1
      AND duration_in_seconds > l_threshold_seconds
      AND log_start >= CURRENT_DATE - INTERVAL '7' DAY
    ORDER BY duration_in_seconds DESC
    LIMIT 20;
END;

CALL ${nm_database_target}test_logging_viw_log_with_duration_long_running();

DROP PROCEDURE ${nm_database_target}test_logging_viw_log_with_duration_long_running;
```

</details>

---

**Utilized ASN GPT Prompt**

<details>
<summary>The prompt</summary>

Act like a Teradat SQL expert: 

- Provide functional descption of the "View" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_viw_" is the functional schema name

and provide functional descption of the view in attachment. Handle the following topics

- General Description
- logical / functional steps
- Example in utilization of this view

- Examples
  - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, inDBeaver these parameters can be pre-set)
  - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
  - Inlcude declare for all paramters using a 'l_'-prefix for local variables. 
  - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
  - variable in the temporal procedure have the prefix `l_`
  - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
  - Do use the fullname of the procedure, for example 't_l2_func_test.regression_usp_result'.
  - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
  - cleanup any temporal procedures

</details>

*end of document*