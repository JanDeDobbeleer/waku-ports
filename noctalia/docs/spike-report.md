# Noctalia port: spike report

Date: 2026-11-01. Upstream: noctalia-dev/noctalia-shell, branch `legacy-v4` (MIT, QML only).
Engine: bundle copied to `bin\` (see `bin\ENGINE.txt`, waku `9a1ae9e`). Nothing in `D:\waku` was
changed. All work is QML, shims and scripts inside this folder.

## Result

- All 413 QML files compile (`tools\loadcheck.ps1`: 0 errors, from 381 failing at the start).
- The shell starts: `windows=6`, `error=none`. The framed bar renders on a real screen with the
  launcher button, clock, system-stat icons, active-window label ("Chat | APM squad"), tray,
  notification, volume and brightness buttons, and the workspace dots (`shots\boot4.png`).
- komorebi is connected through the engine's `Workspaces` once something observes `monitors`.

Not checked: opening panels (launcher, control center, settings), the dock, workspace pills with
komorebi, notifications, click-through of the masked window (needs a person), colours against upstream.

## Port-side changes (all in this folder)

| Area | Change |
|---|---|
| Layout | Upstream tree under `modules\qs\`; `Assets\`, `Shaders\` at the root. Dynamic loads use `ShellUrl.dir` |
| Imports | `import QtQuick.Controls` became `...Controls.Basic` (214 files) |
| `qs.compat` | `Singleton`, `PopupWindow`, `IdleInhibitor`, `IdleMonitor`, `ToplevelManager` (over `TaskbarModel`), `QsMenuOpener`, `ShellUrl` |
| `Quickshell.Networking` | `modules\Quickshell\Networking`: `wifiEnabled` over `Network` |
| Compositor | `Services\Compositor\WakuService.qml` replaces six Wayland backends; `Workspaces` for workspaces, `ToplevelManager` for windows |
| Removed | `Modules\LockScreen`, blur regions, telemetry wizard and changelog start-up path |
| Stubbed | `SpectrumService` (no audio spectrum) |
| Env | `tools\run.ps1` points `NOCTALIA_CONFIG_DIR` and `NOCTALIA_CACHE_DIR` at `state\` and adds komorebic to `PATH` |

## Engine gaps found

Ordered by how many files each blocked.

1. **`Scope`/`Singleton` declares a FINAL `data` property.** Quickshell's is not final. Noctalia's
   `Settings` and `ShellState` declare `readonly property alias data`, which blocked 365 of 417 files.
   Workaround: a `Singleton` in `qs.compat` whose default property is named `children_`.
2. **`PopupWindow` has no `implicitWidth`/`implicitHeight`** (252 files). Workaround: compat wrapper.
3. **Missing Quickshell types:** `IdleInhibitor`, `IdleMonitor`, `ToplevelManager`, `QsMenuOpener`,
   `QsMenuHandle`, `Quickshell.Networking`, `Quickshell.WindowManager`, `Quickshell.Services.Pam`,
   `PwAudioSpectrum` (noctalia-qs only). Shimmed or stubbed.
4. **FINAL properties on `PanelWindow` that subclasses redeclare:** `screen`, `contentItem`,
   `hideDelay`. Renamed in the port (`popupItem`, `barHideDelay`; `required property screen` removed).
5. **`WlrLayershell.anchors { }` (grouped) and `BackgroundEffect.blurRegion` do not exist**, and
   `Region` has no `radius` or corner properties. Blur regions removed; `anchors` moved to the window.
6. **`Singleton` has no `reloadableId`** (322 files). Added to the compat type.
7. **`Hyprland.toplevels` and `Hyprland.workspaces` are empty** with komorebi running (probe
   `smoke\probe2.qml`). Not investigated; the port does not use them.
8. **`Workspaces` gives window counts, not windows.** `WakuService` puts every window on the
   focused workspace of the first monitor.
9. **`Workspaces` starts only when a binding observes it.** A probe that only reads a property sees
   `connected=false`.
10. **Windows paths:** `Quickshell.shellDir` is `D:\...`; Qt reads it as a URL with scheme `d`.
    Every Loader, `createComponent` and `source:` needs a `file:///` URL (known Qt behaviour).
11. **`qrc:/qt/qml/waku/PopupWindow.qml:174:9: Cannot specify ... anchors for items inside Column`**
    appears 14 times per start, from the engine's own file.
12. **`IconImage` cannot resolve icon theme names** (`application-x-executable`).

## Still to do

- Services that read Linux data: `SystemStatService` (`/proc/*`), `HostService` (`/etc/os-release`),
  `BrightnessService` (sysfs, ddcutil), `ClipboardService`, `ProgramCheckerService`.
- Adapters over the engine: `NetworkService` and `VPNService` (over `Network`), `BluetoothService`
  (over `Bluetooth`; pairing stubbed), `BatteryService`, `AudioService`.
- Replace or stub: `IdleService` (logs "Heartbeat monitor failed"), `TelemetryService`,
  `UpdateService`, `GitHubService`, `SupporterService`, Python callers (calendar, theming,
  `Migration56`), `ColorSchemeService` ("Failed to find color scheme files", a path issue).
- Review each panel on screen; scale setting; verify shaders (`Shaders\qsb`) load.

## Notes

