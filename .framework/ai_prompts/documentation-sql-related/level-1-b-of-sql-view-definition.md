# AI Prompt: `level-1-a-of-sql-view-definition.md`

## Step 1: Creating Context

Read the following SQL definition files, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.

## Step 2: Copy and Pasting

Copy and paste text, repeat after all text have been read by the AI.
- Start by loading in the the table and view definitions that are involved with the view
- also let the AI read all involved table and views that are involved with the procedure.

Follow this format:
<relative-file-path>
<text-of-file>

## Step 3: STOP

STOP

## Step 4: Generate the Documentation / text

Detailed Functional Description Generation

- Provide functional descption of the "context" of the shared SQL definition(s).
- understand that part before "_usp_" or "_viw_" or "_tbl_" is the functional schema name, the part after is the object name.
- SQL Object Types:
  - "_usp_" is SQL Procedure
  - "_viw_" is SQL View
  - "_tbl_" is SQL Table

The document structure should have the topics in the give order:

- Tilte should be "Functional Descripton of `<SQL Object Types>` named `<name-of-procedure>` ([Back](../../<virtual-schema-name>.md))"

1. Description
   - This is short description, do NOT make it longer then required to get a general description of the purpuse of the procedure.
   - Max 200 words.
   - Keep it to the point
   - NO over exexaggerating!
  
2. Table Structure
   - Present in table-format with column for Order, Is Primarykey, Name, Datatype, Is Nullable, Functional Description

3. Example in utilization of this view
   - Use calapsable code block
   - Use ${nm_database_target} parameter in the SQL Example! (USe find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - Provide two example in utilization of this procedure, each example in a separate code block, the code blocks must be calapsable. 
   - Inlcude declare for all paramters using a 'l_'-prefix for local variables.
   - If there are input and/or output parameter rap it into a temporal test procdure that will be dropped at the end of the code. 
   - variable in the temporal procedure have the prefix `l_`
   - declared varaible must be align, the datatype should all start at the same position, if default are used align them also.
   - Do use the fullname of the procedure, for example 't_l2_func_test.regression_usp_result'.
   - If there is a table being populated add select-statement, in the where clause the filter value should be aligned.
   - cleanup any temporal procedures

- At the End of the document, add the following in the give order.
  - divider line
  - text:
    - **Utilized ASN GPT Prompt**
    - add blank line
    - **LLM Used:** Claude (Anthropic)
    - **Prompt Used:** [level-1-a-of-sql-table-or-view-definition.txt](./../.ai_prompts/level-1-a-of-sql-table-or-view-definition.txt)
    - add blank line
    - "*end of document*"
    - add blank line
