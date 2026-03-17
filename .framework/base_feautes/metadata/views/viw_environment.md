# Teradata View Documentation: metadata_viw_environment

## 1. General Description

The `metadata_viw_environment` view is a metadata management component that provides standardized environment information for the system. This view belongs to the **metadata** functional schema and serves as a single source of truth for environment-related data including environment identification, codes, names, and associated database information.

The view generates a unique SHA256 hash identifier for each environment and consolidates key environment metadata into a consistent structure that can be referenced across the system.

## 2. Logical / Functional Steps

1. **Environment Data Construction**: Creates a Common Table Expression (CTE) that constructs environment metadata using system parameters
2. **ID Generation**: Generates a unique 64-character SHA256 hash identifier using the environment code as input
3. **Parameter Mapping**: Maps system parameters to standardized column names:
   - `${cd_environment}` → `cd_environment` (environment code)
   - `${nm_environment}` → `nm_environment` (environment name)
   - `${nm_database_target}` → `nm_database` (target database name)
4. **Data Standardization**: Applies appropriate data types and lengths to ensure consistency
5. **Result Set**: Returns a single row containing the complete environment metadata

## 3. Examples in Utilization of This View

<details>
<summary><strong>Example 1: Basic Environment Information Query</strong></summary>

```sql
-- Example 1: Retrieve current environment information
DECLARE l_environment_code VARCHAR(32)     DEFAULT NULL;
DECLARE l_environment_name VARCHAR(128)    DEFAULT NULL;
DECLARE l_database_name    VARCHAR(128)    DEFAULT NULL;

-- Query the environment view
SELECT 
    cd_environment,
    nm_environment,
    nm_database,
    id_environment
FROM ${nm_database_target}metadata_viw_environment
WHERE cd_environment IS NOT NULL;

-- Store results in variables for further processing
SELECT 
    cd_environment,
    nm_environment,
    nm_database
INTO 
    l_environment_code,
    l_environment_name,
    l_database_name
FROM ${nm_database_target}metadata_viw_environment;

-- Display results
SELECT 
    l_environment_code AS current_environment,
    l_environment_name AS environment_description,
    l_database_name    AS target_database;
```
</details>

<details>
<summary><strong>Example 2: Environment Validation in Temporary Procedure</strong></summary>

```sql
-- Example 2: Environment validation procedure
REPLACE PROCEDURE ${nm_database_target}temp_environment_validation()
BEGIN
    DECLARE l_env_id           CHAR(64)       DEFAULT NULL;
    DECLARE l_env_code         VARCHAR(32)    DEFAULT NULL;
    DECLARE l_env_name         VARCHAR(128)   DEFAULT NULL;
    DECLARE l_db_name          VARCHAR(128)   DEFAULT NULL;
    DECLARE l_validation_count INTEGER        DEFAULT 0;
    
    -- Validate environment setup
    SELECT 
        id_environment,
        cd_environment,
        nm_environment,
        nm_database
    INTO 
        l_env_id,
        l_env_code,
        l_env_name,
        l_db_name
    FROM ${nm_database_target}metadata_viw_environment;
    
    -- Count validation
    SELECT COUNT(*) 
    INTO l_validation_count
    FROM ${nm_database_target}metadata_viw_environment
    WHERE cd_environment IS NOT NULL
      AND nm_environment IS NOT NULL
      AND nm_database    IS NOT NULL;
    
    -- Results display
    SELECT 
        l_env_id           AS environment_hash_id,
        l_env_code         AS environment_code,
        l_env_name         AS environment_name,
        l_db_name          AS database_name,
        l_validation_count AS validation_status,
        CASE 
            WHEN l_validation_count = 1 THEN 'VALID'
            ELSE 'INVALID'
        END AS environment_status;
        
END;

-- Execute the validation procedure
CALL ${nm_database_target}temp_environment_validation();

-- Cleanup
DROP PROCEDURE ${nm_database_target}temp_environment_validation;
```
</details>

---

**Utilized ASN GPT Prompt**

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Provide functional descption of the "View" in the file of the attachment. 
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s)
- understand that part before "_viw_" is the functional schema name

and provide functional descption of the view in attachment. Handle the following topics
1. General Description
2. logical / functional steps
3. Example in utilization of this view

- Examples
   - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
   - Inlcude declare for all paramters using a 'l_'-prefix for local variables. 
   - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
   - variable in the temporal procedure have the prefix `l_`
   - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
   - Do use the fullname of the procedure, for example '${nm_database_target}regression_usp_result'.
   - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
   - cleanup any temporal procedures

- At the End of the document after the Examples, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - calapsable text block with the used ASN GPT prompt, title "the prompt" without everthing after
</details>

*end of document*