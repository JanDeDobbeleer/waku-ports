# Windows utilities (dashboard Utilities tab)

The dashboard's Utilities tab holds buttons for the quick actions Windows 11 offers by default.
Each button opens Windows' own window, flyout or settings page. No button changes a setting by
itself in this pass: where a setting is a toggle, the button opens the Windows UI that owns it.

Code: `modules/qs/services/UtilitiesActions.qml` (the list and the launch),
`modules/qs/modules/dashboard/UtilitiesTab.qml` (the grid), config flag `dashboard.showUtilities`
(default `true`). Test IPC: `wakuc call bar utilitiesTab`, `wakuc call bar utilitiesAction <id>`
(refused unless `CAELESTIA_DRYRUN=1`), `wakuc call bar dashTab <n>`, `wakuc call bar dashRect`.

## Sources

- **YASB (retired Qt Widgets build, tag `yasb-native-final` in the [waku repo](https://github.com/JanDeDobbeleer/waku)).** The control center
  had quick-action tiles: Do Not Disturb, Mute, Mic Mute, Screenshot (`ms-screenclip:` through
  ShellExecute, `widgets/control_center/control_center_system.cpp`), touch keyboard (TabTip COM),
  Dark Mode; a settings menu of `ms-settings:` links (Windows Update, Network, Bluetooth, Sound,
  Notifications, Power, Apps, Accounts, Privacy, all settings); power plan and mode; session
  actions. YASB had no cast, record or project action.
- **What the port already has.** The sidebar utilities panel (`modules/qs/modules/utilities`):
  Keep awake (real, `SetThreadExecutionState`), the screen recorder (stub, "Unavailable"), quick
  toggles: Wi-Fi (state only), Bluetooth (real toggle through `Quickshell.Bluetooth`), mic mute
  (real), DND (the shell's own notification DND), game mode, wallpaper playing, VPN (state only),
  settings (disabled). Light/dark and the session actions are launcher actions. The bar's
  popouts cover network, Bluetooth, battery and audio.
- **Windows 11 defaults.** Quick Settings (Win+A), notification center (Win+N), Win+X menu, Win+P
  (project), Win+K (cast), Win+G (Game Bar), Win+Shift+S (snip), Win+V (clipboard history),
  Win+. (emoji), Win+Ctrl+O (on-screen keyboard), and the `ms-settings:` deep links.
- **Snipping Tool protocol** ([Launch Snipping Tool](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-snipping-tool)).
  The new `ms-screenclip://capture/image|video` protocol requires a `redirect-uri` and a
  packaged caller; an unpackaged caller gets no UI. waku is unpackaged, so the tab uses the
  legacy bare `ms-screenclip:` (what YASB used) for the snip overlay, and starts the Snipping Tool
  app for recording.

All schemes in the table were checked as registered (`HKCR\<scheme>` exists) and all executables
as present on a Windows 11 build 26300 (ARM64) machine. No action was launched
during the check.

## How a button launches

Every target goes to `S.Shell.open` (waku's ShellExecute "open" on a worker thread). ShellExecute
resolves URIs, `.cpl` and `.msc` files, `shell:` paths and programs on `PATH` or in App Paths, and
it handles programs whose manifest asks for elevation (Task Manager), which `CreateProcess` would
refuse. With `CAELESTIA_DRYRUN=1` a click logs `DRYRUN utilities <id> <target>` instead.

A button with a `probe` file is hidden when the file is missing. One read-only PowerShell
`Test-Path` runs the first time the tab loads; until it answers every button shows. Battery saver
shows only when UPower reports a laptop battery. URI-based buttons are always shown (the schemes
are part of Windows 11).

## Candidates

Admin: whether the action itself needs elevation. Toggle: whether the Windows setting behind the
button is an on/off state, and whether that state can be read without hacks.

| Name | What it does | Trigger without synthetic input | Admin | Toggle / state readable | Recommendation |
|---|---|---|---|---|---|
| Screenshot | Snip overlay (Win+Shift+S) | `ms-screenclip:` (legacy, deprecated but handled; YASB used it) | no | no, opens UI | include (`snip`) |
| Snip & record | Snipping Tool app; image and video recording | `SnippingTool.exe` (app execution alias in `%LOCALAPPDATA%\Microsoft\WindowsApps`) | no | no | include (`snippingTool`), hidden if the alias is missing |
| Screen record overlay | Direct video capture overlay | `ms-screenclip://capture/video?...` needs `redirect-uri` and a packaged caller | no | no | skip: no UI for an unpackaged caller |
| Game Bar | Xbox Game Bar overlay with capture widget (Win+G) | `ms-gamebar:` | no | no | include (`gameBar`) |
| Project | Win+P display mode flyout | `ms-settings-displays-topology:` (also `DisplaySwitch.exe`) | no | display mode readable via `QueryDisplayConfig`; later option | include (`project`) |
| Display | Display settings | `ms-settings:display` | no | no | include (`display`) |
| Night light | Night light settings page | `ms-settings:nightlight` | no | state only in an undocumented registry blob | include (`nightLight`); no toggle |
| Volume mixer | Per-app volume page | `ms-settings:apps-volume` (classic: `sndvol.exe`) | no | no | include (`mixer`) |
| Sound | Sound settings | `ms-settings:sound` | no | no | include (`sound`) |
| Sound devices | Classic Sound control panel (devices, recording, communications) | `mmsys.cpl` | no | no | include (`soundPanel`) |
| Wi-Fi | Network list flyout of Quick Settings | `ms-availablenetworks:` | no | radio state readable (WinRT `Radio`); switching needs the radio access prompt; later option | include (`wifi`) |
| Cast | Win+K cast flyout | `ms-settings-connectabledevices:devicediscovery` | no | no | include (`cast`) |
| Bluetooth | Bluetooth & devices page | `ms-settings:bluetooth` | no | yes; the port already toggles it in the sidebar | include (`bluetooth`) |
| Airplane mode | Airplane mode page | `ms-settings:network-airplanemode` | no | radio states via WinRT `Radio`; no documented airplane switch | include (`airplane`) |
| Hotspot | Mobile hotspot page | `ms-settings:network-mobilehotspot` | no | `NetworkOperatorTetheringManager` (documented WinRT) can read and start it; later option | include (`hotspot`) |
| VPN | VPN page | `ms-settings:network-vpn` | no | port reads VPN state; no switch | include (`vpn`) |
| Quick settings | Windows Quick Settings flyout (Win+A) | `ms-actioncenter:controlcenter/&showFooter=true` (undocumented URI path; fails soft) | no | no | include (`quickSettings`) |
| Notifications | Notification center (Win+N) | `ms-actioncenter:` | no | no | include (`notifications`) |
| Focus / Do not disturb | Focus and DND settings (Win11 redirects to Notifications) | `ms-settings:quiethours` | no | Windows DND only via undocumented WNF; the shell's own DND is in the sidebar | include (`focus`); no toggle |
| Battery saver | Power & battery page | `ms-settings:batterysaver` | no | readable via `PowerManager.EnergySaverStatus` (documented); no documented setter | include (`batterySaver`), only with a battery |
| Accessibility | Accessibility settings | `ms-settings:easeofaccess` | no | no | include (`accessibility`) |
| On-screen keyboard | Classic on-screen keyboard | `osk.exe` | no | no | include (`keyboard`) |
| Touch keyboard | Touch keyboard (TabTip) | undocumented `ITipInvocation` COM (YASB used it) | no | no | skip: undocumented COM |
| Task Manager | Task Manager | `taskmgr.exe` (manifest `highestAvailable`; ShellExecute handles it) | elevates for admins | no | include (`taskManager`) |
| Terminal | Windows Terminal | `wt.exe` (app execution alias) | no | no | include (`terminal`), hidden if the alias is missing |
| Run | Run dialog (Win+R) | `shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}` | no | no | include (`run`) |
| Device Manager | Device Manager (Win+X) | `devmgmt.msc` | read only without admin | no | include (`deviceManager`) |
| Windows Update | Windows Update page (YASB settings menu) | `ms-settings:windowsupdate` | no | no | include (`update`) |
| Settings | Settings home | `ms-settings:` | no | no | include (`settings`) |
| Installed apps | Apps page (Win+X) | `ms-settings:appsfeatures` | no | no | skip: the launcher covers apps |
| Network connections | Classic adapters list | `ncpa.cpl` | no | no | skip: Wi-Fi and network pages cover it |
| Disk / Computer management | MMC consoles (Win+X) | `diskmgmt.msc`, `compmgmt.msc` | yes | no | skip: admin tools |
| Terminal (Admin) | Elevated terminal (Win+X) | ShellExecute verb `runas` | yes | no | skip: needs a UAC prompt; `Shell.open` has no verb |
| Event Viewer, Services, Resource Monitor | Admin consoles | `eventvwr.msc`, `services.msc`, `resmon.exe` | partly | no | skip: rarely used from a bar |
| Clipboard history | Win+V history flyout | no URI or program opens the flyout; `ms-settings:clipboard` only opens settings | no | no | skip |
| Emoji panel | Win+. picker | no URI or program | no | no | skip |
| Lock, sleep, sign out, shut down | Session actions | already in the session menu and launcher | no | no | skip: exists |
| Dark mode | Light/dark theme | already a launcher action (`setMode`) | no | yes | skip: exists |
| Mute, mic mute | Audio mute | already in the OSD, bar and sidebar | no | yes | skip: exists |
| Keep awake | Prevent sleep | already in the sidebar utilities (real) | no | yes | skip: exists |
| Quick Assist | Remote help | `ms-quick-assist:` | no | no | skip: niche |
| Calculator | Calculator | `calc.exe` | no | no | skip: the launcher covers apps |

## Later options

Real toggles with a documented API, not built in this pass:

- Hotspot: `Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager`.
- Wi-Fi and Bluetooth radios: `Windows.Devices.Radios.Radio` (needs radio access consent).
- Battery saver state: `Windows.System.Power.PowerManager.EnergySaverStatus` (read only).
- Project mode state: `QueryDisplayConfig` topology (read only; `SetDisplayConfig` to switch).

These need engine (C++) services in waku; the port only consumes them.
