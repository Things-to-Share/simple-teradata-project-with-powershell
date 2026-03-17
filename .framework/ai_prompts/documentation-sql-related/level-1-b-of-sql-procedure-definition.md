1. Read the following SQL definition files, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.
2. copy and paste text, repeat after all text have been read by the AI.
3. STOP
4. Detailed Functional Description Generation
- Provide functional descption of the "context" of the shared SQL definition(s). 
- understand that part before "_usp_" or "_viw_" or "_tbl_" is the functional schema name, the part after is the object name.
- SQL Object Types:
  - "_usp_" is SQL Procedure
  - "_viw_" is SQL View
  - "_tbl_" is SQL Table

The document structure should have the topics in the give order:

- Tilte should be "Documentation: `<name-of-the-file>.<extention>` ([Back](../../<over-arching-folder>.md))"
- Purpuse
  - This is short description, do NOT make it longer then required to get a general description of the purpuse of the procedure.
  - Max 200 words.
  - Keep it to the point
  - NO over exexaggerating!

- Parameters
  - If there are None, skip this part.
  - Input (and if applicable Output), present these in table with columns direction, parameter, datatype and description.

- Process Flow Diagram
  - Logical/functional steps of the procedure
  - This has two columns
    - column 1 width 35% has the mermaid diagram
    - column 2 width 65% lists the steps with descriptions
  - Add Mermaid Diagram
    - Diagram should have `Start Procedure` and `End Procedure` using the formatting `SP([Start Procedure])` and `EP([End Procedure])`
    - Other process steps shoul have the following formatting `[...]`
  - number the logical/functional step
  - per step provide title in bold format
  - per step provide short description, if other objects are reference these can be shown, use `name-object`-format
  - Let the Steps correlate to the Mermaid diagram, the text of diagram block must follow pattern `#.step-name`,  # is substituted by the number correlating with the step.

- Examples
   - Use ${nm_database_target} parameter in the SQL Example! (Use find and replace to insert the correct database for the enviroment the dataset is tested on, in DBeaver these parameters can be pre-set)
   - place the examples in calapsable code block
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
    - **Prompt Used:** [level-1-b-of-sql-procedure-definition.txt](./../.ai_prompts/level-1-b-of-sql-procedure-definition.txt)
    - add blank line
    - *end of document*
    - add blank line