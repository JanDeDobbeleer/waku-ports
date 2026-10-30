# Aligning the caelestia frame with Windows corners and komorebi

Goal: the frame's inner corner radius equals the app windows' corner radius, and the gap between a window and the frame or bar equals the gap between windows.

All lengths are logical px (DIP, what Qt uses) unless marked "phys". This machine: 3840x2560 at 150%, so 1 logical px = 1.5 phys px.

## Numbers

| Name | Logical | Phys at 150% | Source |
|---|---|---|---|
| Window corner radius (DWMWCP_ROUND) | 8 | 12 | Windows 11: 8 DIP; ROUNDSMALL is 4, DONOTROUND is 0 |
| Frame inner radius `border.rounding` | 8 | 12 | `config\shell.json`; Qt default was 25 |
| Frame thickness T = `border.thickness` | 8 | 12 | `config\shell.json`; default was 10 |
| Bar width B | 56 | 84 | `Tokens.sizes.bar.innerWidth` (40) + 2 x max(`Tokens.padding.small` (8), T) |
| Gap G (window to frame/bar, window to window) | 8 | 12 | chosen = T = radius |

Where the values come from (`modules\Caelestia\Config\GlobalConfig.qml`, `TokenConfig.qml`):

- `border.thickness` and `border.rounding` are plain `int` settings under `border` in `config\shell.json`. The drawers shell reads `Config.border.rounding` in `ContentWindow.qml` and passes it straight to `BlobInvertedRect.radius` (a hole with arc corners).
- The bar width is `BarWrapper.contentWidth`. Changing T changes B because the bar padding is `max(padding.small, T)`.
- Top, right and bottom edges are T wide, the left edge is B wide (`Exclusions.qml`).

## Scale hooks

`border.rounding` and `border.thickness` are read raw from `Config.border`. They are not multiplied by `Tokens.rounding.scale` or `appearance.rounding.scale`. If a master `scale` token is added, keep the frame radius out of it: Windows corners do not scale with a shell preference, only with display DPI, which Qt already handles. Keep `border.rounding` an absolute DIP value. `Tokens.sizes.bar.innerWidth` and `Tokens.padding.small` may scale; then B changes, so recompute `work_area_offset` below. T and G stay absolute so that G equals komorebi's padding.

## Komorebi (PROPOSED, not applied)

How komorebi spaces windows: the edge gap is `default_workspace_padding + default_container_padding`; the gap between two windows is `2 x default_container_padding`. Values are phys px.

Current `%USERPROFILE%\.config\komorebi\komorebi.json` (found via `$Env:KOMOREBI_CONFIG_HOME`; there is no file in `%USERPROFILE%` itself):

```
default_workspace_padding 5, default_container_padding 5
border true, border_implementation "Komorebi", border_width 4, border_offset -1, border_style "Rounded"
window_container_behaviour: not set; work_area_offset: not set (null); window_hiding_behaviour Cloak
```

`komorebic state` shows monitor DISPLAY1 3840x2560, work area equal to the full monitor (no bar registered), and a tiled layout starting at 13 phys px from each edge. 13 = 5 + 5 + 3, where 3 = `border_width` 4 + `border_offset` -1. So komorebi adds the border to the padding. This is inferred from one reading; check it before relying on it.

Gap G = 12 phys.

Option 1, border disabled (`"border": false`):

```json
{
  "default_workspace_padding": 6,
  "default_container_padding": 6
}
```

Option 2, border kept (width 4, offset -1; subtract the 3 phys px komorebi adds, check the gap with `komorebic state` after applying):

```json
{
  "default_workspace_padding": 6,
  "default_container_padding": 3
}
```

`work_area_offset`:

- With `--register-app-bar` the four ExclusionZone windows shrink the monitor work area by B on the left (84 phys) and T on the other three edges (12 phys). Komorebi tiles inside that area. Leave `work_area_offset` unset.
- Without `--register-app-bar` nothing is reserved. Set the offset by hand instead (and do not combine it with `--register-app-bar`, or the space is reserved twice):

```json
"work_area_offset": { "left": 84, "top": 12, "right": 12, "bottom": 12 }
```

If the bar is hidden (`bar.persistent` off) the left zone shrinks to T, so use left 12.

## Corner preference

`DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, ...)` with `DWMWCP_DEFAULT`, `DONOTROUND`, `ROUND` or `ROUNDSMALL` sets a window's corners. Microsoft documents it for an app that sets its own window. The documentation does not say that another process may set it on a foreign window, and in practice DWM attribute calls on a window of another process are not supported. This was not tested (no state changes were allowed). Plan on not being able to change other apps' corners. Windows 11 uses ROUND (8 DIP) by default for ordinary top-level windows, which is why the frame uses 8.

## Caveats

- Apps with square or custom corners do not match: Electron and Chromium apps with custom frames, Teams, anything with its own non-client area, and games. Maximised windows are square on Windows; with the frame they are tiled and keep their corners.
- Windows with `DWMWCP_DONOTROUND` (some tools) stay square.
- The komorebi border (4 phys wide, "Rounded") is drawn around the window and takes part of the gap.
- At other DPIs: the window radius scales with DPI, as does Qt's logical px, so 8 stays correct at 100% (8 phys) and 200% (16 phys). Komorebi paddings are phys px, so recompute them: padding = G x scale / 2.
