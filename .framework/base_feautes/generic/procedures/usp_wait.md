# Functional Description of `generic_usp_wait` ([Back](../regression.md))

## Purpose

This stored procedure implements a simple delay mechanism by pausing execution for a specified number of seconds. It uses timestamp calculations and a busy-wait loop to achieve the delay, extracting time components and continuously checking the elapsed time until the desired wait period has passed. The procedure is typically used for retry logic, rate limiting, or introducing controlled delays in data processing workflows.

## Parameters

| Direction | Parameter | Datatype | Description |
|-----------|-----------|----------|-------------|
| IN | ni_wait_in_seconds | INT | Number of seconds to pause execution |

## Logical/functional steps of the procedure

| Mermaid Diagram (35%) | Steps (65%) |
|----------------------|-------------|
| ```mermaid<br>flowchart TD<br>    SP([Start Procedure])<br>    SP --> A[1.initialize-variables]<br>    A --> B[2.capture-start-time]<br>    B --> C[3.convert-start-to-seconds]<br>    C --> D[4.initialize-loop-counter]<br>    D --> E[5.start-wait-loop]<br>    E --> F[6.capture-current-time]<br>    F --> G[7.convert-current-to-seconds]<br>    G --> H[8.calculate-elapsed-time]<br>    H --> I{9.check-wait-condition}<br>    I -->|Continue| E<br>    I -->|Complete| EP([End Procedure])<br>``` | **1. Initialize Variables**<br>Declare local variables for start timestamp, current timestamp, and integer representations of time values for calculation purposes<br><br>**2. Capture Start Time**<br>Record the current timestamp as the starting point for the wait period calculation using CURRENT_TIMESTAMP<br><br>**3. Convert Start to Seconds**<br>Extract time components (day, hour, minute, second) from start timestamp and convert to total seconds since beginning of day<br><br>**4. Initialize Loop Counter**<br>Set the elapsed time difference counter to zero to begin the wait loop evaluation process<br><br>**5. Start Wait Loop**<br>Begin WHILE loop that continues executing until the elapsed time exceeds the specified wait duration<br><br>**6. Capture Current Time**<br>Obtain the current timestamp during each loop iteration to calculate the elapsed time since procedure start<br><br>**7. Convert Current to Seconds**<br>Extract time components from current timestamp and convert to total seconds using same calculation method as start time<br><br>**8. Calculate Elapsed Time**<br>Compute the difference between current time and start time in seconds to determine how much time has passed<br><br>**9. Check Wait Condition**<br>Evaluate if the elapsed time is greater than the requested wait period to determine loop continuation or termination |

## Examples

<details>
<summary>Example 1: Short Wait for Retry Logic</summary>

```sql
-- Wait for 3 seconds in retry scenario
CREATE OR REPLACE PROCEDURE test_short_wait()
BEGIN
    DECLARE l_ni_wait_in_seconds INT DEFAULT 3;
    DECLARE l_start_time         TIMESTAMP;
    DECLARE l_end_time           TIMESTAMP;
    
    -- Capture start time for verification
    SET l_start_time = CURRENT_TIMESTAMP;
    
    -- Call the wait procedure
    CALL ${nm_database_target}generic_usp_wait(l_ni_wait_in_seconds);
    
    -- Capture end time for verification
    SET l_end_time = CURRENT_TIMESTAMP;
    
    -- Display timing results
    SELECT l_start_time AS start_time,
           l_end_time   AS end_time,
           CAST((l_end_time - l_start_time) SECOND AS INT) AS actual_wait_seconds,
           l_ni_wait_in_seconds AS requested_wait_seconds;
    
END;

CALL test_short_wait();
DROP PROCEDURE test_short_wait;
```
</details>

<details>
<summary>Example 2: Longer Wait for Rate Limiting</summary>

```sql
-- Wait for 10 seconds for rate limiting scenario
CREATE OR REPLACE PROCEDURE test_rate_limit_wait()
BEGIN
    DECLARE l_ni_wait_in_seconds INT       DEFAULT 10;
    DECLARE l_start_time         TIMESTAMP;
    DECLARE l_end_time           TIMESTAMP;
    DECLARE l_process_status     VARCHAR(50);
    
    -- Simulate some processing before wait
    SET l_process_status = 'Starting batch process';
    SET l_start_time = CURRENT_TIMESTAMP;
    
    -- Apply rate limiting wait
    CALL ${nm_database_target}generic_usp_wait(l_ni_wait_in_seconds);
    
    -- Continue with processing after wait
    SET l_end_time = CURRENT_TIMESTAMP;
    SET l_process_status = 'Batch process completed after wait';
    
    -- Verify wait duration and status
    SELECT l_process_status AS process_status,
           l_start_time     AS batch_start_time,
           l_end_time       AS batch_end_time,
           CAST((l_end_time - l_start_time) SECOND AS INT) AS total_elapsed_seconds
    WHERE  CAST((l_end_time - l_start_time) SECOND AS INT) >= l_ni_wait_in_seconds;
    
END;

CALL test_rate_limit_wait();
DROP PROCEDURE test_rate_limit_wait;
```
</details>

---

**Utilized ASN GPT Prompt**

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "Procedure" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_usp_" is the functional schema name

The document structure should have the topics in the give order: 
- Tilte should be "Functional Descripton of `<name-of-procedure>` ([Back](../regression.md))"
- Purpuse
  - This is short description, do NOT make it longer then required to get a general description of the purpuse of the procedure.
  - Max 200 words.
- Parameters
  - If there are None, skip this part.
  - Input (and if applicable Output), present these in table with columns direction, parameter, datatype and description.
- Logical/functional steps of the procedure
  - This has two columns, column 1 width 35% has the mermaid diagram, column 2 width 65% lists the steps with descriptions
  - Add Mermaid Diagram
    - Diagram should have `Start Procedure` and `End Procedure` using the formatting `SP([Start Procedure])` and `EP([End Procedure])`
    - Other process steps shoul have the following formatting `[...]`
  - number the logical/functional step
  - per step provide title in bold format
  - per step provide short description, if other objects are reference these can be shown, use `name-object`-format
  - Let the Steps correlate to the Mermaid diagram, the text of diagram block must follow pattern `#.step-name`,  # is substituted by the number correlating with the step.
- Examples
   - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
   - Inlcude declare for all paramters using a 'l_'-prefix for local variables. 
   - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
   - variable in the temporal procedure have the prefix `l_`
   - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
   - Do use the fullname of the procedure, for example 't_l2_func_test.regression_usp_result'.
   - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
   - cleanup any temporal procedures

- At the End of the document after the Examples, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - calapsable text block with the used ASN GPT prompt, title "the prompt" without everthing after
</details>

*end of document*