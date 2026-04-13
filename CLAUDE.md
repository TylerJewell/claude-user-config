# Tyler's Global Claude Code Guidelines

<!-- The four "LLM Discipline" principles below are adapted from
     https://github.com/forrestchang/andrej-karpathy-skills
     (Karpathy's observations on LLM coding pitfalls). -->

## Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Simplicity First
Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.
- Test: would a senior engineer say this is overcomplicated? If yes, simplify.

## Surgical Changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/vars/functions that YOUR changes orphaned. Leave pre-existing dead code alone.
- Test: every changed line should trace directly to the request.

## Goal-Driven Execution
Define success criteria. Loop until verified.
- "Add validation" → write tests for invalid inputs, then make them pass.
- "Fix the bug" → write a test that reproduces it, then make it pass.
- "Refactor X" → ensure tests pass before and after.
- For multi-step tasks, state a brief plan: `1. step → verify: check` per line.
- Strong criteria let you loop independently. "Make it work" requires constant clarification.

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

## Environment Variables — API Keys
API keys follow the pattern `{PROVIDER}_{SERVICE}_API_KEY`. When a provider has only one service, the service segment is omitted: `{PROVIDER}_API_KEY`. When a provider has multiple services, the service segment is required to disambiguate them.

Canonical names (confirmed from Akka SDK docs):
- Anthropic: `ANTHROPIC_API_KEY`
- OpenAI: `OPENAI_API_KEY`
- Google Gemini (AI Studio): `GOOGLE_AI_GEMINI_API_KEY`
- Google Vertex AI: `VERTEX_AI_API_KEY`

Rules:
- Do NOT use generic names like `GOOGLE_API_KEY`, `AI_API_KEY`, or `GEMINI_KEY`. They are ambiguous — Google alone has at least two distinct key-bearing services (AI Studio and Vertex AI) that take different keys.
- Before assuming an env var name, check the Akka `akka-context/sdk/model-provider-details.html.md` reference or grep the project for existing uses.
- When a user says "use my X key from env vars" and the specific var is not obvious, ask — don't guess.

## Security
- Never write code with SQL injection, XSS, command injection, or path traversal
- Only validate at system boundaries — trust internal code and framework guarantees
