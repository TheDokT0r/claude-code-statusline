#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
DEST="$CLAUDE_DIR/statusline-command.sh"
REPO_URL="https://raw.githubusercontent.com/TheDokT0r/claude-code-statusline/master/statusline.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { printf "${GREEN}[+]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
error() { printf "${RED}[x]${NC} %s\n" "$1"; exit 1; }

# Check dependencies
command -v jq >/dev/null 2>&1 || error "jq is required. Install it with: brew install jq"
command -v curl >/dev/null 2>&1 || error "curl is required."

# Create .claude dir if needed
mkdir -p "$CLAUDE_DIR"

# Download statusline script
info "Downloading statusline script..."
curl -fsSL "$REPO_URL" -o "$DEST"
chmod +x "$DEST"
info "Installed to $DEST"

# Configure Claude Code settings
STATUSLINE_CONFIG='{"type":"command","command":"bash ~/.claude/statusline-command.sh"}'

if [ -f "$SETTINGS_FILE" ]; then
  existing=$(cat "$SETTINGS_FILE")
  if echo "$existing" | jq -e '.statusLine' >/dev/null 2>&1; then
    warn "statusLine already configured in $SETTINGS_FILE"
    printf "    Overwrite? [y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "$existing" | jq --argjson sl "$STATUSLINE_CONFIG" '.statusLine = $sl' > "$SETTINGS_FILE"
      info "Updated statusLine in $SETTINGS_FILE"
    else
      info "Skipped settings update. Script is installed — configure manually if needed."
    fi
  else
    echo "$existing" | jq --argjson sl "$STATUSLINE_CONFIG" '. + {statusLine: $sl}' > "$SETTINGS_FILE"
    info "Added statusLine to $SETTINGS_FILE"
  fi
else
  jq -n --argjson sl "$STATUSLINE_CONFIG" '{statusLine: $sl}' > "$SETTINGS_FILE"
  info "Created $SETTINGS_FILE with statusLine config"
fi

info "Done! Restart Claude Code to see the new statusline."
warn "Requires a Nerd Font in your terminal for icons to render correctly."
