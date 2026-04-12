#!/bin/bash
# install.sh — Install Tyler's Claude Code user configuration
# Run from the repo root: bash install.sh
# Safe to re-run: existing settings.json is preserved (hooks are merged), other files are overwritten.

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

# ── settings.json (merge hooks, preserve existing config) ───────────────────
SETTINGS_PATH="$CLAUDE_DIR/settings.json"
REPO_SETTINGS="$REPO_DIR/settings.json"

if [ ! -f "$SETTINGS_PATH" ]; then
    cp "$REPO_SETTINGS" "$SETTINGS_PATH"
    echo "✓ settings.json → ~/.claude/settings.json (new)"
else
    # Use Python to merge hooks into existing settings without overwriting other keys
    python3 - "$SETTINGS_PATH" "$REPO_SETTINGS" <<'PYEOF'
import sys, json

existing_path = sys.argv[1]
repo_path = sys.argv[2]

with open(existing_path) as f:
    existing = json.load(f)
with open(repo_path) as f:
    repo = json.load(f)

# Merge hooks: add repo hook matchers to existing, avoiding duplicates
existing.setdefault("hooks", {})
for event, matchers in repo.get("hooks", {}).items():
    existing["hooks"].setdefault(event, [])
    existing_matchers = [m.get("matcher") for m in existing["hooks"][event]]
    for matcher in matchers:
        if matcher.get("matcher") not in existing_matchers:
            existing["hooks"][event].append(matcher)
            print(f"  + Added {event} hook: {matcher.get('matcher')}")
        else:
            print(f"  ~ Skipped (already exists): {event} / {matcher.get('matcher')}")

with open(existing_path, 'w') as f:
    json.dump(existing, f, indent=2)
PYEOF
    echo "✓ settings.json hooks merged into ~/.claude/settings.json"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "Done! Restart Claude Code for hook changes to take effect."
echo ""
echo "For new projects, copy templates as needed:"
echo "  cp $REPO_DIR/templates/.claudeignore.template <project>/.claudeignore"
echo "  cp $REPO_DIR/templates/project-settings.json.template <project>/.claude/settings.json"
