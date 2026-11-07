# claude-user-config

Tyler's portable Claude Code and Codex user configuration - global instructions, hooks, skills, MCP setup, and project templates that apply across laptops.

## What's Here

| File/Dir | Installs to | Purpose |
|----------|-------------|---------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions loaded in every Claude session |
| `settings.json` | deep-merged into `~/.claude/settings.json` | Permissions, MCP servers, enabled plugins, marketplaces, default mode, and hooks |
| `hooks/check-config-sync.sh` | `~/.claude/hooks/` | On SessionStart, auto-pulls this repo and re-runs install.sh if behind origin |
| `hooks/pre-akka-local-start.sh` | `~/.claude/hooks/` | Blocks `akka_local_start` if runtime already running |
| `hooks/post-angular-edit.sh` | `~/.claude/hooks/` | Reminds to run `ng build + copy` after frontend edits |
| `hooks/pre-akka-push.sh` | `~/.claude/hooks/` | Blocks `git push` of a feature branch in an `akka` org repo until `/akka-pr-review` has passed on it |
| `skills/fe-build/` | `~/.claude/skills/fe-build/` | `/fe-build` skill for Angular + Akka build pipeline |
| `skills/akka-pr-review/` | `~/.claude/skills/akka-pr-review/` | `/akka-pr-review` skill: independent pre-push review of a branch headed for an `akka` org PR |
| `skills/html-phone-check/` | `~/.claude/skills/html-phone-check/` | `/html-phone-check`: renders an HTML page at phone widths with scripts on and off (WebKit and Chromium) and reports sideways scroll, missing text and script errors; run before sending a page |
| `skills/akka-presentation/` | `~/.claude/skills/akka-presentation/` | Tyler's standard for every deck, keynote, briefing and narrated demo film: storyboard first, one idea per scene, the Akka visual language, complete plain sentences |
| `hooks/_python.sh` | `~/.claude/hooks/` | Sourced by the hooks and installers to find a working Python 3. On Windows `python3` is a Store stub that does nothing, so it tries `py -3` first |
| `akka-mcp-gateway` (registered by `install.sh`) | `~/.claude.json` at user scope | Company MCP gateway at `https://mcp.akka.services/mcp` — Slack, Gmail, Google Calendar, Google Drive, HubSpot, Okta, and Groundcover. Requires the `claude` CLI on PATH. Authentication is per-machine: run `/mcp` and sign in through Okta. |
| `robert-mcp/` (cloned, gitignored) | `go install` + registers in `~/.claude.json`, symlinks `rw-*` assets into `~/.claude/` | 82 narrow MCP dev tools (git/go/cargo/mvn/sbt/gh/docker/buf/jq/akka) plus `rw-walk-through` skill. Requires Go on PATH; on Windows, requires Developer Mode enabled for symlink creation. |
| `codex/` | `~/.codex` and project roots | Portable Codex MCP/config templates and AGENTS.md guidance |
| `install-codex.ps1` | run from repo root | Windows Codex installer; preserves local config and secrets |
| `install-codex.sh` | run from repo root | macOS/Linux/Git Bash Codex installer; preserves local config and secrets |
| `templates/.claudeignore.template` | copy to project root | Ignore generated Angular chunk files |
| `templates/project-settings.json.template` | copy to `<project>/.claude/settings.json` | Project-level hooks |

## Install Claude Config

```bash
git clone https://github.com/TylerJewell/claude-user-config
cd claude-user-config
bash install.sh
```

Restart Claude Code after installing.

## Install Codex Config

Windows:

```powershell
.\install-codex.ps1
.\install-codex.ps1 -ProjectPath C:\Users\tyler\explain
```

macOS/Linux/Git Bash:

```bash
bash install-codex.sh
bash install-codex.sh --project /path/to/project
```

The Codex installer updates only the managed reusable block in `~/.codex/config.toml`, preserving trusted projects and local preferences outside that block. It does not copy `auth.json`, history, logs, sessions, SQLite state, caches, or other machine-local runtime files.

Codex command approvals are intentionally documented in `codex/command-approvals.md` instead of copied from runtime state.

## Windows

`python` and `python3` are Microsoft Store stubs on most Windows machines. The installers and the hooks that need Python source `hooks/_python.sh`, which runs each candidate (`py -3`, `python3`, `python`) and uses the first that works. Before that, `install.sh` could not merge `settings.json` on Windows and the `pre-akka-push` hook failed open, so the akka-org review was not enforced there.

## Subagents

`settings.json` sets `CLAUDE_CODE_SUBAGENT_MODEL=haiku`, so every subagent runs on the cheaper model. It overrides a model set in an agent's own file or on a call, so a project that chooses its agents' models sets `CLAUDE_CODE_SUBAGENT_MODEL` to an empty string in its own `.claude/settings.local.json` (a project value overrides the user value). `ai-console` does this: its agents are `model: inherit` and its rules pick the model per call. To check that an override took effect, read the `model` field on the subagent's messages in the session transcript.

