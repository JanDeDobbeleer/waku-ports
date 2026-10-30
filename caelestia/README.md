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
