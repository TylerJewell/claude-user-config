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

# ── robert-mcp (clone, build, register, install assets) ─────────────────────
# robert-mcp is cloned as a subdirectory of this repo (gitignored). It's
# updated on every install.sh run so machines stay in sync with upstream.
# Skipped gracefully if `go` isn't on PATH.
RW_DIR="$REPO_DIR/robert-mcp"
if ! command -v go >/dev/null 2>&1; then
    echo "⚠ go not found on PATH — skipping robert-mcp install"
else
    if [ -d "$RW_DIR/.git" ]; then
        (cd "$RW_DIR" && git pull --ff-only 2>&1 | sed 's/^/  /')
        echo "✓ robert-mcp pulled"
    else
        git clone https://github.com/akka/robert-mcp.git "$RW_DIR" 2>&1 | sed 's/^/  /'
        echo "✓ robert-mcp cloned"
    fi
    (cd "$RW_DIR" && go install .)
    GOBIN="$(go env GOBIN)"
    [ -z "$GOBIN" ] && GOBIN="$(go env GOPATH)/bin"
    RW_BIN="$GOBIN/robert-mcp"
    [ -x "$RW_BIN.exe" ] && RW_BIN="$RW_BIN.exe"
    "$RW_BIN" register --user --config "$RW_DIR/config.yaml" | sed 's/^/  /'
    "$RW_BIN" install --source "$RW_DIR" | sed 's/^/  /'
    echo "✓ robert-mcp registered + assets installed"
fi

# ── akka-mcp-gateway (company MCP gateway) ──────────────────────────────────
# Registered at user scope so every project sees it, matching robert-mcp.
# Authentication is per-machine and interactive — run /mcp in Claude Code and
# sign in through Okta. No credential belongs in this repo.
# The scope is matched, not just the name: a registration that exists only at
# local scope is confined to one project, which is the state this replaces.
GATEWAY_NAME="akka-mcp-gateway"
GATEWAY_URL="https://mcp.akka.services/mcp"
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠ claude not found on PATH — skipping $GATEWAY_NAME registration"
elif claude mcp get "$GATEWAY_NAME" 2>/dev/null | grep -q "User config"; then
    echo "✓ $GATEWAY_NAME already registered at user scope"
else
    claude mcp add --transport http --scope user "$GATEWAY_NAME" "$GATEWAY_URL" 2>&1 | sed 's/^/  /'
    echo "✓ $GATEWAY_NAME registered — run /mcp to authenticate"
fi

# ── google-sheets (personal Google Workspace, Tyler's personal Gmail) ───────
# Google's official remote Sheets MCP server. Registered at user scope so it's
# available in every project. Authentication is per-machine: user must create
# an OAuth 2.0 Web-application client in Google Cloud Console (redirect URI
# https://claude.ai/api/mcp/auth_callback), enable the Sheets API and Sheets
# MCP API, then run /mcp in Claude Code and paste Client ID + Secret at the
# prompt. No credential belongs in this repo. Tied to tylerjewell@gmail.com,
# not any akka.io account.
SHEETS_NAME="google-sheets"
SHEETS_URL="https://sheetsmcp.googleapis.com/mcp/v1"
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠ claude not found on PATH — skipping $SHEETS_NAME registration"
elif claude mcp get "$SHEETS_NAME" 2>/dev/null | grep -q "User config"; then
    echo "✓ $SHEETS_NAME already registered at user scope"
else
    claude mcp add --transport http --scope user "$SHEETS_NAME" "$SHEETS_URL" 2>&1 | sed 's/^/  /'
    echo "✓ $SHEETS_NAME registered — run /mcp to authenticate"
fi

# ── settings.json (deep merge: repo wins on tracked keys) ───────────────────
SETTINGS_PATH="$CLAUDE_DIR/settings.json"
REPO_SETTINGS="$REPO_DIR/settings.json"

if [ ! -f "$SETTINGS_PATH" ]; then
    cp "$REPO_SETTINGS" "$SETTINGS_PATH"
    echo "✓ settings.json → ~/.claude/settings.json (new)"
else
    # Deep merge: repo values win on conflicts; local-only keys are preserved.
    # Backup is only written when the merged output actually differs from the
    # existing file, so repeated no-op runs (e.g. from the SessionStart hook)
    # don't litter ~/.claude with dozens of identical backups.
    python3 - "$SETTINGS_PATH" "$REPO_SETTINGS" <<'PYEOF'
import sys, json, shutil, datetime

existing_path = sys.argv[1]
repo_path = sys.argv[2]

with open(existing_path, 'rb') as f:
    existing_raw = f.read()
with open(repo_path, 'rb') as f:
    repo_raw = f.read()

existing = json.loads(existing_raw)
repo = json.loads(repo_raw)


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
    return upstream


def merge_hooks(local_hooks, repo_hooks):
    """Per-event entry union: a repo hook entry is appended to local hooks if an
    identical entry (by JSON serialization) isn't already present. This works
    for events with matchers (PreToolUse) and without (SessionStart)."""
    result = dict(local_hooks) if local_hooks else {}
    for event, repo_entries in (repo_hooks or {}).items():
        result.setdefault(event, [])
        existing_keys = {json.dumps(e, sort_keys=True) for e in result[event]}
        for entry in repo_entries:
            key = json.dumps(entry, sort_keys=True)
            label = entry.get("matcher") or event
            if key not in existing_keys:
                result[event].append(entry)
                existing_keys.add(key)
                print(f"  + Added hook: {label}")
            else:
                print(f"  ~ Skipped (already exists): {label}")
    return result


local_hooks = existing.pop("hooks", {})
repo_hooks = repo.pop("hooks", {})

merged = deep_merge(existing, repo)
merged["hooks"] = merge_hooks(local_hooks, repo_hooks)

merged_raw = (json.dumps(merged, indent=2) + "\n").encode("utf-8")

if merged_raw == existing_raw:
    print("  = settings.json already up to date")
else:
    backup = f"{existing_path}.bak.{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}"
    shutil.copy2(existing_path, backup)
    with open(existing_path, 'wb') as f:
        f.write(merged_raw)
    print(f"  + settings.json updated (backup: {backup})")
PYEOF
    echo "✓ settings.json deep-merge complete"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "Done! Restart Claude Code for hook changes to take effect."
echo ""
echo "For new projects, copy templates as needed:"
echo "  cp $REPO_DIR/templates/.claudeignore.template <project>/.claudeignore"
echo "  cp $REPO_DIR/templates/project-settings.json.template <project>/.claude/settings.json"
