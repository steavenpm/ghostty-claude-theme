# CLAUDE.md

Ghostty terminal theme inspired by the Claude AI desktop app dark mode. Ships a theme file, an opinionated config, and a bash installer/uninstaller.

## Project Structure

```
themes/claude-desktop-dark   # The theme file (Ghostty key=value format)
config/ghostty.conf           # Opinionated config that pairs with the theme
install.sh                    # Installer (works via curl pipe AND local clone)
uninstall.sh                  # Uninstaller (interactive, offers backup restore)
assets/                       # SVG banner, preview, palette + social-preview PNG
```

## Key Design Decisions

**Theme file** contains only color definitions (`background`, `foreground`, `cursor-color`, `selection-*`, `palette`). No layout or behavior settings — those belong in `config/ghostty.conf`.

**Install script** must work in two modes:
1. `bash <(curl -fsSL ...)` — process substitution, BASH_SOURCE resolves to `/dev/fd/XX`
2. `git clone && bash install.sh` — local execution, BASH_SOURCE resolves normally

The script detects which mode by checking if theme files exist at the resolved path. If not, it downloads them to a temp directory with a cleanup trap.

**Config file** is optional. The installer offers three choices: full config, theme-only, or skip. The config targets macOS (titlebar tabs, option-as-alt) but won't break Linux.

## Platform Gotchas

- **BSD sed/grep** (macOS): never use `\s` — use `[[:space:]]` instead
- **Process substitution**: `bash <(curl ...)` sets `BASH_SOURCE[0]` to `/dev/fd/XX`, not a real path
- **Ghostty config keys**: verify against https://ghostty.org/docs/config/reference — invalid keys are silently ignored (e.g. `background-blur-radius` is wrong, `background-blur` is correct)

## Editing the Theme

Colors follow the Claude desktop app aesthetic: warm dark brown background (#2B2523), cream foreground (#E8DDD3), terracotta orange cursor (#D97757). The 16-color ANSI palette is tuned for readability on this background.

When changing colors, update both `themes/claude-desktop-dark` and `assets/palette.svg` to stay in sync.

## Validation

- Run `bash install.sh` locally and test all three install options
- Run `bash uninstall.sh` to verify cleanup
- Check config keys against Ghostty docs — there is no linter for this
- SVGs should render correctly on GitHub (no external fonts, no foreignObject)
