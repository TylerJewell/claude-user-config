# claude-user-config

Tyler's portable Claude Code user configuration — global instructions, hooks, and skills that apply across all projects and laptops.

## What's Here

| File/Dir | Installs to | Purpose |
|----------|-------------|---------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions loaded in every Claude session |
| `settings.json` | deep-merged into `~/.claude/settings.json` | Permissions, MCP servers, enabled plugins, marketplaces, default mode, and hooks |
| `hooks/pre-akka-local-start.sh` | `~/.claude/hooks/` | Blocks `akka_local_start` if runtime already running |
| `hooks/post-angular-edit.sh` | `~/.claude/hooks/` | Reminds to run `ng build + copy` after frontend edits |
| `skills/fe-build/` | `~/.claude/skills/fe-build/` | `/fe-build` skill for Angular + Akka build pipeline |
| `templates/.claudeignore.template` | copy to project root | Ignore generated Angular chunk files |
| `templates/project-settings.json.template` | copy to `<project>/.claude/settings.json` | Project-level hooks |

## Install

```bash
git clone https://github.com/TylerJewell/claude-user-config
cd claude-user-config
bash install.sh
```

Restart Claude Code after installing.

## Update (new laptop or after pulling changes)

```bash
cd claude-user-config
git pull
bash install.sh  # safe to re-run — deep-merges settings.json (repo wins, local-only keys preserved, backup saved)
```

## Adding a New Project

1. Copy `.claudeignore` template and adjust paths:
   ```bash
   cp templates/.claudeignore.template <project>/.claudeignore
   ```

2. Copy project-level hooks template if the project uses Angular:
   ```bash
   mkdir -p <project>/.claude
   cp templates/project-settings.json.template <project>/.claude/settings.json
   ```

3. Add a project-specific `CLAUDE.md` at the repo root with:
   - Large file protocol (which files are too big to read whole)
   - Build process (how to compile + test)
   - Key invariants (patterns that must never be broken)

## What the Hooks Do

**`pre-akka-local-start`** — The Akka local runtime is a shared daemon. If one Claude session restarts it, all services from other sessions die. This hook checks if port 9889 is already in use and blocks the call with an explanation.

**`post-angular-edit`** — After editing any file under `frontend/src/`, reminds about the `ng build → copy` step. The Angular source and the compiled static resources served by Java are separate — forgetting to rebuild leads to stale UI.

## What the Skills Do

**`/fe-build [dev|prod|serve]`** — Runs the full Angular build pipeline:
- `dev`: `ng build --configuration development` + copy to static-resources
- `prod`: `ng build` (optimized) + copy
- `serve`: starts `ng serve` on port 4200 with proxy config

## Global CLAUDE.md Principles

### LLM Discipline (adapted from [Karpathy's LLM coding pitfalls](https://github.com/forrestchang/andrej-karpathy-skills))

- **Think before coding**: state assumptions, surface tradeoffs, ask when unclear — don't pick silently
- **Simplicity first**: minimum code, no speculative features, no abstractions for single-use code
- **Surgical changes**: touch only what the request demands, don't refactor adjacent code
- **Goal-driven execution**: transform tasks into verifiable success criteria and loop until met

### Operational rules

- **Grep first**: never read large files whole — grep for the specific symbol needed
- **Memory**: always check project memory at session start; save non-obvious findings
- **Environment variables**: API keys follow `{PROVIDER}_{SERVICE}_API_KEY` (e.g. `GOOGLE_AI_GEMINI_API_KEY`, `VERTEX_AI_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`). Never use generic names like `GOOGLE_API_KEY`.
- **Git safety**: never force-push main, never amend published commits, always stage by name
- **Terse responses**: no trailing summaries, no emojis, diff speaks for itself
