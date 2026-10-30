# caelestia for wabar

A port of [caelestia-dots/shell](https://github.com/caelestia-dots/shell) to wabar. GPL-3.0, a
derivative work of the upstream shell (see `LICENSE` and `NOTICE`). Start it with
`wabar.exe --config-home <this folder> --no-tray --font-engine=directwrite`.

## UI scale

Caelestia's design tokens assume a screen of about 1x. On Windows at 150% every logical pixel is 1.5
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
  (a slot to move to an empty desktop), in workspace order. `false` shows every komorebi workspace
  (at least `bar.workspaces.shown`).
- Layout switcher: the active dot shows a glyph for its komorebi layout. Click or wheel down runs
  `komorebic cycle-layout next`, wheel up `previous`. Hovering shows the layout name.
  BSP `view_quilt`, Columns `view_column`, Rows `table_rows`, VerticalStack `view_sidebar`,
  HorizontalStack `view_agenda`, UltrawideVerticalStack `view_week`, Grid `grid_view`,
  RightMainVerticalStack `view_sidebar` mirrored.
- Running apps: one icon per application (grouped by executable, first-seen order). A count badge
  marks an application with several windows; hovering it lists them (title, workspace numeral) and a
  click on a row jumps there. A click on the icon raises the focused window's next sibling, or the
  window that had focus last. A click raises a window through the engine's `WindowControl` when the
  engine has it, else through `komorebic eager-focus`; the highlight moves at once.
- Test IPC (`wabarc --config-home <home> call bar ...`): `dots`, `layoutDry next|previous` (logs the
  command, never runs it), `appGroups`, `apps`, `popout layout`, `popout appGroup:<exe>`,
  `activateApp <i>`, `activateGroupWindow <exe> <i>` (refuse unless the target is already focused),
  `fakeCopies <n>` (fake windows for the badge).
## Launcher commands and session actions

The launcher's `>` commands act on Windows through wabar:

| Command | What it does |
|---|---|
| `>wallpaper`, `>random` | Sets the Windows wallpaper through wabar's `Wallpapers` service, with its change animation (`services.wallpaperAnimation`: `circle`, `slide_top`, `diamond`, `split`, `fade`, `none`; empty is wabar's default). The folder is `paths.wallpaperDir` (default `~/Pictures/Wallpapers`); wabar's own folder is set to the same one. |
| `>light`, `>dark` | Regenerates the palette and switches the Windows app and system theme (`ControlCenter.toggleTheme`, only when it differs). |
| `>scheme`, `>variant` | Chooses the colour scheme and variant. The choice, with the mode, is saved in `state/persistent.json` and restored at startup. `dynamic` follows the current wallpaper. |
| `>lock`, `>sleep` | `LockWorkStation` and sleep, through `ControlCenter.requestAction`. |
| `>shutdown`, `>reboot`, `>logout` | Hidden and refused unless `launcher.enableDangerousActions` is `true` (default `false`). |

The session menu buttons use the same actions. `services.allowSystemActions` (default `true`)
turns every session action off when `false`. Sign out, restart and shutdown need a second press in
the session menu (wabar's confirm step).

Test switch: start wabar with the environment variable `CAELESTIA_DRYRUN=1` and every action logs a
`DRYRUN ...` line (or `REFUSED ...`) and changes nothing.
