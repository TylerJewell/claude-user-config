#!/bin/bash
# Install Tyler's portable Codex configuration.
# Usage:
#   bash install-codex.sh
#   bash install-codex.sh --project /path/to/project
#   bash install-codex.sh --project /path/to/project --force-project-files
#   bash install-codex.sh --dry-run

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_SOURCE="$REPO_DIR/codex"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PROJECT_PATH="${1:-}"
FORCE_PROJECT_FILES=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      PROJECT_PATH="${2:-}"
      shift 2
      ;;
    --force-project-files)
      FORCE_PROJECT_FILES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      PROJECT_PATH="$1"
      shift
      ;;
  esac
done

echo "Installing Codex user config from $REPO_DIR"
echo ""

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$CODEX_HOME"
fi

CONFIG_SOURCE="$CODEX_SOURCE/config.toml.template"
CONFIG_TARGET="$CODEX_HOME/config.toml"
BEGIN_MARKER="# BEGIN claude-user-config codex managed"
END_MARKER="# END claude-user-config codex managed"

TMP_CONFIG="$(mktemp)"
trap 'rm -f "$TMP_CONFIG"' EXIT

python3 - "$CONFIG_TARGET" "$CONFIG_SOURCE" "$BEGIN_MARKER" "$END_MARKER" > "$TMP_CONFIG" <<'PYEOF'
import re
import sys
from pathlib import Path

target = Path(sys.argv[1])
source = Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]

existing = target.read_text(encoding="utf-8") if target.exists() else ""
managed = source.read_text(encoding="utf-8").strip()

content = re.sub(
    rf"(?ms)^{re.escape(begin)}\r?\n.*?^{re.escape(end)}\r?\n?",
    "",
    existing,
)
for table in ("windows", "mcp_servers.akka"):
    content = re.sub(rf"(?ms)^\[{re.escape(table)}\]\r?\n.*?(?=^\[|\Z)", "", content)

content = content.rstrip()
if content:
    content += "\n\n"
content += f"{begin}\n{managed}\n{end}\n"
sys.stdout.write(content)
PYEOF

if [ ! -f "$CONFIG_TARGET" ] || ! cmp -s "$TMP_CONFIG" "$CONFIG_TARGET"; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Would update $CONFIG_TARGET"
  else
    if [ -f "$CONFIG_TARGET" ]; then
      BACKUP="$CONFIG_TARGET.bak.$(date +%Y%m%d-%H%M%S)"
      cp "$CONFIG_TARGET" "$BACKUP"
      echo "Backed up existing config.toml to $BACKUP"
    fi
    cp "$TMP_CONFIG" "$CONFIG_TARGET"
    echo "Installed managed Codex config block to $CONFIG_TARGET"
  fi
else
  echo "config.toml already contains the managed Codex config"
fi

install_project_template() {
  local source="$1"
  local destination="$2"
  local label="$3"

  if [ -f "$destination" ] && [ "$FORCE_PROJECT_FILES" -eq 0 ]; then
    echo "Skipped $label because $destination already exists. Use --force-project-files to overwrite."
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Would install $label to $destination"
    return
  fi

  cp "$source" "$destination"
  echo "Installed $label to $destination"
}

if [ -n "$PROJECT_PATH" ]; then
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$PROJECT_PATH"
  fi
  install_project_template "$CODEX_SOURCE/mcp.json.template" "$PROJECT_PATH/.mcp.json" "project .mcp.json"
  install_project_template "$CODEX_SOURCE/AGENTS.md.template" "$PROJECT_PATH/AGENTS.md" "project AGENTS.md"
fi

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. No files were changed."
else
  echo "Done. Restart Codex for user config changes to take effect."
fi
echo "Secrets and local runtime files were not copied."
