# Start12

A port of the look of [Stardock Start11](https://www.stardock.com/products/start11/) (v3) to waku: a
taskbar of three islands and a Pro-style Start menu. Written from scratch, MIT. Not affiliated with Stardock
(see `NOTICE`).

    .\start.ps1 -Port start12

`start.ps1` hides the Windows taskbar while it runs. Pins are saved in `%LOCALAPPDATA%\waku\start12_pins.json`.

## What is in it

| Element | Works through |
|---|---|
| Start button, Start menu | click, `wakuc surface toggle startmenu`, `Ctrl+Escape` (`keys.conf`) |
| Downloads toolbar | lists your Downloads folder; a click opens the item |
| App island | built-in `Taskbar`: pinned and running apps, grouping, right-click menu |
| Tray island | built-in `Tray`, `Volume`, `Notifications`, and the clock |
| Search | `AppsService.search`; Enter starts the first match |
| Pinned page | your pins (first run: the apps you launch most); right-click to pin or unpin |
| All apps | every Start Menu app, A to Z |
| Widgets page | clock, CPU, memory, GPU and network rings, drives, a Run box |
| Folders, Control Panel, Settings, Run… | Explorer `shell:` folders, `control.exe`, `ms-settings:`, the Run dialog |
| Power | lock, sleep, sign out, restart, shut down (the last three ask for a second click) |

## Left out

Dropped because waku has no backend for them, not stubbed:

- File search (the box searches apps only; waku has no Windows Search source).
- The News widget and the world clocks (no feed source, no time-zone API in QML).
- Taskbar hover previews, vertical and grid taskbar, and the other Start styles (Windows 7, Windows 10,
  tabs and groups, fences).
- The bare Windows key: the shell owns it, so use `Ctrl+Escape`.
- The Run history line.

Window tiling is off; this port is a Start menu and taskbar, not a tiler.
