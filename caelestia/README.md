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