## Update

```bash
cd claude-user-config
git pull
bash install.sh
bash install-codex.sh --dry-run
```

`install.sh` is safe to re-run because it deep-merges `settings.json`: repo keys win, local-only keys are preserved, and a backup is saved when the file changes.

## Adding a New Project

1. Copy `.claudeignore` template and adjust paths:
   ```bash
   cp templates/.claudeignore.template <project>/.claudeignore
   ```

2. Copy project-level Claude hooks template if the project uses Angular:
   ```bash
   mkdir -p <project>/.claude
   cp templates/project-settings.json.template <project>/.claude/settings.json
   ```

3. Copy Codex project templates when the project should use the shared Akka MCP and AGENTS rules:
   ```powershell
   .\install-codex.ps1 -ProjectPath C:\path\to\project
   ```

4. Add project-specific instructions at the repo root with:
   - Large file protocol: which files are too big to read whole
   - Build process: how to compile and test
   - Key invariants: patterns that must never be broken

## What the Hooks Do

**`check-config-sync`** (SessionStart) - Every new Claude Code session, this hook fetches `~/claude-user-config` and checks whether the checkout is behind origin. If behind and the working tree is clean, it auto-pulls, re-runs `install.sh`, and prints a one-line reminder to restart Claude Code so the new config is loaded. If the working tree is dirty, it warns and skips auto-pull. Network failures and missing checkouts are silent to avoid startup noise.

**`pre-akka-local-start`** (PreToolUse) - The Akka local runtime is a shared daemon. If one Claude session restarts it, all services from other sessions die. This hook checks if port 9889 is already in use and blocks the call with an explanation.

**`pre-akka-push`** (PreToolUse) - Makes the akka-org review rule enforced rather than advisory. Before any Bash/PowerShell `git push`, it checks whether `origin` is under `github.com/akka/` and the branch is not `main`/`master`. If so it requires `~/.claude/reviews/<repo>-<branch>-review.md` to exist, to be newer than the branch tip, and to carry a `READY TO PUSH` verdict — otherwise the push is denied with the reason. A report older than the tip reviewed code that is no longer being pushed, so it is treated as absent. Everything else exits silently. Override with `AKKA_PR_REVIEW_SKIP=1 git push ...`.

**`post-angular-edit`** (PostToolUse) - After editing any file under `frontend/src/`, reminds about the `ng build -> copy` step. The Angular source and the compiled static resources served by Java are separate, so forgetting to rebuild leads to stale UI.

## What the Skills Do

**`/fe-build [dev|prod|serve]`** - Runs the full Angular build pipeline:
- `dev`: `ng build --configuration development` + copy to static-resources
- `prod`: `ng build` (optimized) + copy
- `serve`: starts `ng serve` on port 4200 with proxy config

**`/akka-pr-review`** - Run on a finished branch before pushing it for a PR in the
`akka` GitHub org. It spawns a fresh agent that is given the *problem* but never the
*fix*, so it derives the root cause itself instead of grading the change against the
approach that produced it. The reviewer is read-only apart from its report, which it
writes to `~/.claude/reviews/<repo>-<branch>-review.md` — outside every repo, so it
cannot land on the branch. Output is a verdict (READY TO PUSH / NEEDS WORK / NEEDS
HUMAN DECISION) plus findings tagged `[blocker]` / `[should-fix]` / `[nit]`.

## Global CLAUDE.md Principles

### LLM Discipline

- **Think before coding**: state assumptions, surface tradeoffs, ask when unclear
- **Simplicity first**: minimum code, no speculative features, no abstractions for single-use code
- **Surgical changes**: touch only what the request demands, don't refactor adjacent code
- **Goal-driven execution**: transform tasks into verifiable success criteria and loop until met

### Operational Rules

- **Grep first**: never read large files whole; grep for the specific symbol needed
- **Memory**: always check project memory at session start; save non-obvious findings
- **Environment variables**: API keys follow `{PROVIDER}_{SERVICE}_API_KEY` such as `GOOGLE_AI_GEMINI_API_KEY`, `VERTEX_AI_API_KEY`, `ANTHROPIC_API_KEY`, and `OPENAI_API_KEY`; never use generic names like `GOOGLE_API_KEY`
- **Git safety**: never force-push main, never amend published commits, always stage by name
- **Terse responses**: no trailing summaries, no emojis, diff speaks for itself
- **No claude.ai publishing**: HTML deliverables are written to a local file and opened from disk; the Artifact tool is never called
- **Comments describe the code, not the session**: rationale belongs in comments, chronology belongs in commit messages
- **Akka org PRs**: run `/akka-pr-review` before pushing a branch for a PR in the `akka` org
