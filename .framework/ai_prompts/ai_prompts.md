# Documentation: `ai_prompts` [back](./../.framework.md)

## Introduction

This framework provides a structured set of AI prompts designed to generate consistent, standardized documentation for a Teradata SQL / PowerShell project. The prompts guide an AI through a two-phase process: first reading source files for context, then generating documentation based on predefined templates.

The framework covers three main areas:
- **PowerShell documentation** – for scripts and summaries
- **SQL documentation** – for tables, views, and stored procedures
- **Overall summaries** – for folder-level overviews

Each prompt follows the same interaction pattern: read → confirm → STOP → generate.

---

## Hierarchical Structure

### Level 1: Overall Summary

**Prompt:** `generate-overall-summery.md`

Generates a top-level summary of an entire folder/framework. Targets a broad audience. Produces an introduction, hierarchical structure overview, and key features section.

---

### Level 2: PowerShell Documentation

#### `level-1-powershell-script.md`

Documents an individual PowerShell script. Produces an introduction, hierarchical breakdown, and key features. Aimed at Data Engineers with limited PowerShell knowledge.

#### `level-2-powershell-summery.md`

Generates a summary across multiple PowerShell scripts. Same structure as level-1 but aggregated.

---

### Level 3: SQL Documentation

#### `level-1-a-of-sql-table-definition.md`

Documents a **SQL Table**. Produces a description, table structure (columns, datatypes, keys), and collapsible usage examples with `${nm_database_target}` parameter.

#### `level-1-b-of-sql-view-definition.md`

Documents a **SQL View**. Same structure as table definition, including dependent table/view context.

#### `level-1-c-of-sql-procedure-definition.md`

Documents a **SQL Stored Procedure**. Produces description, parameters table, Mermaid process flow diagram, and collapsible examples wrapped in a temporal test procedure.

Example Mermaid pattern:

```text
SP([Start Procedure]) --> [1.step-name] --> [2.step-name] --> EP([End Procedure])
```

#### `level-2-of-sql-schema.md`

Aggregates level-1 SQL documentation into a **virtual schema summary**. Presents objects in a table (type, name, description) with key features and 2–3 practical coding examples.

#### `level-3-of-sql-layer.md`

Aggregates schema-level summaries into a **layer-level overview**. Produces introduction, hierarchical structure, and key features.

---

## Key Features

- **Consistent structure** – All prompts follow the same read → confirm → STOP → generate pattern.
- **Audience-aware** – Documentation is tailored (e.g., Data Engineers with limited PowerShell knowledge).
- **Standardized footers** – Every generated document includes LLM used, prompt reference, and end-of-document marker.
- **SQL-aware naming conventions** – Prompts understand `_tbl_`, `_viw_`, `_usp_` naming patterns for automatic schema/object identification.
- **Scalable** – Prompts are layered (object → schema → layer → overall), enabling documentation at any level of granularity.
- **Reusable templates** – Prompts are file-based and referenceable, making them easy to maintain and version.

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-2-of-sql-schema.txt](./../.ai_prompts/level-2-of-sql-schema.txt)

*end of document*
