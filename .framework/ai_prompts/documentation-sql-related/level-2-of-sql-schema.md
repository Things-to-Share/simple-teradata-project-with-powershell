# AI Prompt: `level-2-of-sql-schema.md`

## Step 1: Creating Context

Read the following SQL definition files, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.

## Step 2: Copy and Pasting

Copy and paste text, repeat after all text have been read by the AI.
- load all involved table definitions
- load all involved view definitions
- load sll involved procedure definitions

Follow this format:
<relative-file-path>
<text-of-file>

## Step 3: STOP

STOP

## Step 4: Generate the Documentation / text

Act like a Teradat SQL / PowerShell expert: Overview of the underlaying functionality

- Tilte should be "Documentation: `<virtual-schema-name>` ([Back](../../<virtual-schema-name>.md))"

- Given the previous texts, create summary overview of the described functionality.

- Handle the following topics
  - virutal schema the part before "_tbl", "_viw_" of "_usp_" is the virual schema name
  - SQL Object Types:
    - "_usp_" --> Procedure
    - "_viw_" --> View
    - "_tbl_" --> Table
  - If reference a SQL object make it into a clickable link to the documentation use this format "[`<sql-object>`](./<virtual-schema-name>/<SQL-Object-Type>/<name-of-object>.md)" for tables and for procedure use "[`sql-object`](./<virtual-schema-name>/procedures/<name-of_procedure>.md)"

- The document structure handle the following topic, in the given order
  - Introduction (Max 100 words, DO NOT make if longer then is required)
  - per share markdown file (present as a table with columns SQL Objecttype (procedure, Table or View), Name, Description)
  - Key Features
  - Provide 2 ro 3 practical coding examples

- At the End of the document, add the following in the give order.
  - divider line
  - text:
    - **Utilized ASN GPT Prompt**
    - add blank line
    - **LLM Used:** Claude (Anthropic)
    - **Prompt Used:** [level-2-of-sql-schema.txt](./../.ai_prompts/level-2-of-sql-schema.txt)
    - add blank line
    - *end of document*
    - add blank line