- `shots\` can hold private content: the real desktop is captured. It is git-ignored; do not share.
- Tools: `tools\loadcheck.ps1` (compile every file), `tools\rootcauses.ps1` (group the errors),
  `tools\probe.ps1` (run a probe shell), `tools\run.ps1` (boot and screenshot),
  `tools\gen-qmldir.ps1`, `tools\add-compat-import.ps1`.

## Update: engine gaps closed (2026-11-01)

Engine branch `feat/quickshell-compat` in `D:\wabar-compat` (a git worktree of waku, two commits on
top of `9a1ae9e`): `8f68488` and `85f7ac5`. Not merged into `main`.

| Gap | Now |
|---|---|
| `Scope` default property `data` FINAL | default property is `shellChildren`; `data`, `screen`, `contentItem`, `hideDelay` are not FINAL |
| `Singleton` has no `reloadableId` | added to `Scope` |
| `PopupWindow` has no `implicitWidth`/`implicitHeight` | added (unset keeps the content size) |
| `IdleInhibitor`, `IdleMonitor` | in `Quickshell.Wayland` |
| `QsMenuOpener`, `QsMenuHandle` | in `Quickshell` (no entries) |
| `Quickshell.Networking` | module with `wifiEnabled`, `wifiHardwareEnabled` over `Network` |

Port shims removed because of it: `qs.compat` `Singleton`, `PopupWindow`, `IdleInhibitor`,
`IdleMonitor`, `QsMenuOpener`, and `modules\Quickshell\Networking`. On the new engine all 409 files
compile and the shell starts offscreen with `error=none`.

Still open on the engine side: `ToplevelManager` (kept in `qs.compat`, over `TaskbarModel` with a
hidden anchor window), per-workspace window lists, a bare `PopupWindow` without the themed chrome
(Noctalia's popups still hit the Column-anchors warning), `BackgroundEffect.blurRegion`, grouped
`WlrLayershell.anchors`, `Region` radius and corner properties. `Quickshell.Hyprland` is an empty stub
by design (empty models), which explains gap 7 above.

## Update: second engine pass (2026-11-01)

Engine branch `feat/quickshell-compat` now has five more commits (`74a661d` to `d275e37`, on top of
`85f7ac5`).

| Gap | Now |
|---|---|
| Noctalia's popups hit "Column will not function" | `Quickshell.PopupWindow` is a bare window (`PopupWindowBase`); `waku.PopupWindow` keeps its themed surface and column |
| `ToplevelManager` only as a port shim | `Quickshell.Wayland.ToplevelManager` and `Toplevel` over the taskbar service |
| Taskbar rows without process, class, handle, monitor | `exe`, `className`, `hwnd`, `monitorHandle` roles on `TaskbarModel` |
| `Workspaces` without the windows of a workspace | `windows` (handles) per komorebi workspace; empty with GlazeWM |

Port changes: `qs.compat` now holds only `ShellUrl`. `WakuService` takes `ToplevelManager` from the engine
and places each window on the workspace whose `windows` lists its handle. All 408 files compile and the
shell starts offscreen with `error=none` on the final build. Caelestia's offscreen smoke run is identical to
its baseline. Not checked on a live desktop: the window list and the workspace placement need a running
komorebi and a visible shell.

Still open: `BackgroundEffect.blurRegion`, grouped `WlrLayershell.anchors`, `Region` corner properties,
monitor-to-screen mapping (`Toplevel.screens` is empty), `Toplevel.maximized` and `fullscreen`.

## Update: Windows adapters (2026-11-01)

The Linux-only services now read the engine's services (`waku.services`), checked against a live engine
with `tools\livecheck.ps1` (a shell with no windows, its own config home):

| Noctalia service | Now | Live result |
|---|---|---|
| `SystemStatService` | `Cpu`, `Memory`, `Gpu`, `Disks` instances and `Network` throughput, bound only while a component is registered. Drives map to `C:\`, `D:\` and `/` (the system drive). History, thresholds and colours are upstream's | cpu 16 % on 12 cores, 36 C, memory 21.3 of 31.6 GB, disks, speeds |
| `NetworkService`, `VPNService` | `Network` (scan, known-network connect, radio switch, RAS VPN entries) | Wi-Fi connected, 7 networks, 1 VPN entry |
| `BluetoothService` | upstream, over the engine's `Quickshell.Bluetooth`; pairing calls `BluetoothDevice.pair()` instead of `bluetoothctl` and Python | adapter found |
| `BrightnessService` | `ControlCenter` brightness and sources; every screen shares one value | 60 %, available |
| `HostService` | account and machine name, "Windows" | real names |
| `FontService` | `Qt.fontFamilies()` | loads (2 families offscreen) |
| `ColorSchemeService` | `FolderListModel` over the scheme folders | "Noctalia (default)" applied |
| `WallpaperService` | `powershell Get-ChildItem` in the `mtime\|path` format `find -printf` gave | format tested on `C:\Windows\Web\Wallpaper` |
| Session actions | `ControlCenter.requestAction` (lock, sleep, hibernate, signOut, restart, shutdown) | not run |
| Compositor | komorebi windows and workspaces | 7 workspaces, 4 windows |
| Files, clipboard, URLs | `qs.compat.Os` (`mkdirp`, `rm`, `copy`, `open`) | not run |
| Hooks, custom buttons, idle commands | `cmd /c` instead of `sh -c` | not run |
| Telemetry, GitHub, supporters, night light, program checks | stubs with the same names | n/a |

Adjusted in Noctalia where the engine has no counterpart (the theme follows the engine, not the reverse):
Wi-Fi connect works for saved networks only, and disconnect, forget and airplane mode show an error or log;
Ethernet shows the adapter name and address; load average, ZFS and GPU temperature stay 0; the lock screen is
gone (lock uses `LockWorkStation`); the wallpaper is Noctalia's own window, not the Windows wallpaper.

Not done: the clipboard history (`cliphist`), emoji usage file (`sh`), `ImageCacheService` (ImageMagick and
`find`, it falls back to Qt), the plugin system (`curl`, `sh`), Wallhaven download (`curl`), template
generation for other apps (Python), the calendar sources (`khal`, Evolution), and the recursive wallpaper
folder mode beyond the PowerShell scan. A live visual pass over the panels is still to do.
