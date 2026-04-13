#!/bin/bash
# install.sh — Install Tyler's Claude Code user configuration
# Run from the repo root: bash install.sh
# Safe to re-run: settings.json is deep-merged (repo wins on tracked keys,
# local-only keys are preserved); other files are overwritten.

set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude user config from $REPO_DIR..."
echo ""

# ── Create directories ───────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/skills"

# ── CLAUDE.md (global instructions) ─────────────────────────────────────────
cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ CLAUDE.md → ~/.claude/CLAUDE.md"

# ── Hook scripts ─────────────────────────────────────────────────────────────
cp "$REPO_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "✓ hooks/*.sh → ~/.claude/hooks/ (executable)"

# ── Skills ───────────────────────────────────────────────────────────────────
for skill_dir in "$REPO_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp -r "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/"
    echo "✓ skills/$skill_name/ → ~/.claude/skills/$skill_name/"
done

# ── settings.json (deep merge: repo wins on tracked keys) ───────────────────
SETTINGS_PATH="$CLAUDE_DIR/settings.json"
REPO_SETTINGS="$REPO_DIR/settings.json"

if [ ! -f "$SETTINGS_PATH" ]; then
    cp "$REPO_SETTINGS" "$SETTINGS_PATH"
    echo "✓ settings.json → ~/.claude/settings.json (new)"
else
    # Backup before modifying
    cp "$SETTINGS_PATH" "$SETTINGS_PATH.bak.$(date +%Y%m%d-%H%M%S)"

    # Deep merge: repo values win on conflicts; local-only keys are preserved.
    # List semantics: repo lists replace local lists entirely (except hooks matchers,
    # which are merged by matcher string).
    python3 - "$SETTINGS_PATH" "$REPO_SETTINGS" <<'PYEOF'
import sys, json

existing_path = sys.argv[1]
repo_path = sys.argv[2]

with open(existing_path) as f:
    existing = json.load(f)
with open(repo_path) as f:
    repo = json.load(f)


def deep_merge(local, upstream):
    """Repo wins on leaf conflicts. Local-only keys preserved. Lists overwrite."""
    if isinstance(upstream, dict) and isinstance(local, dict):
        result = dict(local)
        for k, v in upstream.items():
            if k in result:
                result[k] = deep_merge(result[k], v)
            else:
                result[k] = v
        return result
    # Any non-dict: upstream wins
    return upstream


def merge_hooks(local_hooks, repo_hooks):
    """Per-event matcher union: repo hooks are appended to local hooks if their
    matcher string isn't already present. Preserves local hooks not in repo."""
    result = dict(local_hooks) if local_hooks else {}
    for event, repo_matchers in (repo_hooks or {}).items():
        result.setdefault(event, [])
        existing_matchers = {m.get("matcher") for m in result[event]}
        for matcher in repo_matchers:
            name = matcher.get("matcher")
            if name not in existing_matchers:
                result[event].append(matcher)
                existing_matchers.add(name)
                print(f"  + Added {event} hook: {name}")
            else:
                print(f"  ~ Skipped (already exists): {event} / {name}")
    return result


# Pull hooks out, deep-merge everything else, then restitch hooks with the
# specialized matcher-union logic.
local_hooks = existing.pop("hooks", {})
repo_hooks = repo.pop("hooks", {})

merged = deep_merge(existing, repo)
merged["hooks"] = merge_hooks(local_hooks, repo_hooks)

with open(existing_path, 'w', newline='\n') as f:
    json.dump(merged, f, indent=2)
    f.write('\n')
PYEOF
    echo "✓ settings.json deep-merged into ~/.claude/settings.json (backup saved)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "Done! Restart Claude Code for hook changes to take effect."
echo ""
echo "For new projects, copy templates as needed:"
echo "  cp $REPO_DIR/templates/.claudeignore.template <project>/.claudeignore"
echo "  cp $REPO_DIR/templates/project-settings.json.template <project>/.claude/settings.json"
