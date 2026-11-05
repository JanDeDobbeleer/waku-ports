# Nomarchy bar

This is the Quickshell implementation of the Nomarchy status bar. It is
shipped as a first-party plugin of [`nomarchy-shell`](../../README.md), the
long-running shell host. The bar is mounted at startup and lives inside
the shell for its whole session.

- `manifest.json` declares the plugin (`id: nomarchy.bar`, `kind: bar`) and points at `Bar.qml` as the entry point.
- `Bar.qml` is Nomarchy-owned bar engine code, loaded by the nomarchy-shell host. Users should not edit it directly.
- `widgets/` holds simple first-party bar widgets with sibling manifests.
- Feature plugins such as `../panels/audio/`, `../panels/network/`, `../panels/power/`, and `../agents/` provide richer popup bar plugins.
- The bar receives its config from the host shell as a `barConfig` property; the host loads it from `~/.config/nomarchy/shell.json` (or `config/nomarchy/shell.json` when the user has no file).
- `nomarchy bar position` updates only the user shell.json file.

## Customizing

The bar config lives under the `bar:` key of [`~/.config/nomarchy/shell.json`](../../../docs/nomarchy-shell.md#shelljson). Out of the box the shell uses [`config/nomarchy/shell.json`](../../../config/nomarchy/shell.json). Once you customize anything via the bar gestures, `nomarchy bar ...`, or by editing shell.json directly, your file is canonical — there is no deep-merge.

The bar is configured directly on the bar itself: drag empty bar space (or click-and-hold) to move the bar to another screen edge, double-left-click empty center-bar space to cycle the bar background from clear to glassy to opaque, and drag widgets to reorder them. The `nomarchy bar position`, `nomarchy bar background`, `nomarchy bar move`, and `nomarchy bar set` commands do the same from scripts. Enable or disable widgets with `nomarchy plugin enable` and `nomarchy plugin disable` (widget ids come from `nomarchy plugin list`).

Example `shell.json` (bar subtree only shown):

```json
{
  "version": 1,
  "bar": {
    "position": "top",
    "background": "opaque",
    "layout": {
      "left": [
        { "id": "nomarchy.menu" },
        { "id": "nomarchy.spacer", "size": 12 },
        { "id": "nomarchy.workspaces" }
      ],
      "centerBegin": [
        { "id": "nomarchy.media" }
      ],
      "center": [
        { "id": "nomarchy.clock", "format": "HH:mm" }
      ],
      "centerEnd": [],
      "right": [
        { "id": "nomarchy.audio" },
        { "id": "nomarchy.power" }
      ]
    }
  }
}
```

`center` is a box in the middle of the bar whose modules are centered as one group on the exact horizontal/vertical center. `centerBegin` and `centerEnd` hang off the box's two edges and move out as it grows; with the box empty they meet in the middle of the bar.

## Module catalogue

### First-party interactive widgets

| Name | What it does | Interactions |
|---|---|---|
| `nomarchy.menu` | Nomarchy menu launcher | left = menu · right = terminal |
| `nomarchy.workspaces` | Hyprland workspace switcher; the focused workspace shows its layout | left = focus workspace, or cycle the focused one's layout |
| `nomarchy.clock` | Date/time label + popup with a month grid, ISO week numbers, and month stepping | left = popup · right = cycle label format · middle = timezone selector |
| `nomarchy.media` | MPRIS now-playing — scrolling track + artist, cover-art popup | left = play/pause · middle = next · scroll = prev/next · right = popup |
| `nomarchy.indicators` | Manual state indicators | left = indicator action |
| `nomarchy.system-update` | Available update indicator | left = update |
| `nomarchy.tray` | System tray | hover = reveal drawer · right on chevron = manage |
| `nomarchy.weather` | Weather icon + popup with forecast | left = popup · right = full notification |
| `nomarchy.microphone` | Mic icon + scroll volume | left = mute toggle · middle = audio panel · scroll = source volume |

| `nomarchy.audio` | Volume icon + popup with master slider, output-device picker, per-app mixer | left = popup · right = mute · middle = popup · scroll = volume |
| `nomarchy.network` | Wi-Fi/Ethernet icon + popup with Wi-Fi scan, signal, connect, DNS provider selection | left = popup |
| `nomarchy.tailscale` | Tailscale status, connection switcher, machine browser, and copy actions | left = popup · right = toggle · middle = refresh |
| `nomarchy.agents` | AI coding agent limits with pace, today, last week, and all-time model breakdown | left = panel · right = launch agent · middle = next subscription |
| `nomarchy.power` | Battery/AC icon + popup with battery stats, power profiles, and system info | left = popup · right = toggle percentage |
| `nomarchy.bluetooth` | Bluetooth icon + popup with device list, connect/disconnect, battery | left = popup · right = toggle radio |
| `nomarchy.monitor` | Brightness and laptop display controls | left = popup |

The `nomarchy.indicators` widget loads individual bar indicators from `indicators/`. Omit `items` (or set it to an empty array) to show all indicators in the default order, or set `items` to a subset such as `["Dnd", "Reminder", "NightLight"]`. Set `alwaysShow` to `true` to keep inactive indicators visible instead of revealing them only on hover. Multiple `nomarchy.indicators` instances are allowed, so different sections can show different subsets.

## Orientation

All widgets work in `top`, `bottom`, `left`, and `right` positions. Popups anchor on the side opposite the bar edge, sliding into the workspace. Vertical bars use 28px width; widgets that show text fall back to compact icon-only forms (e.g. `media` hides its scrolling label).

## Icon geometry

Use `BarIconButton` from `qs.Ui` for bar icons. It fits the visible glyph bounds to `Style.bar.iconSize` and centers them on both axes. It preserves each glyph's aspect ratio. Set `labelText` for an adjacent text label, such as the battery percentage.

The `[bar]` section of a theme's `shell.toml` supplies the shared dimensions. `icon-size` sets the visual target, with a default of 12 logical pixels. `icon-canvas` sets the canvas, with a default of 16 logical pixels. `icon-slot` and `status-slot` set the button extent. These dimensions follow the font scale unless `scale-with-font` is false.

Custom `iconComponent` content also fits the shared target. Its source dimensions can be 15px or another size. The bar measures its glyph, image, or vector bounds and applies one scale without changing its aspect ratio. A source `iconSize` override does not change the rendered target. Image padding remains part of an application's tray asset.

Custom text bounds include text alignment and padding. The bar applies each shape's fill mode and alignment to `Shape.boundingRect`. Canvas and shader icons use their item bounds. Set their item size to match their artwork.

`WidgetButton` also uses the shared renderer for a single icon glyph. This covers custom command widgets and existing plugins that use `WidgetButton` with a different `fontSize`. Text labels retain their text size. Custom widgets must use `WidgetButton` or `BarIconButton` for this icon contract.

## Custom user modules

The schema accepts arbitrary module ids that you provide. Set `type` to `command` for shell-driven output or `qml` for a custom QML widget. Both still go under `bar.layout.<section>` in `shell.json`.

Command module:

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "right": [
        { "id": "nomarchy.tray" },
        { "id": "vpn", "type": "command", "exec": "~/.config/nomarchy/bar/scripts/vpn-status", "interval": 5, "tooltip": "VPN", "onClick": "nm-connection-editor" },
        { "id": "nomarchy.audio" }
      ]
    }
  }
}
```

The command may print plain text or Waybar-style JSON, for example:

```json
{"text":"󰌆","tooltip":"Work VPN","class":"active"}
```

QML module:

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "right": [
        { "id": "gpu", "type": "qml" },
        { "id": "nomarchy.audio" }
      ]
    }
  }
}
```

