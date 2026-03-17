# AI Prompt: `level-1-powershell-script.md`

## Step 1: Creating Context

Read the following PowerShell-scripts, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.

## Step 2: Copy and Pasting

Copy and paste text, repeat after all text have been read by the AI.
Follow this format:
<relative-file-path>
<text-of-file>

## Step 3: STOP

STOP

## Step 4: Generate the Documentation / text

You are PowerShell-expert and need to explain what the provided PowerShell script below does. Audiance are Data Engineers with little to no knowlegd of PowerShell.

- Title "# Documentation: `<name-of-file>`"

- Brief overview of the purpose utilization of this script.
  - Max 100 words
  - Keep it to the point
  - NO over exexaggerating!

- Per divined function, provide detailed description
  - Overview
  - Keep it to the point
  - NO over exexaggerating!
  - List Input Parameters in table form, technical name, functional name and short descript of intended use
  - Output Parameter if any, otherwise skip
  - List dependencies, refernce with link
  - add mermiad diagram of the process flow
  - Logical/functional steps of the procedure
  - This has two columns, column 1 width 35% has the mermaid diagram, column 2 width 65% lists the steps with descriptions
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

- Code NOT in function
  - Overview
  - List Input Parameters in table form, technical name, functional name and short descript of intended use
  - Output Parameter if any, otherwise skip
  - List dependencies, refernce with link
  - add mermiad diagram of the process flow
    - everstep should be number
    - everstep should have short description max 30 words

- At the End of the document, add the following in the give order.
  - divider line
  - text:
    - **Utilized ASN GPT Prompt**
    - add blank line
    - **LLM Used:** Claude (Anthropic)
    - **Prompt Used:** [level-1-powershell-script.txt](./../.ai_prompts/level-1-powershell-script.txt)
    - add blank line
    - *end of document*
    - add blank line
