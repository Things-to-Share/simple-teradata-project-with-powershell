# AI Prompt: `level-2-of-sql-schema.md`

## Step 1: Creating Context

Read the following Markdown files, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.

## Step 2: Copy and Pasting

Copy and paste text, repeat after all text have been read by the AI.
- load all `schema`-md files

Follow this format:
<relative-file-path>
<text-of-file>

## Step 3: STOP

STOP

## Step 4: Generate the Documentation / text

Act like a Teradat SQL / PowerShell expert: Overview of the underlaying functionality

- Tilte should be "Documentation: `<layer>.sql`  [Back](./../<overarching-folder-name>.md)"

- Given the previous texts, create summary overview of the described data features per virtual schema.
- The document structure handle the following topic, in the given order
  - Introduction
    - Max 500 words
    - DO NOT make if longer then is required
    - Keep it to the point
    - NO over exexaggerating!
  - Provide hierarchal structure of the functionality described in the share texts
    - Per hierarchical Level a short description
      - Max 100 words
      - DO NOT make if longer then is required
      - Keep it to the point
      - NO over exexaggerating!
      - If applicable provide 1 example, if must be selfcontained
  - Key Features

- At the End of the document, add the following in the give order.
  - divider line
  - text:
    - **Utilized ASN GPT Prompt**
    - add blank line
    - **LLM Used:** Claude (Anthropic)
    - **Prompt Used:** [level-3-of-sql-layer.md](./../ai_prompts/documentation-sql-related/level-3-of-sql-layer.md)
    - add blank line
    - *end of document*
    - add blank line
