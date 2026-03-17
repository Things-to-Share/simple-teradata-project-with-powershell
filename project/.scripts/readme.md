# README.md

Here's a `README.md` focused on extending the framework:

```markdown
# Extending the PowerShell Teradata Framework

This guide explains how to add new functionality to the PowerShell Teradata framework.
Follow the conventions below to ensure consistency across the codebase.

---

## Prerequisites

- PowerShell 5.1 or higher
- `$global:fp_root` must be set before loading the framework
- Access to the Teradata environment (configured in `.environments.ps1`)

---

## Getting Started

Bootstrap the framework by dot-sourcing the entry point:

```powershell
$global:fp_root = "C:\your\project\path"
. "$global:fp_root\.load_modules.ps1"
```

This loads all modules into your current session, making every function and class
immediately available.

---

## Project Structure

```text
project/
├── .load_modules.ps1               # Entry point — bootstraps the framework
├── .configuration/
│   └── .environments.ps1           # Environment-specific settings
└── .framework/
    └── .scripts/
        └── modules/
            ├── classes.ps1         # Reusable class definitions
            ├── functions.ps1       # Utility and helper functions
            ├── build_and_publish.ps1
            ├── process_data.ps1
            └── example.ps1         # Developer reference / coding template
```

---

## How to Add a New Module

### Step 1: Create Your Script

Create a new `.ps1` file in the modules directory:

```powershell
.framework/.scripts/modules/your_module.ps1
```

Follow the conventions demonstrated in `example.ps1`:

```powershell
function your_function_name {
    param (
        [bool]$ip_is_debugging = $false
        # Add your parameters here
    )

    if ($ip_is_debugging) {
        Write-Host "your_function_name: Debug mode enabled" -ForegroundColor Green
    } else {
        Write-Host "your_function_name: Running" -ForegroundColor DarkYellow
    }

    # Your logic here
}
```

### Step 2: Register the Module

Add a dot-source entry in `.load_modules.ps1`:

```powershell
. "$global:fp_root\.framework\.scripts\modules\your_module.ps1"
```

> ⚠️ **Order matters.** If your module depends on `classes.ps1` or `functions.ps1`,
> make sure those are dot-sourced first.

### Step 3: Test Your Module

Reload the framework and call your function:

```powershell
. "$global:fp_root\.load_modules.ps1"

your_function_name -ip_is_debugging $true
```

---

## Adding a New Class

Define new classes in `classes.ps1`:

```powershell
class YourClassName {
    [string]$PropertyOne
    [int]$PropertyTwo

    YourClassName([string]$propOne, [int]$propTwo) {
        $this.PropertyOne = $propOne
        $this.PropertyTwo = $propTwo
    }

    [void] YourMethod() {
        # Method logic here
    }
}
```

Classes defined here are automatically available across all modules after
the framework is bootstrapped.

---

## Adding a Utility Function

Add reusable helper functions to `functions.ps1`:

```powershell
function Get-FormattedTimestamp {
    param (
        [bool]$ip_is_debugging = $false
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    if ($ip_is_debugging) {
        Write-Host "Timestamp generated: $timestamp" -ForegroundColor Green
    }

    return $timestamp
}
```

---

## Coding Conventions

| Convention | Description |
|---|---|
| **Function Naming** | Use `snake_case` for function names (e.g., `process_data`) |
| **Parameter Naming** | Prefix parameters with `ip_` (e.g., `$ip_is_debugging`) |
| **Debug Flag** | Always include `[bool]$ip_is_debugging = $false` as a parameter |
| **Console Output** | Use `Green` for debug/true states, `DarkYellow` for default/false states |
| **Single Responsibility** | Each script should handle one concern only |
| **Dot-Sourcing** | Always register new modules in `.load_modules.ps1` |

---

## Modifying Environments

Environment-specific settings (connection strings, flags, paths) are managed
in `.configuration/.environments.ps1`. To add a new setting:

```powershell
# .environments.ps1
$global:your_new_setting = "your_value"
```

Use `$global:` scope to ensure the variable is accessible across all modules.

---

## Tips for Data Engineers New to PowerShell

- **Dot-sourcing** (`. script.ps1`) loads a script into your *current* session —
  think of it like importing a module.
- Use `$ip_is_debugging = $true` while developing to get verbose console feedback.
- The `example.ps1` script is your best reference — when in doubt, follow its pattern.
- Test individual functions by calling them directly in the terminal after bootstrapping.

---

## Example: End-to-End Extension

```powershell

# 1. Bootstrap the framework
$global:fp_root = "C:\pat\to\your\project\.framework\scripts\modules.ps1"
. "$global:fp_root\.load_modules.ps1"

# 2. Call your new function with debugging enabled
your_function_name -ip_is_debugging $true

# 3. Call it in production mode
your_function_name -ip_is_debugging $false
```

---

*This framework was built for data engineering workflows targeting Teradata databases.*
*For questions, reach out to the team responsible for maintaining this framework.*

---

### Notes on what was included

- **Step-by-step guidance** for the three most common extension scenarios: new module, new class, new utility function
- **Coding conventions table** extracted from the patterns described in `scripts.md`
- **Tips section** tailored for Data Engineers with limited PowerShell experience, as mentioned in the source document
- Consistent use of the `ip_is_debugging` pattern throughout all examples