Then create `~/.config/nomarchy/bar/modules/gpu.qml`. If you want to store it elsewhere, add a `source` path.

Custom QML modules should be an `Item` with `implicitWidth` and `implicitHeight`. They may optionally define these properties, which the bar fills after loading:

```qml
import QtQuick

Item {
  property var bar
  property string moduleName
  property var settings

  implicitWidth: 28
  implicitHeight: bar ? bar.barSize : 26

  Text {
    anchors.centerIn: parent
    text: "GPU"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 12
  }

  MouseArea {
    anchors.fill: parent
    onClicked: if (bar) bar.run("nomarchy-launch-or-focus-tui btop")
  }
}
```

## Bar properties available to widgets

Widgets receive `bar` (the shell root), `moduleName` (string), and `settings` (object) injected at load time. A widget that declares `fixedEdge` also gets the edge of it that stays put when it grows: `"start"` (left, or top on a vertical bar), `"end"`, or `"center"` when it grows both ways, following the section it sits in. When the center box holds more than one widget, its first gets `"end"` and its last `"start"`, like `centerBegin`'s and `centerEnd`'s. A widget that grows, like the tray's drawer or the indicator peek, can lay its content out against that edge so it doesn't shift. A widget moved to another section keeps running, and its `fixedEdge` and `settings` change in place, so bind to them rather than reading them once. The bar exposes:

- `bar.foreground`, `bar.background`, `bar.urgent` — theme colors (live-updated)
- `bar.fontFamily` — current monospace family
- `bar.position` — `"top" | "bottom" | "left" | "right"`
- `bar.vertical` — boolean shortcut
- `bar.barSize` — 26 horizontal / 28 vertical
- `bar.run(command)` — fire-and-forget bash exec (quote arguments with `Util.shellQuote` from `qs.Commons`)
- `bar.showTooltip(target, text)` / `bar.hideTooltip(target)` — shared tooltip popup
- `bar.requestPopout(owner)` / `bar.releasePopout(owner)` — one-popup-at-a-time coordinator

First-party bar widgets are manifest-backed just like third-party widgets.
Simple widgets carry sibling manifests such as `widgets/Workspaces.manifest.json`;
richer popup plugins live in feature directories such as `../panels/audio/`,
`../panels/network/`, and `../agents/`; and feature plugins such as
`nomarchy.menu` and `nomarchy.media` declare their bar-widget entry points in their own
`manifest.json`. Bar layout ids are namespaced, e.g. `nomarchy.audio`,
`nomarchy.network`, and `nomarchy.clock`.

Third-party widgets ship as separate plugins under `~/.config/nomarchy/plugins/<plugin-id>/` with their own `manifest.json` declaring `kinds: ["bar-widget"]` and a `barWidget` entry point. See the [shell reference](../../../docs/nomarchy-shell.md#plugin-manifest) for the manifest schema. Rescan, enable, and place third-party plugins with `nomarchy-shell shell rescanPlugins`, `nomarchy plugin enable`, and `nomarchy bar move`.
