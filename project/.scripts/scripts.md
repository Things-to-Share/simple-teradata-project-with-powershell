# Documentation: `scripts.md`

## Introduction

This project is a PowerShell-based data engineering framework designed to interact with Teradata databases. It is structured around a modular approach, where functionality is split across multiple dedicated scripts, each handling a specific concern.

The entry point of the framework is `.load_modules.ps1`, which bootstraps the environment by loading all required components into the current PowerShell session using dot-sourcing. Dot-sourcing ensures that everything defined in the loaded scripts (functions, classes, variables) becomes directly available without needing to re-import them.

The `example.ps1` script serves as a developer reference, demonstrating the coding conventions used throughout the project — specifically how functions are structured, how parameters are defined, and how console output is handled.

The framework is built for Data Engineers who may have limited PowerShell experience. The scripts follow consistent patterns, making it easier to understand and extend the codebase.

---

## Hierarchical Structure

### Level 1: Entry Point

**`.load_modules.ps1`**
Bootstraps the entire framework. Dot-sources all required scripts into the current session, making their contents available. Relies on `$global:fp_root` as the base path.

```powershell
# Example: Dot-sourcing a script
. "$global:fp_root\project\.configuration\.environments.ps1"
```

---

### Level 2: Configuration

**`.environments.ps1`**
Loaded first by `.load_modules.ps1`. Provides environment-specific settings (e.g., connection strings, environment flags) used throughout the framework.

---

### Level 2: Framework Components

Scripts loaded from `$global:fp_root\.framework\.scripts\modules\`:

- **`classes.ps1`** — Defines reusable PowerShell classes (object blueprints) used across the framework.
- **`functions.ps1`** — Contains utility and helper functions available to all other scripts.
- **`build_and_publish.ps1`** — Handles build and deployment automation tasks.
- **`process_data.ps1`** — Manages data processing operations against the database.

---

### Level 3: Developer Reference

**`example.ps1` → `ps_example`**
A template function demonstrating project conventions. Accepts a boolean parameter (`$ip_is_debugging`) and writes a color-coded message to the console.

```powershell
# Example: Calling the function
ps_example -ip_is_debugging $true
# Output (Green): "is_debugging: True"

ps_example -ip_is_debugging $false
# Output (DarkYellow): "is_debugging: False"
```

---

## Key Features

| Feature | Description |
|---|---|
| Modular Design | Functionality is split across dedicated scripts, each with a single responsibility. |
| Dot-Sourcing | Scripts are loaded into the current scope, making all functions and classes directly accessible. |
| Global Base Path | `$global:fp_root` acts as the single root reference, making paths consistent and portable. |
| Debug Support | Functions support a boolean debug flag, enabling color-coded console feedback. |
| Developer Conventions | `example.ps1` serves as a coding template, ensuring consistency across the codebase. |
| Teradata Integration | The framework is purpose-built for data engineering workflows involving a Teradata database. |

---

**Utilized ASN GPT Prompt**

**LLM Used:** Claude (Anthropic)
**Prompt Used:** [level-2-powershell-summery.txt](./../.ai_prompts/level-2-powershell-summery.txt)

*end of document*
