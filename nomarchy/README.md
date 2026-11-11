# nomarchy for waku

A port of the [Nomarchy 4](https://github.com/omacom/omarchy) ("Quattro") desktop shell to waku: the
top bar, the menu / app launcher, the theme and background switchers and the control panels. MIT,
derived from the upstream `shell/` directory (see `LICENSE`). The default theme is Catppuccin.

## Run it

    ..\start.ps1 -Port nomarchy       # live: your deployed engine, tray, app bar, Windows taskbar hidden
    ..\start.ps1 -Port nomarchy -Dev  # the shared bundled engine (..\bin), hidden, no tray, no app bar, taskbar left alone
    ..\stop.ps1                       # the engine restores the taskbar

| Hotkey | What |
|---|---|
| Alt+Shift+Space | The Nomarchy menu (also the Nomarchy icon in the bar) |
| Alt+Space | The app launcher (Apps list) |
| Ctrl+Alt+T | Theme switcher |
| Ctrl+Alt+B | Background switcher |
| Ctrl+Alt+E | Windows emoji picker (Win+.) |
| Ctrl+Alt+V | Windows clipboard history (Win+V) |

Needs Git for Windows (`C:\Program Files\Git`; the shell runs bash scripts), and the
**CaskaydiaMono Nerd Font**. Install it for your user, without admin rights:

    .\tools\install-fonts.ps1

The port wrapper uses the shared `tools\install-fonts.ps1` at the repository root. No Python. The shell
uses its own home, `state\home`, not your user profile.

## What it does

| Part | How it works on Windows |
|---|---|
| Bar | menu, workspaces (Windows virtual desktops), running apps (one icon per program), clock, weather, tray, bluetooth, network, audio, power |
| Menu | Apps, Appearance (Theme, Background), Trigger (Emoji, Clipboard), Setup (Audio, Bluetooth, Network, Power, Windows Settings), About, System (Lock, Sleep, Sign out, Restart, Shut down) |
| Apps | the Start menu through the engine's `AppsService`: Win32, UWP and shortcuts, with icons |
| Theme switcher | 21 Nomarchy themes (`themes\`); `tools\theme-apply.ps1 <name>` rewrites the files the shell watches, so colours change live |
| Background switcher | the images of the current wallpaper's folder (or `NOMARCHY_WALLPAPER_DIR`); a choice calls the engine's `Wallpapers.setWallpaper`, the service Celeste's port uses. It also sets the lock screen picture unless the service is told not to |
| Emoji, clipboard | Windows' own panels, opened by `tools\winkeys.ps1` (clipboard history must be on in Windows settings) |
| Wi-Fi | the engine's `Network` service behind `qs.compat.Networking`: networks, signal, saved-network connect, radio switch. A new network or password opens Windows' Wi-Fi settings; disconnect and forget use `netsh` |
| Audio, Bluetooth, battery | the engine's Pipewire, Bluetooth and UPower modules |

Dropped (they run `nomarchy-*`, `hyprctl`, `timedatectl` or other Linux commands): the indicators, world
clock, system-update, keyboard-layout, agents, monitor, Tailscale, Dropbox, Wi-Fi QR, speed-test, the
Linux emoji/clipboard/reminders overlays, night light, remote session, idle, lock screen, polkit prompt
and the Unix-socket IPC. Switched off by default: the background layer (Windows or another shell draws the
wallpaper) and the dock.

## Developing

| Tool | What it does |
|---|---|
| `tools\loadcheck.ps1` | Compiles every QML file; 0 errors expected |
| `tools\run.ps1 -Seconds 12` | Boots the shell, reports status and log problems, then quits. `-Call 'shell call nomarchy.menu open {"menu":"apps"}'` runs `wakuc call` lines |
| `tools\menu-state.ps1 -Menu apps -Rows 8` | Opens a menu and prints its state and rows, no screenshot |
| `tools\winshot.ps1` | Saves each shell window as a PNG (transparency is lost; desktop captures can contain private content) |
| `tools\theme-apply.ps1 <name>` | Applies a theme (`-Prepare` only refreshes the picker's previews) |
| `tools\build-menu.py` | Regenerates the Windows menu from the upstream one |

`Menu.qml` and `ImagePicker.qml` have `debugState` helpers (marked `PORTDBG`) that the tools above call.

## Port notes (the non-obvious ones)

- `"bash"` in a Process command resolves to the WSL launcher in System32 (Windows searches it before
  PATH). Every call uses `C:/Program Files/Git/usr/bin/bash.exe`; so does `find`.
- A multi-line script passed through argv gets mangled; the plugin scan is `services/scan-plugins.sh`.
- Paths handed to Qt need `file:///D:/...` (`Util.fileUrl`).
- The engine's `PopupAnchor` has `item`, `rect`, `edges`, `gravity` only; popups follow `anchor.item`.
- `OverlayWindow` waited for a Hyprland monitor; it now builds one from the screen.
- `IpcHandler` is the engine's own (`import waku as W`); `wakuc call <target> <function>` reaches it.
- `Quickshell.Networking` has only `wifiEnabled`; `qs.compat` supplies the rest.
- `theme.name` holds the theme's folder name (`tokyo-night`); the picker matches rows against it.

## Known gaps

- Not verified on screen: the look of the bar, menu and both switchers; applying a background (only a
  call with the current wallpaper was tried); Win+. / Win+V from the hotkeys; Wi-Fi with a real adapter.
- Wi-Fi: no password entry and no profile creation; the engine joins saved networks only.
- The audio input meter is empty (`PwNodePeakMonitor` is a stub). The weather widget needs `curl` and
  network access (wttr.in).
- The tooltip logs "Binding loop detected for property contentWidth" (engine `PopupWindow`).
- `PopupCard` and the tooltip no longer clamp to the screen edge.
- The theme list has no per-theme wallpapers (those are large and live in Nomarchy's repo).

## Keys and tiling

This port uses waku's own tiler and key handler. No komorebi, whkd or AutoHotkey is needed. The shell
turns the tiler on (`Tiling.enabled`, in `shell.qml`) and ships its bindings in `keys.conf` next to
`shell.qml`; `wakukeys` reads that file by itself when it runs with this folder as `--config-home`
(`start.ps1` and `wakuc startup enable` both do). All three ports ship the same file, so they behave the
same. Edit `keys.conf` and save: the daemon reloads it. `wakukeys status` shows what is bound.

Windows reserves `Alt+Space` and `Win+L`; they cannot be bound.

| Keys | Does |
|---|---|
| `Alt+T` | new Windows Terminal window |
| `Alt+Q` | close the focused window |
| `Alt+M` | minimize the focused window |
| `Alt+Shift+O` | reload the shell |
| **Focus** | |
| `Alt+Left/Down/Up/Right` | focus the window in that direction |
| `Alt+Shift+[` / `Alt+Shift+]` | focus the previous / next window |
| **Move** | |
| `Alt+Shift+Left/Down/Up/Right` | swap the window with its neighbour |
| `Alt+Shift+Enter` | promote the window to the main slot |
| **Stacks** (windows that share one slot; the top one shows) | |
| `Ctrl+Alt+Shift+Left/Down/Up/Right` | stack the window onto its neighbour |
| `Alt+;` | take the window out of its stack |
| `Alt+[` / `Alt+]` | cycle the stack backward / forward |
| **Resize** | |
| `Alt+=` / `Alt+-` | wider / narrower |
| `Alt+Shift+=` / `Alt+Shift+-` | taller / shorter |
| **Layout** | |
| `Alt+L` | next layout: mainStack, mainStackTop, columns, rows, bsp, grid, centerMain |
| `Alt+X` / `Alt+Y` | mirror the layout horizontally / vertically |
| `Alt+F` | float the window, or tile it again |
| `Alt+Shift+M` | monocle: the focused window fills the area |
| `Alt+Shift+R` | retile every window of the desktop |
| `Alt+P` | pause or resume the tiler |
| **Desktops** | |
| `Alt+1` ... `Alt+9` | go to desktop 1 to 9 |
| `Alt+Shift+1` ... `Alt+Shift+9` | move the window to desktop 1 to 9 (you stay); past the last desktop it makes one new desktop |
| `Ctrl+Alt+Left` / `Ctrl+Alt+Right` | previous / next desktop |

The same actions run from a terminal: `wakuc tile layout next`, `wakuc tile focus left`,
`wakuc desktop goto 2`, `wakuc tile status`.
