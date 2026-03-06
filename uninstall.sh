#!/usr/bin/env bash
# ─────────────────────────────────────────────
# ghostty-claude-theme uninstaller
# ─────────────────────────────────────────────
set -euo pipefail

GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
GHOSTTY_THEMES_DIR="$GHOSTTY_CONFIG_DIR/themes"
GHOSTTY_CONFIG_FILE="$GHOSTTY_CONFIG_DIR/config"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}${BOLD}→${NC} $1"; }
ok()    { echo -e "${GREEN}${BOLD}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}${BOLD}!${NC} $1"; }

echo ""
echo -e "${BOLD}  ghostty-claude-theme uninstaller${NC}"
echo ""

# Remove theme file
if [[ -f "$GHOSTTY_THEMES_DIR/claude-desktop-dark" ]]; then
    rm "$GHOSTTY_THEMES_DIR/claude-desktop-dark"
    ok "Removed theme file"
else
    warn "Theme file not found (already removed?)"
fi

# Check for backup configs
BACKUPS=$(ls "${GHOSTTY_CONFIG_FILE}.backup."* 2>/dev/null || true)
if [[ -n "$BACKUPS" ]]; then
    echo ""
    info "Found config backups:"
    echo "$BACKUPS"
    echo ""
    read -rp "  Restore the most recent backup? [y/N]: " restore
    if [[ "$restore" =~ ^[Yy]$ ]]; then
        LATEST=$(echo "$BACKUPS" | sort | tail -1)
        cp "$LATEST" "$GHOSTTY_CONFIG_FILE"
        ok "Restored config from $LATEST"
    fi
else
    warn "No config backups found. You may need to update your theme = line manually."
fi

echo ""
echo -e "${GREEN}${BOLD}  Done!${NC} Reload Ghostty with Cmd+Shift+, or restart."
echo ""
