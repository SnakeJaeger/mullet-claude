# Desktop / tablet setup map

Everything here is user config; nothing under /usr/share/omarchy is modified.
Tablet mode is switched by the fold sensor via `~/.local/bin/tablet-mode`,
which swaps the desktop bar for the tablet bar and back.

## Shell plugins (`~/.config/omarchy/plugins/`)

### Desktop only — `daa.desktop-*`
| Plugin | What it is |
|---|---|
| `daa.desktop-bar` | Desktop bar (islands, stats flyout) |
| `daa.desktop-arch-menu` | Arch logo button → Go menu |
| `daa.desktop-workspaces` | Workspace dots |
| `daa.desktop-app-name` | Focused-app island next to the workspaces |
| `daa.desktop-media` | Now-playing island (only while playing) |
| `daa.desktop-indicators` | Clock island indicators + drop-down toggle panel |

### Tablet only — `daa.tablet-*`
| Plugin | What it is |
|---|---|
| `daa.tablet-bar` | Touch bar shown in tablet mode |
| `daa.tablet-menu` | Arch button → tablet menu |
| `daa.tablet-workspace` | Current workspace / window list |
| `daa.tablet-apps` | App-grid button |
| `daa.tablet-apps-grid` | Touch app grid (list in `~/.config/tablet-mode/apps`) |
| `daa.tablet-keyboard` | On-screen keyboard button |
| `daa.tablet-rotate` | Rotate / rotation-lock button |
| `daa.tablet-quick` | Quick toggles button |
| `daa.tablet-media` | Play/pause button |

### Shared — plain `daa.*` (behave differently in tablet mode)
| Plugin | What it is |
|---|---|
| `daa.menu` | All menus (Go menu, tablet menu, quick toggles…); typing in the root menu adds a "Search all files" row (→ ~/.local/bin/file-search → Catfish dropdown); system (shutdown) menu is borderless, bottom-left, slides in from the left; menu keys go through ~/.local/bin/menu-toggle (re-press closes, other key switches); SUPER+K keybindings list is borderless, 600x720 in the Bitwarden dropdown spot, slides in from the right |
| `daa.clipboard` | Clipboard manager (SUPER+V, SUPER+CTRL+V), borderless, bottom-right, slides in from the right; header Clear button (= Shift+Delete, asks first) |
| `daa.launcher` | App launcher (scroll rail in tablet mode) |
| `daa.osd` | On-screen display |
| `daa.background` | Wallpaper (tap = dismiss in tablet mode) |

## Other files

| File | Mode | What |
|---|---|---|
| `~/.local/bin/tablet-mode` | tablet | The switcher: devices, bar swap, gestures, keyboard, rotation, per-mode wallpaper, `dismiss` |
| `~/.config/tablet-mode/gestures` | tablet | Edge-swipe gestures (lisgd) |
| `~/.config/tablet-mode/apps` | tablet | Apps shown in the tablet app grid |
| `~/.config/hypr/tablet_mode.lua` | tablet | Fold switch → `tablet-mode on/off` |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | both | Menu entries; `tablet.*` entries are tablet only |
| `~/.config/omarchy/shell.json` | both | Bar layout + enabled plugins (tablet mode switches `bar.id`) |
| `~/.config/omarchy/shell.toml` | both | Theme overrides (borderless popups). Tablet mode appends `[tablet]` / bigger font while on and restores the file on exit |
| `~/.config/hypr/*.lua` (rest) | both | Hyprland config (scratchpads, dropdowns, looknfeel…) |

Runtime state (don't edit): `~/.local/state/tablet-mode/`
(`state`, `rotation`, `sensor`, per-mode `background-laptop` / `background-tablet`).

## Backups

All old `.bak` files: `~/.local/state/config-backups/`
(`config/` mirrors `~/.config`, `tablet-mode-state/` holds old tablet-mode
backups, `pre-reorg-*.tar.gz` is a full snapshot taken before the
`daa.desktop-*` rename, `unused-clone-files/` holds the bars' never-loaded
`widgets/` + `indicators/` copies and the retired `daa.tablet` button).
