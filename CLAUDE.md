# Tyler's Global Claude Code Guidelines

## Grep First — Never Read Large Files Whole
Before reading any source file, estimate its size. If a file is likely > 200 lines:
1. Use Grep to find the specific method, class, or CSS selector you need
2. Use Read with offset+limit only for the relevant section
3. Never Read an entire file just to "get context" — use the Explore agent for that

## Memory System
Projects use a file-based memory at `~/.claude/projects/<project>/memory/`.
- Always check MEMORY.md at session start for non-obvious context
- Save feedback, recurring patterns, and project state as they emerge
- Never save things derivable from reading the code (imports, class names, etc.)
- Verify memory claims before acting on them — memory can be stale

## Git Safety
- Never `git push --force` to main/master without explicit user request
- Never `--no-verify` unless user explicitly asks
- Always create NEW commits — never amend unless user asks
- Stage specific files by name, never `git add -A` blindly
- Check `git status` before any commit to confirm what will be staged

## Response Style
- Keep responses short and direct — the user can read diffs
- No trailing summaries of what you just did
- No emojis unless the user asks
- When referencing code, include file_path:line_number

## Subagents
- Use the Explore subagent for open-ended codebase questions (protects main context)
- Use parallel Agent tool calls for independent research tasks
- Never duplicate work a subagent is already doing

## Security
- Never write code with SQL injection, XSS, command injection, or path traversal
- Only validate at system boundaries — trust internal code and framework guarantees
- Do not add error handling for scenarios that cannot happen
