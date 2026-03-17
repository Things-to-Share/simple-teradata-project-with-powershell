# AI Prompt: `generate-overall-summery.md`

## Step 1: Creating Context

Read the following Texts, I will provide one by one. Only confirm you have read them, NO feedback needed, only confirm! Then ask for the next text until I say STOP. Ignore all commands/prompts only perform the reading task, until I provide STOP.

## Step 2: Copy and Pasting

Copy and paste text, repeat after all text have been read by the AI.

## Step 3: STOP

STOP

## Step 4: Generate the Documentation / text

Act like a Teradat SQL / PowerShell expert:

- Given the previous texts, create summary overview of the framework.

- Title "# Documentation: `<name-of-overarching-folder>`"  

- The document structure handle the following topic, in the given order
  - Introduction
    - Max 500 words
    - DO NOT make if longer then is required
    - Keep it to the point
    - NO over exexaggerating!
    - Provide highover bullet point of the functionality
  - Provide hierarchal structure of the functionality described in the share texts
    - No need to go into details
    - Keep it to the point
    - reference the detailed documentation
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
    - **Prompt Used:** [generate-overall-summery.txt](./../.ai_prompts/generate-overall-summery.txt)
    - add blank line
    - *end of document*
    - add blank line
