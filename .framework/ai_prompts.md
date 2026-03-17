# AI-Assisted Documentation Framework

## Introduction

This framework provides a structured, AI-driven approach to generating technical documentation for a data engineering environment. It covers two primary domains: **PowerShell scripting** and **Teradata SQL**, using ASN GPT (Claude/Anthropic) as the underlying LLM.

The framework is prompt-driven: each prompt file defines a documentation template targeting a specific documentation level. This ensures consistency, repeatability, and quality across all generated documentation.

**High-level functionality:**

- Automated documentation generation for PowerShell scripts
- Automated documentation generation for SQL objects (Tables, Views, Procedures)
- Layered documentation approach (detail → schema → layer → overall)
- Consistent document structure enforced via prompt templates
- Traceable AI usage (LLM and prompt references included in every document)

---

## Hierarchical Structure

### Level 0 — Overall Framework Summary

*Covers the entire framework across both SQL and PowerShell domains.*

A single summary document providing a high-level overview of the complete framework, its structure, and key features. Combines output from all lower-level documentation.

> See: [generate-overall-summery.txt](./../.ai_prompts/generate-overall-summery.txt)

---

### Level 1 — Object-Level Documentation

*Detailed documentation per individual object.*

#### 1a. PowerShell Script Documentation

Documents individual PowerShell scripts. Covers purpose, per-function descriptions, input/output parameters, dependencies, and process flow diagrams (Mermaid).

> See: [level-1-powershell-script.txt](./../.ai_prompts/level-1-powershell-script.txt)

**Example (function process step reference):**

```text
SP([Start Procedure]) --> [1.validate-input] --> [2.execute-logic] --> EP([End Procedure])
```

#### 1b. SQL Table / View Documentation

Documents individual SQL Tables and Views. Covers purpose, column structure, and usage examples with parameterized SQL (`${nm_database_target}`).

> See: [level-1-a-of-sql-table-or-view-definition.txt](./../.ai_prompts/level-1-a-of-sql-table-or-view-definition.txt)

#### 1c. SQL Procedure Documentation

Documents individual SQL Procedures. Covers purpose, parameters, process flow (Mermaid), and collapsible usage examples.

> See: [level-1-b-of-sql-procedure-definition.txt](./../.ai_prompts/level-1-b-of-sql-procedure-definition.txt)

---

### Level 2 — Schema / Module Summary

*Aggregated documentation per SQL schema or PowerShell module.*

#### 2a. SQL Schema Summary

Summarizes all SQL objects within a virtual schema (Tables, Views, Procedures). Presents objects in a structured table with clickable links to Level 1 documentation. Includes practical coding examples.

> See: [level-2-of-sql-schema.txt](./../.ai_prompts/level-2-of-sql-schema.txt)

#### 2b. PowerShell Module Summary

Summarizes all PowerShell scripts within a module. Covers introduction, hierarchical structure, and key features.

> See: [level-2-powershell-summery.txt](./../.ai_prompts/level-2-powershell-summery.txt)

---

### Level 3 — Layer Summary

*High-level summary across multiple schemas or modules within a functional layer.*

Provides an introduction, hierarchical breakdown of functionality, and key features. Draws from Level 2 summaries.

> See: [level-3-of-sql-layer.txt](./../.ai_prompts/level-3-of-sql-layer.txt)

---

## Key Features

| Feature | Description |
| --- | --- |
| **Layered Documentation** | Four documentation levels from object to framework |
| **Prompt-Driven** | Each level has a dedicated, reusable prompt template |
| **Consistency** | Uniform structure enforced across all documents |
| **Traceability** | Every document references the LLM and prompt used |
| **Mermaid Diagrams** | Visual process flow diagrams for scripts and procedures |
| **Parameterized SQL** | Examples use `${nm_database_target}` for environment flexibility |
| **Collapsible Code Blocks** | SQL examples are collapsible for readability |
| **Audience-Aware** | Tailored for Data Engineers with varying PowerShell/SQL experience |

---

## **Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [generate-overall-summery.txt](./../.ai_prompts/generate-overall-summery.txt)

*end of document*
