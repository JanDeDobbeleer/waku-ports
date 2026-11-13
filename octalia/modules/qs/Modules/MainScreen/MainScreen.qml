pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import "Backgrounds" as Backgrounds
import "Backgrounds/BackgroundHelpers.js" as BackgroundHelpers

import qs.Commons

// All panels
import qs.Modules.Panels.Audio
import qs.Modules.Panels.Battery
import qs.Modules.Panels.Bluetooth
import qs.Modules.Panels.Brightness
import qs.Modules.Panels.Changelog
import qs.Modules.Panels.Clock
import qs.Modules.Panels.ControlCenter
import qs.Modules.Panels.Dock
import qs.Modules.Panels.Launcher
import qs.Modules.Panels.Media
import qs.Modules.Panels.Network
import qs.Modules.Panels.NotificationHistory
import qs.Modules.Panels.SessionMenu
import qs.Modules.Panels.Settings
import qs.Modules.Panels.SetupWizard
import qs.Modules.Panels.SystemStats
import qs.Modules.Panels.Tray
import qs.Modules.Panels.Wallpaper
import qs.Services.Compositor
import qs.Services.Power
import qs.Services.UI

/**
* MainScreen - Single PanelWindow per screen that manages all panels and the bar
*/
PanelWindow {
  id: root

  Component.onCompleted: {
    Logger.d("MainScreen", "Initialized for screen:", screen?.name, "- Dimensions:", screen?.width, "x", screen?.height, "- Position:", screen?.x, ",", screen?.y);
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "octalia-background-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore // Don't reserve space - BarExclusionZone handles that
  WlrLayershell.keyboardFocus: {
    // No panel open anywhere: no keyboard focus needed
    if (!root.isAnyPanelOpen) {
      return WlrKeyboardFocus.None;
    }
    // Panel open on THIS screen: use panel's preferred focus mode
    if (root.isPanelOpen) {
      // Hyprland's Exclusive captures ALL input globally (including pointer),
      // preventing click-to-close from working on other monitors.
      // Workaround: briefly use Exclusive when panel opens (for text input focus),
      // then switch to OnDemand (for click-to-close on other screens).
      if (CompositorService.isHyprland) {
        return PanelService.isInitializingKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand;
      }
      return BackgroundHelpers.field(PanelService.openedPanel, "exclusiveKeyboard") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand;
    }
    // Panel open on ANOTHER screen: OnDemand allows receiving pointer events for click-to-close
    return WlrKeyboardFocus.OnDemand;
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Desktop dimming when panels are open
  property real dimmerOpacity: Settings.data.general.dimmerOpacity ?? 0.8
  property bool isPanelOpen: (PanelService.openedPanel !== null) && (BackgroundHelpers.field(PanelService.openedPanel, "screen") === screen)
  property bool isPanelClosing: (PanelService.openedPanel !== null) && BackgroundHelpers.field(PanelService.openedPanel, "isClosing")
  property bool isAnyPanelOpen: PanelService.openedPanel !== null

  color: {
    if (dimmerOpacity > 0 && isPanelOpen && !isPanelClosing) {
      return Qt.alpha(Color.mShadow, dimmerOpacity);
    }
    return "transparent";
  }

  Behavior on color {
    enabled: !PanelService.closedImmediately
    ColorAnimation {
      duration: root.isPanelClosing ? Style.animationFaster : Style.animationNormal
      easing.type: Easing.OutQuad
    }
  }

  // Reset closedImmediately flag after color change is applied
  onColorChanged: {
    if (PanelService.closedImmediately) {
      PanelService.closedImmediately = false;
    }
  }

  // Check if bar should be visible on this screen
  readonly property bool barShouldShow: {
    // Check global bar visibility (includes overview state)
    if (!BarService.effectivelyVisible)
      return false;

    // Check screen-specific configuration
    var monitors = Settings.data.bar.monitors || [];
    var screenName = screen?.name || "";

    // If no monitors specified, show on all screens
    // If monitors specified, only show if this screen is in the list
    return BackgroundHelpers.includesScreen(monitors, screenName);
  }

  // Click mask, built like Celeste's drawers: the window is click-through except where a Subtract
  // child punches the root rectangle (the mask is `window XOR root`). The bar area is punched, so the
  // bar widgets inside this window take clicks; with a panel open the whole window is punched, so a
  // click outside the panel reaches the click-to-close area. All children are direct children of the
  // root, none are nested in a wrapper region (a wrapper's empty shape cancels its Subtract children).
  mask: Region {
    id: clickableMask

    readonly property bool isFramed: Settings.data.bar.barType === "framed"
    readonly property real barThickness: Style.barHeight
    readonly property real frameThickness: Settings.data.bar.frameThickness ?? 12
    readonly property string barPos: Settings.data.bar.position || "top"
    readonly property bool showBar: root.barShouldShow && (!root.screenFullscreen || !barContent.isHidden)

    // Cover entire window (everything is masked/click-through)
    x: 0
    y: 0
    width: root.width
    height: root.height
    intersection: Intersection.Xor

    Region {
      item: fullscreenTrigger
      intersection: Intersection.Subtract
    }

    // Mode: Simple or Floating
    Region {
      x: barPlaceholder.x
      y: barPlaceholder.y
      width: (!clickableMask.isFramed && clickableMask.showBar) ? barPlaceholder.width : 0
      height: (!clickableMask.isFramed && clickableMask.showBar) ? barPlaceholder.height : 0
      intersection: Intersection.Subtract
    }

    // Mode: Framed - top side
    Region {
      x: 0
      y: 0
      width: (clickableMask.isFramed && clickableMask.showBar) ? root.width : 0
      height: (clickableMask.isFramed && clickableMask.showBar) ? (clickableMask.barPos === "top" ? clickableMask.barThickness : clickableMask.frameThickness) : 0
      intersection: Intersection.Subtract
    }

    // Framed - bottom side
    Region {
      x: 0
      y: (clickableMask.isFramed && clickableMask.showBar) ? (root.height - (clickableMask.barPos === "bottom" ? clickableMask.barThickness : clickableMask.frameThickness)) : 0
      width: (clickableMask.isFramed && clickableMask.showBar) ? root.width : 0
      height: (clickableMask.isFramed && clickableMask.showBar) ? (clickableMask.barPos === "bottom" ? clickableMask.barThickness : clickableMask.frameThickness) : 0
      intersection: Intersection.Subtract
    }

    // Framed - left side
    Region {
      x: 0
      y: 0
      width: (clickableMask.isFramed && clickableMask.showBar) ? (clickableMask.barPos === "left" ? clickableMask.barThickness : clickableMask.frameThickness) : 0
      height: (clickableMask.isFramed && clickableMask.showBar) ? root.height : 0
      intersection: Intersection.Subtract
    }

    // Framed - right side
    Region {
      x: (clickableMask.isFramed && clickableMask.showBar) ? (root.width - (clickableMask.barPos === "right" ? clickableMask.barThickness : clickableMask.frameThickness)) : 0
      y: 0
      width: (clickableMask.isFramed && clickableMask.showBar) ? (clickableMask.barPos === "right" ? clickableMask.barThickness : clickableMask.frameThickness) : 0
      height: (clickableMask.isFramed && clickableMask.showBar) ? root.height : 0
      intersection: Intersection.Subtract
    }

    // Background region for click-to-close - reactive sizing
    // Uses isAnyPanelOpen so clicking on any screen's background closes the panel
    Region {
      x: 0
      y: 0
      width: root.isAnyPanelOpen ? root.width : 0
      height: root.isAnyPanelOpen ? root.height : 0
      intersection: Intersection.Subtract
    }
  }

  // Blur behind the bar and open panels — attached to PanelWindow (required by BackgroundEffect API)

  // --------------------------------------
  // Container for all UI elements
  Item {
    id: container
    width: root.width
    height: root.height

    // Unified backgrounds container / unified shadow system
    // Renders all bar and panel backgrounds as ShapePaths within a single Shape
    // This allows the shadow effect to apply to all backgrounds in one render pass
    Backgrounds.AllBackgrounds {
      id: unifiedBackgrounds
      anchors.fill: parent
      bar: barPlaceholder.barItem || null
      windowRoot: root
      z: 0 // Behind all content
    }

    // Background MouseArea for closing panels when clicking outside
    // Uses isAnyPanelOpen so clicking on any screen's background closes the panel
    MouseArea {
      anchors.fill: parent
      enabled: root.isAnyPanelOpen
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: mouse => {
                   if (PanelService.openedPanel) {
                     PanelService.openedPanel.close();
                   }
                 }
      z: 0 // Behind panels and bar
    }

    // ---------------------------------------
    // All panels always exist
    // ---------------------------------------
    AudioPanel {
      id: audioPanel
      objectName: "audioPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    MediaPlayerPanel {
      id: mediaPlayerPanel
      objectName: "mediaPlayerPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    BatteryPanel {
      id: batteryPanel
      objectName: "batteryPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    BluetoothPanel {
      id: bluetoothPanel
      objectName: "bluetoothPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    BrightnessPanel {
      id: brightnessPanel
      objectName: "brightnessPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    ControlCenterPanel {
      id: controlCenterPanel
      objectName: "controlCenterPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    ChangelogPanel {
      id: changelogPanel
      objectName: "changelogPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    ClockPanel {
      id: clockPanel
      objectName: "clockPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    Launcher {
      id: launcherPanel
      objectName: "launcherPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    NotificationHistoryPanel {
      id: notificationHistoryPanel
      objectName: "notificationHistoryPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    SessionMenu {
      id: sessionMenuPanel
      objectName: "sessionMenuPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    SettingsPanel {
      id: settingsPanel
      objectName: "settingsPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    SetupWizard {
      id: setupWizardPanel
      objectName: "setupWizardPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    TrayDrawerPanel {
      id: trayDrawerPanel
      objectName: "trayDrawerPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    WallpaperPanel {
      id: wallpaperPanel
      objectName: "wallpaperPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    NetworkPanel {
      id: networkPanel
      objectName: "networkPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    SystemStatsPanel {
      id: systemStatsPanel
      objectName: "systemStatsPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    StaticDockPanel {
      id: staticDockPanel
      objectName: "staticDockPanel-" + (root.screen?.name || "unknown")
      screen: root.screen
    }

    // ----------------------------------------------
    // Bar background placeholder - just for background positioning (the widgets are BarContent, below)
    Item {
      id: barPlaceholder

      // Expose self as barItem for AllBackgrounds compatibility
      readonly property var barItem: barPlaceholder

      // Screen reference
      property ShellScreen screen: root.screen

      // Bar background positioning properties (per-screen)
      readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
      readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
      readonly property bool isFramed: Settings.data.bar.barType === "framed"
      readonly property real frameThickness: Settings.data.bar.frameThickness ?? 12
      readonly property bool barFloating: Settings.data.bar.barType === "floating"
      readonly property real barMarginH: barFloating ? Math.floor(Settings.data.bar.marginHorizontal) : 0
      readonly property real barMarginV: barFloating ? Math.floor(Settings.data.bar.marginVertical) : 0
      readonly property real barHeight: Style.getBarHeightForScreen(screen?.name)

      // Auto-hide properties (read by AllBackgrounds for background fade)
      readonly property bool autoHide: barContent.autoHide
      readonly property bool isHidden: barContent.isHidden

      // Expose bar dimensions directly on this Item for BarBackground
      // Use screen dimensions directly
      x: {
        if (barPosition === "right")
          return (screen?.width ?? 0) - barHeight - barMarginH;
        if (isFramed && !barIsVertical)
          return frameThickness;
        return barMarginH;
      }
      y: {
        if (barPosition === "bottom")
          return (screen?.height ?? 0) - barHeight - barMarginV;
        if (isFramed && barIsVertical)
          return frameThickness;
        return barMarginV;
      }
      width: {
        if (barIsVertical) {
          return barHeight;
        }
        if (isFramed)
          return (screen?.width ?? 0) - frameThickness * 2;
        return (screen?.width ?? 0) - barMarginH * 2;
      }
      height: {
        if (!barIsVertical) {
          return barHeight;
        }
        if (isFramed)
          return (screen?.height ?? 0) - frameThickness * 2;
        return (screen?.height ?? 0) - barMarginV * 2;
      }

      // Corner states (same as Bar.qml)
      readonly property int topLeftCornerState: {
        if (barFloating)
          return 0;
        if (barPosition === "top")
          return -1;
        if (barPosition === "left")
          return -1;
        if (Settings.data.bar.outerCorners && (barPosition === "bottom" || barPosition === "right")) {
          return barIsVertical ? 1 : 2;
        }
        return -1;
      }

      readonly property int topRightCornerState: {
        if (barFloating)
          return 0;
        if (barPosition === "top")
          return -1;
        if (barPosition === "right")
          return -1;
        if (Settings.data.bar.outerCorners && (barPosition === "bottom" || barPosition === "left")) {
          return barIsVertical ? 1 : 2;
        }
        return -1;
      }

      readonly property int bottomLeftCornerState: {
        if (barFloating)
          return 0;
        if (barPosition === "bottom")
          return -1;
        if (barPosition === "left")
          return -1;
        if (Settings.data.bar.outerCorners && (barPosition === "top" || barPosition === "right")) {
          return barIsVertical ? 1 : 2;
        }
        return -1;
      }

      readonly property int bottomRightCornerState: {
        if (barFloating)
          return 0;
        if (barPosition === "bottom")
          return -1;
        if (barPosition === "right")
          return -1;
        if (Settings.data.bar.outerCorners && (barPosition === "top" || barPosition === "left")) {
          return barIsVertical ? 1 : 2;
        }
        return -1;
      }
    }

    // Bar widgets: in this window, above the backgrounds and panels, so nothing can cover them
    BarContent {
      id: barContent
      screen: root.screen
      screenFullscreen: !!root.screenFullscreen
      placeholder: barPlaceholder
      z: 100
    }

    // Screen Corners
    ScreenCorners {
      visible: !root.screenFullscreen || !barContent.isHidden
    }

    Item {
      id: fullscreenTrigger

      readonly property string position: Settings.getBarPositionForScreen(root.screen?.name)
      readonly property bool vertical: position === "left" || position === "right"
      readonly property bool active: !!root.screenFullscreen && root.barShouldShow
      x: position === "right" ? root.width - 2 : 0
      y: position === "bottom" ? root.height - 2 : 0
      width: active ? (vertical ? 2 : root.width) : 0
      height: active ? (vertical ? root.height : 2) : 0
      z: 110

      HoverHandler {
        onHoveredChanged: BarService.setScreenHovered(root.screen?.name, hovered)
      }
    }

    // Blur behind the bar and open panels
    // Helper object holding computed properties for blur regions
    QtObject {
      id: backgroundBlur

      // Panel background geometry (from the currently open panel on this screen)
      readonly property var panelBg: {
        var op = PanelService.openedPanel;
        if (!op || BackgroundHelpers.field(op, "screen") !== root.screen || BackgroundHelpers.field(op, "blurEnabled") === false)
          return null;
        var region = BackgroundHelpers.field(op, "panelRegion");
        return (region && BackgroundHelpers.field(region, "visible")) ? BackgroundHelpers.field(region, "panelItem") : null;
      }

      // Panel background geometry for the closing panel (may coexist with panelBg)
      readonly property var closingPanelBg: {
        var cp = PanelService.closingPanel;
        if (!cp || BackgroundHelpers.field(cp, "screen") !== root.screen || BackgroundHelpers.field(cp, "blurEnabled") === false)
          return null;
        var region = BackgroundHelpers.field(cp, "panelRegion");
        return (region && BackgroundHelpers.field(region, "visible")) ? BackgroundHelpers.field(region, "panelItem") : null;
      }

      // Framed bar: inner hole boundary (where the hole begins on each axis)
      // These are the x/y coordinates of the 4 inner hole corners
      readonly property real frameHoleX: barPlaceholder.barPosition === "left" ? barPlaceholder.barHeight : barPlaceholder.frameThickness
      readonly property real frameHoleY: barPlaceholder.barPosition === "top" ? barPlaceholder.barHeight : barPlaceholder.frameThickness
      readonly property real frameHoleX2: root.width - (barPlaceholder.barPosition === "right" ? barPlaceholder.barHeight : barPlaceholder.frameThickness)
      readonly property real frameHoleY2: root.height - (barPlaceholder.barPosition === "bottom" ? barPlaceholder.barHeight : barPlaceholder.frameThickness)
      readonly property real frameR: Settings.data.bar.frameRadius ?? 20
    }

    // Native idle inhibitor — one per active MainScreen window.
    // Multiple inhibitors bound to the same enabled state are harmless;
    // having one per screen is more robust than picking a "primary" screen.
    IdleInhibitor {
      window: root
      enabled: IdleInhibitorService.isInhibited

      Component.onCompleted: {
        IdleInhibitorService.nativeInhibitorAvailable = true;
        Logger.d("IdleInhibitor", "Native IdleInhibitor active on screen:", root.screen?.name);
      }
    }
  }

  // Centralized Keyboard Shortcuts

  // These shortcuts delegate to the opened panel's handler functions
  // Panels can implement: onEscapePressed, onTabPressed, onBackTabPressed,
  // onUpPressed, onDownPressed, onReturnPressed, etc...
  Instantiator {
    model: Settings.data.general.keybinds.keyEscape || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onEscapePressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onEscapePressed()
    }
  }

  Shortcut {
    sequence: "Tab"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onTabPressed") !== undefined)
    onActivated: PanelService.openedPanel.onTabPressed()
  }

  Shortcut {
    sequence: "Backtab"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onBackTabPressed") !== undefined)
    onActivated: PanelService.openedPanel.onBackTabPressed()
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyUp || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onUpPressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onUpPressed()
    }
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyDown || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onDownPressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onDownPressed()
    }
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyEnter || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onEnterPressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onEnterPressed()
    }
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyLeft || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onLeftPressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onLeftPressed()
    }
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyRight || []
    Shortcut {
      required property var modelData
      sequence: modelData
      enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onRightPressed") !== undefined) && !PanelService.isKeybindRecording
      onActivated: PanelService.openedPanel.onRightPressed()
    }
  }

  Shortcut {
    sequence: "Home"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onHomePressed") !== undefined)
    onActivated: PanelService.openedPanel.onHomePressed()
  }

  Shortcut {
    sequence: "End"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onEndPressed") !== undefined)
    onActivated: PanelService.openedPanel.onEndPressed()
  }

  Shortcut {
    sequence: "PgUp"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onPageUpPressed") !== undefined)
    onActivated: PanelService.openedPanel.onPageUpPressed()
  }

  Shortcut {
    sequence: "PgDown"
    enabled: root.isPanelOpen && (BackgroundHelpers.field(PanelService.openedPanel, "onPageDownPressed") !== undefined)
    onActivated: PanelService.openedPanel.onPageDownPressed()
  }
}
