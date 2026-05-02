# Codex user configuration

Portable Codex configuration for Tyler's laptops. This keeps reusable settings
in git while leaving secrets, history, logs, sessions, and local state in
`~/.codex` only.

## What this installs

| File | Installs to | Purpose |
| --- | --- | --- |
| `config.toml.template` | managed block in `~/.codex/config.toml` | Windows sandbox mode and Akka MCP server |
| `mcp.json.template` | project `.mcp.json` | Project-level Akka MCP server definition |
| `AGENTS.md.template` | project `AGENTS.md` | Codex/Akka SDK operating rules for a project |
| `command-approvals.md` | reference only | Safe recurring command prefixes to approve on new laptops |

## Install on Windows

From the repo root:

```powershell
.\install-codex.ps1
```

To also install project templates into a repo:

```powershell
.\install-codex.ps1 -ProjectPath C:\Users\tyler\explain
```

Existing project files are not overwritten unless `-ForceProjectFiles` is passed.
Use `-WhatIf` to preview the install without changing files.

## Install on macOS/Linux/Git Bash

```bash
bash install-codex.sh
```

With project templates:

```bash
bash install-codex.sh --project /path/to/project
```

Existing project files are not overwritten unless `--force-project-files` is passed.
Use `--dry-run` to preview the install without changing files.

## What is intentionally not tracked

Never commit these files from `~/.codex`:

- `auth.json`
- `history.jsonl`
- `logs_*.sqlite*`
- `state_*.sqlite*`
- `sessions/`
- `cache/`
- `tmp/`
- `cap_sid`
- `installation_id`
- `models_cache.json`

Those are machine-local, secret-bearing, or high-churn runtime files.

## Current reusable Codex settings

The template captures the settings that have worked well for Akka SDK work:

- `windows.sandbox = "unelevated"`
- Akka MCP server:
  - command: `akka`
  - args: `["mcp", "serve", "--disable-prompt"]`
  - default tools approval mode: `approve`
- existing trusted projects and local preferences are preserved outside the
  managed block

Command-approval history is not copied from Codex runtime state. If a new
laptop asks for recurring command approval, use `command-approvals.md` as the
reference list for scoped prefixes.

Do not copy Codex SQLite state between machines to transfer approvals.
