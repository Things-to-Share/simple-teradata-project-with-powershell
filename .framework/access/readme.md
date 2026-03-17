# Access

The [DATABASE_NAME] database is a [PURPOSE]-solution to [BRIEF_DESCRIPTION]. It uses database-to-database select-rights to access the required information for the respective environments. To maintain this database, additional rights must be assigned.

## Visual Studio Code

Executing the PowerShell script is best done within the Visual Studio Code IDE Editor, a essential extention is needed, it called `PowerShell` and provided by `microsoft`.

## OTA-environments

As an individual database user, if you need to maintain the solution, you should request OTA `developer`-rights (DDL and EXECUTE). The QUERY-right is granted to everyone on OTA by default. This can be done via email to [ITC teradatabeheer](ITCTeradatabeheer@asnbank.nl). Make sure you include the approval of the database owner ([DATABASE_OWNER_NAME] at the time of writing this).

## Production

For the production environment, there is a specialized role `[ROLE_NAME]`. This role should provide the same rights. In [One Identity Manager](https://oneim.verz.local/IdentityManager/) you can request this role.

> ### Preparations: PowerShell-files, 64-bit ODBC drivers, DSN -> TeradataOTA64
>
> PowerShell can work with the JDBC drivers, but the ODBC drivers for the Teradata SQL work better. These must be Installed and a `System DSN` must be defined. If you don\`t have the **64-bit ODBC drivers** please follow the instruction on.

- [https://downloads.teradata.com/download/connectivity/odbc-driver/windows](https://downloads.teradata.com/download/connectivity/odbc-driver/windows)
- [https://www.cdata.com/drivers/teradata/odbc/](https://www.cdata.com/drivers/teradata/odbc/)

After installing the ODBC-drivers, setup the `System DSN`\`s per environment for example `TeradataDEV`, `TeradataTST`, `TeradataACC` and `TeradataPRD`, the PowerShell reference thise in the [.environment.ps1](../../project/.configuration/.environments.ps1)-file.script, These must match the `nm_dsn`-properties in [environment-congif](../../project/.configuration/.environments.ps1) file.

### Example: Approval Request Email

Before submitting any request to obtain rights for the OTA-environment, you must first obtain approval from the database owner ([DATABASE_OWNER_NAME] at the time of writing).

```Text
Dear <Database-Owner>,

I need to maintain the [DATABASE_NAME] database for the [TEAM_NAME] team, which [BRIEF_PURPOSE_DESCRIPTION].

To perform maintenance and implement changes as needed in both the OTA-environment and Production, I require additional rights. For OTA environments, these are granted individually; for production, a role has been created for this purpose.

OTA-Environment:
- WRITE-rights (for modifying tables, views and/or procedures in the database)
- EXECUTE-rights (for executing procedures/scripts that [SPECIFIC_TASK])

Production:
- Assignment of the role '[ROLE_NAME]'

I would appreciate receiving your approval for granting these rights.

Kind regards,

<add-in-your-name>

```

---

**Placeholders to replace:**

- `[DATABASE_NAME]` - Name of your database
- `[PURPOSE]` - Purpose type (e.g., temporal, integration, staging)
- `[BRIEF_DESCRIPTION]` - Short description of what the database does
- `[DATABASE_OWNER_NAME]` - Current database owner
- `[ROLE_NAME]` - Production role name
- `[TEAM_NAME]` - Your team name
- `[BRIEF_PURPOSE_DESCRIPTION]` - Brief explanation of database purpose
- `[SPECIFIC_TASK]` - Specific task the scripts perform
