import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons as Commons
import "OverlayWindowUtils.js" as OverlayWindowUtils

// Map a fresh fullscreen surface on each open. Keep its first frames
// transparent until Qt receives the output's scale, so it opens sharp without
// retaining a parked surface that can be closed when a monitor disconnects.
PanelWindow {
  id: window

  // Whether the overlay is showing. Drive this instead of visible.
  property bool shown: false
  property int shownLayer: WlrLayer.Overlay
  property int shownKeyboardFocus: WlrKeyboardFocus.Exclusive

  property var targetScreen: null
  readonly property var targetMonitor: OverlayWindowUtils.targetMonitor(Hyprland.monitors, targetScreen)

  // Wait for fullscreen geometry as well as scale so no smaller opening frame
  // is stretched across the output. Fractional scale uses units of 1/120;
  // compare in those units to tolerate floating point rounding.
  readonly property bool contentReady: shown && backingWindowVisible && !!targetScreen
    && width === OverlayWindowUtils.number(targetScreen, "width")
    && height === OverlayWindowUtils.number(targetScreen, "height")
    && !!targetMonitor && Math.round(devicePixelRatio * 120) === Math.round(OverlayWindowUtils.number(targetMonitor, "scale") * 120)
  property bool contentRevealed: false

  // Closing keeps the window mapped for one more frame at opacity 0. A window
  // hidden while its last frame was still the open overlay keeps that frame, and
  // the next open presented it (the scrim, the card) for a few frames before the
  // new content rendered, which showed as a flash of the dimmed desktop on open.
  // The transparent frame replaces it first.
  property bool closing: false

  // Light dismiss: Hyprland keeps an exclusive overlay on top, Windows does not, so focus can
  // move to another panel, menu or app and leave the overlay open behind it. Emitted when the
  // shown overlay loses the focus it had; overlays dismiss on it as they do on Escape. The
  // grace interval lets focus pass through "none active" while it moves within the shell.
  signal focusLost()
  property bool hadFocus: false
  Item {
    id: focusWatch
    readonly property bool windowActive: Window.active
    onWindowActiveChanged: {
      if (windowActive) {
        window.hadFocus = window.shown
        focusLossTimer.stop()
      } else if (window.shown && window.hadFocus) {
        focusLossTimer.restart()
      }
    }
  }
  Timer {
    id: focusLossTimer
    interval: 80
    onTriggered: if (window.shown && !focusWatch.windowActive) window.focusLost()
  }

  Timer {
    id: closeTimer
    interval: 50
    onTriggered: {
      window.closing = false
      if (!window.shown) window.targetScreen = null
    }
  }

  onContentReadyChanged: {
    contentRevealed = false
    // Resize and scale notifications arrive while Qt is still updating the
    // window. Reveal on the next turn, once its content layout has caught up.
    if (contentReady) Qt.callLater(function() {
      if (window.contentReady) window.contentRevealed = true
    })
  }

  function focusedScreen(): var {
    var monitor = Hyprland.focusedMonitor as HyprlandMonitor
    var name = monitor ? String(monitor.name || "") : ""
    for (let i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
    }
    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  }

  // Live monitor scaling does not emit a Hyprland monitor event, so its cached
  // scale can lag behind Qt. Refresh on opening and on scale changes while open.
  onShownChanged: {
    hadFocus = false
    focusLossTimer.stop()
    if (shown) {
      closeTimer.stop()
      closing = false
      targetScreen = focusedScreen()
      if (typeof Hyprland.refreshMonitors === "function") Hyprland.refreshMonitors()
    } else if (targetScreen && backingWindowVisible) {
      closing = true
      closeTimer.restart()
    } else {
      targetScreen = null
    }
  }
  onDevicePixelRatioChanged: if (shown && typeof Hyprland.refreshMonitors === "function") Hyprland.refreshMonitors()

  Connections {
    target: Quickshell
    function onScreensChanged() {
      if (window.shown && Quickshell.screens.indexOf(window.targetScreen) < 0) {
        window.targetScreen = null
        // Let the removed output finish closing its old window before mapping
        // a replacement, rather than recreating it during Qt's teardown.
        Qt.callLater(function() {
          if (window.shown && !window.targetScreen) window.targetScreen = window.focusedScreen()
        })
      }
    }
  }

  visible: (shown || closing) && !!targetScreen && !!targetMonitor
  screen: targetScreen
  anchors { top: true; left: true; bottom: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: shownLayer
  WlrLayershell.keyboardFocus: shownKeyboardFocus

  // Opacity preserves keyboard handling while the scale arrives, including
  // search keystrokes and Escape pressed immediately after opening.
  Binding {
    target: window.contentItem
    property: "opacity"
    value: window.contentRevealed ? 1 : 0
  }

  // Right-to-left languages read the overlay mirrored.
  Binding {
    target: window.contentItem
    property: "LayoutMirroring.enabled"
    value: Commons.I18n.rightToLeft
  }
  Binding {
    target: window.contentItem
    property: "LayoutMirroring.childrenInherit"
    value: true
  }
}
