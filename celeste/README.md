# celeste for waku

A port of [celeste-dots/shell](https://github.com/caelestia-dots/shell) to waku. GPL-3.0, a
derivative work of the upstream shell (see `LICENSE` and `NOTICE`). Start it with
`waku.exe --config-home <this folder> --no-tray --font-engine=directwrite`.

## Fonts

Celeste needs two fonts that Windows does not have: **Material Symbols Rounded** (every icon) and
**Google Sans Flex** (the text). They are not in this repo. Install them once, for your user only, no
admin rights needed:

    .\tools\install-fonts.ps1

The script downloads them from upstream (google/material-design-icons and google/fonts) into
`%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registers them under `HKCU`. Restart waku afterwards.
Or install the files by hand: right-click each `.ttf` and choose "Install". Without them the icons show as
empty boxes and the text falls back to a system font.

## UI scale

Celeste's design tokens assume a screen of about 1x. On Windows at 150% every logical pixel is 1.5
physical pixels, so the shell looks about 1.5 times too big. Three settings in
`config/shell-tokens.json` fix that. The file reloads when you save it.

```json
{
  "scale": 0.75,
  "fontScale": 1.0,
  "roundingScale": 1.0
}
```

| Setting | Default | Effect |
|---|---|---|
| `scale` | `0.75` | Master factor. Multiplies every size token: spacing, padding, corner radii, font sizes (so icons too), the bar width, popout, launcher, dashboard, sidebar, OSD and notification sizes. `1` is the upstream design. |
| `fontScale` | `1.0` | Extra factor for text and icon glyphs only, on top of `scale`. Font size is `size * scale * fontScale`. |
| `roundingScale` | `1.0` | Extra factor for corner radii only, on top of `scale`. |
| `scale: "auto"` | n/a | Derives the master factor from the first screen's `devicePixelRatio`: `1 / dpr^0.6`, clamped to 0.6..1.0. A ratio of 1.0 gives 1.0, 1.5 gives 0.78, 2.0 gives 0.66. |

Pick a number to keep the same look on every machine. Pick `"auto"` when the config home moves
between screens with different Windows scale factors. The factor is read once from the first
screen, not per screen.

Code in the modules reads `Tokens.scale`, or calls `Tokens.px(n)` to scale a fixed pixel value.
Animation durations are not scaled; `appearance.anim.durations.scale` in `config/shell.json`
still controls them. The per-scale multipliers in `config/shell.json`
(`appearance.rounding.scale`, `spacing.scale`, `padding.scale`, `font.scale`) still work and
multiply with the settings above.

## Bar: workspaces, layouts and running apps

- `bar.workspaces.dynamic` (default `true`, in `config/shell.json`): the dots are every occupied
  workspace of the monitor, the active one, and the first empty workspace after the last of those
  (a slot to move to an empty desktop), in workspace order. `false` shows at least `bar.workspaces.shown` dots.
- Layout button: one button (bar entry `layout`) right below the dots shows the glyph of the
  layout of the focused workspace (waku's tiler keeps one layout per desktop and monitor). A click
  steps to the next layout, wheel up the previous, wheel down the next. Hovering shows the layout
  name and a hint. The button is hidden while the tiler is off. mainStack `view_sidebar`,
  mainStackTop `view_agenda`, columns `view_column`, rows `table_rows`, bsp `view_quilt`, grid
  `grid_view`, centerMain `view_week`.
- Running apps: one icon per application (grouped by executable, first-seen order). A count badge
  marks an application with several windows; hovering it lists them (title, workspace numeral) and a
  click on a row jumps there. A click on the icon raises the focused window's next sibling, or the
  window that had focus last. A click raises a window through the engine's `WindowControl`; the
  highlight moves at once.
- Test IPC (`wakuc --config-home <home> call bar ...`): `dots`, `layoutDry next|previous` (logs the
  command, never runs it), `clickLayout` (the click handler; only with `CELESTE_DRYRUN=1`),
  `layoutButton` (glyph, workspace, layout, visibility), `appGroups`, `apps`, `popout layout`, `popout appGroup:<exe>`,
  `activateApp <i>`, `activateGroupWindow <exe> <i>` (refuse unless the target is already focused),
  `fakeCopies <n>` (fake windows for the badge).
## Launcher commands and session actions

The launcher's `>` commands act on Windows through waku:

| Command | What it does |
|---|---|
| `>wallpaper`, `>random` | Sets the Windows wallpaper through waku's `Wallpapers` service; Windows applies its own fade. The folder is `paths.wallpaperDir` (default `~/Pictures/Wallpapers`); waku's own folder is set to the same one. Each change also sets the Windows lock screen (and sign-in screen) picture unless `services.wallpaperLockScreen` is `false` (default `true`). |
| `>light`, `>dark` | Regenerates the palette and switches the Windows app and system theme (`ControlCenter.toggleTheme`, only when it differs). |
| `>scheme`, `>variant` | Chooses the colour scheme and variant. The choice, with the mode, is saved in `state/persistent.json` and restored at startup. `dynamic` follows the current wallpaper. |
| `>lock`, `>sleep` | `LockWorkStation` and sleep, through `ControlCenter.requestAction`. |
| `>shutdown`, `>reboot`, `>logout` | Hidden and refused unless `launcher.enableDangerousActions` is `true` (default `false`). |

The session menu buttons use the same actions. `services.allowSystemActions` (default `true`)
turns every session action off when `false`. Sign out, restart and shutdown need a second press in
the session menu (waku's confirm step).

Test switch: start waku with the environment variable `CELESTE_DRYRUN=1` and every action logs a
`DRYRUN ...` line (or `REFUSED ...`) and changes nothing.

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
`wakuc desktop goto 2`, `wakuc tile status`. The layout button below the desktop dots cycles the
layouts with a click or the wheel.
