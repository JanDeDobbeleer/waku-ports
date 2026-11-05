import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar
import qs.Services.UI

/**
* BarContent - the bar widgets, drawn inside MainScreen's window
*
* The bar background and the panels are painted by MainScreen. The widgets used to sit in a second
* window above it, and waku raised whichever Top window was shown or focused last, so MainScreen
* covered the widgets whenever a panel opened (they flickered or stopped reacting). Drawing them in
* the same window fixes their stacking by construction, as in Celeste's drawers.
*
* Instantiated once per screen by MainScreen, which gives it the bar's geometry.
*/
Item {
  id: barWindow

  required property ShellScreen screen

  // Bar rectangle inside MainScreen's window (same geometry the background is drawn with)
  required property Item placeholder
  x: placeholder.x
  y: placeholder.y
  width: placeholder.width
  height: placeholder.height

  // Hidden when auto-hidden (after the fade-out) or toggled off via IPC.
  // windowVisible stays true briefly after isHidden to allow fade-out animation.
  property bool windowVisible: !isHidden
  visible: contentLoaded && windowVisible && BarService.effectivelyVisible

  Component.onCompleted: {
    Logger.d("BarContent", "Bar content window created for screen:", barWindow.screen?.name);
    if (!isHidden)
      contentLoaded = true;
  }

  // Position and size to match bar location (per-screen)
  readonly property string barPosition: Settings.getBarPositionForScreen(barWindow.screen?.name)
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
  readonly property bool isFramed: Settings.data.bar.barType === "framed"
  readonly property real frameThickness: Settings.data.bar.frameThickness ?? 12
  readonly property bool barFloating: Settings.data.bar.barType === "floating"
  readonly property real barMarginH: Math.ceil(barFloating ? Settings.data.bar.marginHorizontal : 0)
  readonly property real barMarginV: Math.ceil(barFloating ? Settings.data.bar.marginVertical : 0)
  readonly property real barHeight: Style.getBarHeightForScreen(barWindow.screen?.name)

  // Auto-hide properties
  readonly property bool autoHide: Settings.getBarDisplayModeForScreen(barWindow.screen?.name) === "auto_hide"
  readonly property int barHideDelay: Settings.data.bar.autoHideDelay || 500
  readonly property int showDelay: Settings.data.bar.autoShowDelay || 100
  property bool isHidden: autoHide

  // Hover tracking
  property bool barHovered: false

  // Check if any panel is open on this screen
  readonly property bool panelOpen: PanelService.openedPanel !== null

  // Timer for delayed hide
  Timer {
    id: hideTimer
    interval: barWindow.barHideDelay
    onTriggered: {
      if (barWindow.autoHide && !barWindow.barHovered && !barWindow.panelOpen && !BarService.popupOpen) {
        BarService.setScreenHidden(barWindow.screen?.name, true);
      }
    }
  }

  // Timer for delayed show
  Timer {
    id: showTimer
    interval: barWindow.showDelay
    onTriggered: {
      // Only show if still hovered (via trigger zone or bar itself)
      if (barWindow.autoHide && BarService.isBarHovered(barWindow.screen?.name)) {
        BarService.setScreenHidden(barWindow.screen?.name, false);
      }
    }
  }

  // React to auto-hide state changes from BarService
  Connections {
    target: BarService
    function onBarAutoHideStateChanged(screenName, hidden) {
      Logger.d("BarContent", "onBarAutoHideStateChanged:", screenName, hidden, "my screen:", barWindow.screen?.name);
      if (screenName === barWindow.screen?.name) {
        barWindow.isHidden = hidden;
      }
    }
    function onBarHoverStateChanged(screenName, hovered) {
      if (screenName === barWindow.screen?.name && barWindow.autoHide) {
        if (hovered) {
          hideTimer.stop();
          // If bar is already visible, no need to delay
          if (!barWindow.isHidden) {
            showTimer.stop();
          } else {
            // Bar is hidden, use show delay
            showTimer.restart();
          }
        } else if (!barWindow.barHovered && !barWindow.panelOpen) {
          showTimer.stop();
          hideTimer.restart();
        }
      }
    }
  }

  // Don't hide when panel is open
  onPanelOpenChanged: {
    if (panelOpen && autoHide) {
      hideTimer.stop();
      BarService.setScreenHidden(barWindow.screen?.name, false);
    } else if (!panelOpen && autoHide && !barHovered) {
      hideTimer.restart();
    }
  }

  // React to popup menu closing
  Connections {
    target: BarService
    function onPopupOpenChanged() {
      if (!BarService.popupOpen && barWindow.autoHide && !barWindow.barHovered && !barWindow.panelOpen) {
        hideTimer.restart();
      }
    }
  }

  // React to displayMode changes
  onAutoHideChanged: {
    if (!autoHide) {
      // Show bar when auto-hide is disabled
      hideTimer.stop();
      showTimer.stop();
      barWindow.isHidden = false;
    }
    // When auto-hide is enabled, don't immediately hide - wait for mouse to leave
  }

  // Content stays loaded once initialized — never unloaded during auto-hide.
  // Destroying and recreating widgets on every hide/show cycle caused nested
  // QML incubation crashes (SIGSEGV in QV4::Object::insertMember) because
  // async widget Loaders complete during incubateFor() and their onLoaded
  // handlers trigger signal cascades mid-incubation.
  // The bar is hidden via opacity + window visibility instead.
  property bool contentLoaded: false

  // Delay window hide to allow fade-out animation to complete
  Timer {
    id: windowHideTimer
    interval: Style.animationFast
    onTriggered: {
      if (barWindow.isHidden)
        barWindow.windowVisible = false;
    }
  }

  onIsHiddenChanged: {
    if (isHidden) {
      // Delay window hide so fade-out is visible
      windowHideTimer.restart();
    } else {
      windowHideTimer.stop();
      windowVisible = true;
      if (!contentLoaded)
        contentLoaded = true;
    }
  }

  Connections {
    target: BarService
    function onEffectivelyVisibleChanged() {
      if (BarService.effectivelyVisible && !barWindow.isHidden && !barWindow.contentLoaded) {
        barWindow.contentLoaded = true;
      }
    }
  }

  // Bar content loader - loaded once, stays active for lifetime
  Loader {
    id: barLoader
    anchors.fill: parent
    active: barWindow.contentLoaded

    sourceComponent: Item {
      anchors.fill: parent

      // Fade animation
      opacity: barWindow.isHidden ? 0 : 1

      Behavior on opacity {
        enabled: barWindow.autoHide
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutQuad
        }
      }

      Bar {
        id: barContent
        anchors.fill: parent
        screen: barWindow.screen

        // Hover detection using HoverHandler (doesn't block child hover events)
        HoverHandler {
          id: hoverHandler

          onHoveredChanged: {
            if (hovered) {
              barWindow.barHovered = true;
              BarService.setScreenHovered(barWindow.screen?.name, true);
              if (barWindow.autoHide) {
                hideTimer.stop();
                showTimer.restart();
              }
            } else {
              // Skip if already hidden (being destroyed)
              if (barWindow.isHidden)
                return;
              barWindow.barHovered = false;
              BarService.setScreenHovered(barWindow.screen?.name, false);
              if (barWindow.autoHide && !barWindow.panelOpen) {
                showTimer.stop();
                hideTimer.restart();
              }
            }
          }
        }
      }
    }
  }
}
