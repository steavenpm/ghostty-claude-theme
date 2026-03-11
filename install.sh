#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ghostty-claude-theme installer
# Installs the Claude Desktop Dark theme and optional config
# ─────────────────────────────────────────────────────────
set -euo pipefail

GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
GHOSTTY_THEMES_DIR="$GHOSTTY_CONFIG_DIR/themes"
GHOSTTY_CONFIG_FILE="$GHOSTTY_CONFIG_DIR/config"
# macOS also reads config from Application Support — a theme set there overrides ours
GHOSTTY_MACOS_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d%H%M%S)"
BACKUP_CREATED=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}${BOLD}→${NC} $1"; }
ok()    { echo -e "${GREEN}${BOLD}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}${BOLD}!${NC} $1"; }
fail()  { echo -e "${RED}${BOLD}✗${NC} $1"; exit 1; }

# ── Resolve script directory ──
# Try to find files locally first (works for git clone + bash install.sh)
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    _candidate="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    if [[ -f "$_candidate/themes/claude-desktop-dark" ]]; then
        SCRIPT_DIR="$_candidate"
    fi
fi

# If local files not found, download them (handles bash <(curl ...) and curl | bash)
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(mktemp -d)"
    trap 'rm -rf "$SCRIPT_DIR"' EXIT
    REMOTE_URL="https://raw.githubusercontent.com/steavenpm/ghostty-claude-theme/main"
    info "Downloading theme files..."
    mkdir -p "$SCRIPT_DIR/themes" "$SCRIPT_DIR/config"
    curl -fsSL "$REMOTE_URL/themes/claude-desktop-dark" -o "$SCRIPT_DIR/themes/claude-desktop-dark" \
        || fail "Failed to download theme file. Check your internet connection."
    curl -fsSL "$REMOTE_URL/config/ghostty.conf" -o "$SCRIPT_DIR/config/ghostty.conf" \
        || fail "Failed to download config file. Check your internet connection."
    ok "Downloaded theme files"
fi

# ── Preflight checks ──
echo ""
echo -e "${BOLD}  ghostty-claude-theme installer${NC}"
echo -e "  Claude Desktop Dark theme + developer config for Ghostty"
echo ""

if ! command -v ghostty &>/dev/null; then
    warn "Ghostty not found in PATH. Install it first: https://ghostty.org"
    warn "Continuing anyway (you might have it installed as an app)..."
    echo ""
fi

# ── Handle macOS Application Support config ──
# Ghostty on macOS reads from both ~/.config/ghostty/config AND
# ~/Library/Application Support/com.mitchellh.ghostty/config.
# A theme= line in the latter overrides the former, so we need to
# comment it out to prevent conflicts.
fix_macos_config() {
    if [[ -f "$GHOSTTY_MACOS_CONFIG" ]] && grep -q "^theme[[:space:]]*=" "$GHOSTTY_MACOS_CONFIG" 2>/dev/null; then
        warn "Found conflicting theme in macOS Ghostty config:"
        warn "  $GHOSTTY_MACOS_CONFIG"
        cp "$GHOSTTY_MACOS_CONFIG" "${GHOSTTY_MACOS_CONFIG}${BACKUP_SUFFIX}"
        sed -i.tmp 's/^theme[[:space:]]*=.*$/# &  # commented by ghostty-claude-theme installer/' "$GHOSTTY_MACOS_CONFIG"
        rm -f "${GHOSTTY_MACOS_CONFIG}.tmp"
        ok "Commented out conflicting theme (backup saved)"
    fi
}

# ── Create directories ──
mkdir -p "$GHOSTTY_THEMES_DIR"

# ── Install theme ──
info "Installing claude-desktop-dark theme..."
cp "$SCRIPT_DIR/themes/claude-desktop-dark" "$GHOSTTY_THEMES_DIR/claude-desktop-dark"
ok "Theme installed to $GHOSTTY_THEMES_DIR/claude-desktop-dark"

# ── Ask about config ──
echo ""
echo -e "${BOLD}  Config options:${NC}"
echo ""
echo "  1) Apply full config (theme + cursor + font + padding + macOS settings)"
echo "     → Backs up your current config first"
echo ""
echo "  2) Theme only (just set theme = claude-desktop-dark in your config)"
echo "     → Keeps all your existing settings"
echo ""
echo "  3) Skip config (theme file is installed, you'll configure manually)"
echo ""

read -rp "  Choose [1/2/3]: " choice
echo ""

case "$choice" in
    1)
        if [[ -f "$GHOSTTY_CONFIG_FILE" ]]; then
            cp "$GHOSTTY_CONFIG_FILE" "${GHOSTTY_CONFIG_FILE}${BACKUP_SUFFIX}"
            BACKUP_CREATED=true
            ok "Backed up existing config to config${BACKUP_SUFFIX}"
        fi
        cp "$SCRIPT_DIR/config/ghostty.conf" "$GHOSTTY_CONFIG_FILE"
        ok "Full config applied"
        fix_macos_config
        ;;
    2)
        if [[ -f "$GHOSTTY_CONFIG_FILE" ]]; then
            # Remove existing theme line if present, then add new one
            if grep -q "^theme[[:space:]]*=" "$GHOSTTY_CONFIG_FILE" 2>/dev/null; then
                cp "$GHOSTTY_CONFIG_FILE" "${GHOSTTY_CONFIG_FILE}${BACKUP_SUFFIX}"
                BACKUP_CREATED=true
                sed -i.tmp 's/^theme[[:space:]]*=.*/theme = claude-desktop-dark/' "$GHOSTTY_CONFIG_FILE"
                rm -f "${GHOSTTY_CONFIG_FILE}.tmp"
                ok "Updated theme in existing config (backup saved)"
            else
                echo "theme = claude-desktop-dark" >> "$GHOSTTY_CONFIG_FILE"
                ok "Added theme to existing config"
            fi
        else
            echo "theme = claude-desktop-dark" > "$GHOSTTY_CONFIG_FILE"
            ok "Created config with theme"
        fi
        fix_macos_config
        ;;
    3)
        ok "Skipped config. Set theme = claude-desktop-dark in your Ghostty config."
        ;;
    *)
        warn "Invalid choice. Skipping config."
        ok "Theme file is installed. Set theme = claude-desktop-dark manually."
        ;;
esac

# ── Done ──
echo ""
echo -e "${GREEN}${BOLD}  Done!${NC}"
echo ""
echo "  Reload Ghostty with Cmd+Shift+, or restart the app."
if [[ "$BACKUP_CREATED" == true ]]; then
    echo ""
    echo "  To revert: your backup is at"
    echo "  ${GHOSTTY_CONFIG_FILE}${BACKUP_SUFFIX}"
fi
echo ""
