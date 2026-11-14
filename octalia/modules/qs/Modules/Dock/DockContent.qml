pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services.Compositor
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import qs.compat
import "DockHelpers.js" as DockHelpers

Item {
  id: root
  required property var dockRoot
  required property int extraTop
  required property int extraBottom
  required property int extraLeft
  required property int extraRight
  property alias dockContainer: dockContainer
  readonly property bool isAttachedMode: Settings.data.dock.dockType === "attached"

  Rectangle {
    id: dockContainer
    // For vertical dock, swap width and height logic
    width: DockHelpers.getProperty(root.dockRoot, "isVertical") ? Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 1.5) : Math.min(dockLayout.implicitWidth + Style.marginXL, DockHelpers.getProperty(root.dockRoot, "maxWidth"))
    height: DockHelpers.getProperty(root.dockRoot, "isVertical") ? Math.min(dockLayout.implicitHeight + Style.marginXL, DockHelpers.getProperty(root.dockRoot, "maxHeight")) : Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 1.5)
    color: Qt.alpha(Color.mSurface, (root.isAttachedMode ? 0 : Color.adaptiveOpacity(Settings.data.dock.backgroundOpacity)))

    // Anchor based on padding to achieve centering shift
    x: root.extraLeft > 0 ? parent.width - width : (root.extraRight > 0 ? 0 : (parent.width - width) / 2)
    y: root.extraTop > 0 ? parent.height - height : (root.extraBottom > 0 ? 0 : (parent.height - height) / 2)

    radius: Style.radiusL
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, (root.isAttachedMode ? 0 : Color.adaptiveOpacity(Settings.data.dock.backgroundOpacity)))

    MouseArea {
      id: dockMouseArea
      anchors.fill: parent
      hoverEnabled: true

      onEntered: {
        DockHelpers.setProperty(root.dockRoot, "dockHovered", true);
        if (DockHelpers.getProperty(root.dockRoot, "autoHide")) {
          DockHelpers.timerAction(root.dockRoot, "showTimer", "stop");
          DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
          DockHelpers.timerAction(root.dockRoot, "unloadTimer", "stop"); // Cancel unload if hovering
          DockHelpers.setProperty(root.dockRoot, "hidden", false); // Make sure dock is visible
        }
      }

      onExited: {
        DockHelpers.setProperty(root.dockRoot, "dockHovered", false);
        if (DockHelpers.getProperty(root.dockRoot, "autoHide") && !DockHelpers.getProperty(root.dockRoot, "anyAppHovered") && !DockHelpers.getProperty(root.dockRoot, "peekHovered") && !DockHelpers.getProperty(root.dockRoot, "menuHovered") && DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === -1) {
          DockHelpers.timerAction(root.dockRoot, "hideTimer", "restart");
        }
      }

      onClicked: {
        // Close any open context menu when clicking on the dock background
        root.dockRoot.closeAllContextMenus();
      }
    }

    Flickable {
      id: dock
      // Use parent dimensions more directly to avoid clipping
      width: DockHelpers.getProperty(root.dockRoot, "isVertical") ? parent.width : Math.min(dockLayout.implicitWidth, parent.width - Style.marginXL)
      height: !DockHelpers.getProperty(root.dockRoot, "isVertical") ? parent.height : Math.min(dockLayout.implicitHeight, parent.height - Style.marginXL)
      contentWidth: dockLayout.implicitWidth
      contentHeight: dockLayout.implicitHeight
      anchors.centerIn: parent
      clip: true

      flickableDirection: DockHelpers.getProperty(root.dockRoot, "isVertical") ? Flickable.VerticalFlick : Flickable.HorizontalFlick

      // Keep interactive dependent on overflow
      interactive: DockHelpers.getProperty(root.dockRoot, "isVertical") ? contentHeight > height : contentWidth > width

      // Centering margins
      contentX: DockHelpers.getProperty(root.dockRoot, "isVertical") && contentWidth < width ? (contentWidth - width) / 2 : 0
      contentY: !DockHelpers.getProperty(root.dockRoot, "isVertical") && contentHeight < height ? (contentHeight - height) / 2 : 0

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
          var hDelta;
                   var delta = (event.angleDelta.y !== 0) ? event.angleDelta.y : event.angleDelta.x;
                   if (DockHelpers.getProperty(root.dockRoot, "isVertical")) {
                     dock.contentY = Math.max(-dock.topMargin, Math.min(dock.contentHeight - dock.height + dock.bottomMargin, dock.contentY - delta));
                   } else {
                     // For horizontal dock, we want to scroll contentX with BOTH x and y wheels
                     hDelta = (event.angleDelta.x !== 0) ? event.angleDelta.x : event.angleDelta.y;
                     dock.contentX = Math.max(-dock.leftMargin, Math.min(dock.contentWidth - dock.width + dock.rightMargin, dock.contentX - hDelta));
                   }
                   event.accepted = true;
                 }
      }

      ScrollBar.horizontal: ScrollBar {
        visible: !DockHelpers.getProperty(root.dockRoot, "isVertical") && dock.interactive
        policy: ScrollBar.AsNeeded
      }
      ScrollBar.vertical: ScrollBar {
        visible: DockHelpers.getProperty(root.dockRoot, "isVertical") && dock.interactive
        policy: ScrollBar.AsNeeded
      }

      function getAppIcon(appData: var): string {
        if (!appData || !DockHelpers.getProperty(appData, "appId"))
          return "";
        return ThemeIcons.iconForAppId(DockHelpers.lowerCaseAppId(appData), undefined);
      }

      function getPrimaryToplevel(appData: var): var {
        const toplevels = DockHelpers.getValidToplevels(appData, ToplevelManager);
        if (toplevels.length === 0)
          return null;
        if (ToplevelManager && ToplevelManager.activeToplevel && toplevels.includes(ToplevelManager.activeToplevel))
          return ToplevelManager.activeToplevel;
        return toplevels[0];
      }

      function launchAppById(appId: string): void {
        if (!appId)
          return;

        const app = ThemeIcons.findAppEntry(appId);
        if (!app) {
          Logger.w("Dock", `Could not find desktop entry for pinned app: ${appId}`);
          return;
        }

        if (Settings.data.appLauncher.customLaunchPrefixEnabled && Settings.data.appLauncher.customLaunchPrefix.trim() !== "") {
          const prefix = Settings.data.appLauncher.customLaunchPrefix.trim().split(" ");

          if (DockHelpers.getProperty(app, "runInTerminal") && Settings.data.appLauncher.terminalCommand.trim() !== "") {
            const terminal = Settings.data.appLauncher.terminalCommand.trim().split(" ");
            const command = prefix.concat(terminal.concat(DockHelpers.getProperty(app, "command")));
            Quickshell.execDetached(command);
          } else {
            const command = prefix.concat(DockHelpers.getProperty(app, "command"));
            Quickshell.execDetached(command);
          }
        } else {
          if (DockHelpers.getProperty(app, "runInTerminal") && Settings.data.appLauncher.terminalCommand.trim() !== "") {
            Logger.d("Dock", "Executing terminal app manually: " + DockHelpers.getProperty(app, "name"));
            const terminal = Settings.data.appLauncher.terminalCommand.trim().split(" ");
            const command = terminal.concat(DockHelpers.getProperty(app, "command"));
            CompositorService.spawn(command);
          } else if (DockHelpers.getProperty(app, "command") && DockHelpers.getProperty(DockHelpers.getProperty(app, "command"), "length") > 0) {
            CompositorService.spawn(DockHelpers.getProperty(app, "command"));
          } else if (DockHelpers.getProperty(app, "execute")) {
            app.execute();
          } else {
            Logger.w("Dock", `Could not launch: ${DockHelpers.getProperty(app, "name")}. No valid launch method.`);
          }
        }
      }

      // Use GridLayout for flexible horizontal/vertical arrangement
      GridLayout {
        id: dockLayout
        columns: DockHelpers.getProperty(root.dockRoot, "isVertical") ? 1 : -1
        rows: DockHelpers.getProperty(root.dockRoot, "isVertical") ? -1 : 1
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        // Ensure the layout takes its full implicit size
        width: implicitWidth
        height: implicitHeight

        Component {
          id: launcherButtonComponent

          Item {
            id: launcherButton
            anchors.fill: parent
            readonly property string screenName: DockHelpers.getProperty(root.dockRoot, "modelData") ? DockHelpers.getProperty(root.dockRoot, "modelData").name : (DockHelpers.getProperty(root.dockRoot, "screen") ? DockHelpers.getProperty(root.dockRoot, "screen").name : "")
            readonly property var launcherWidgetSettings: {
              const widgetsBySection = screenName ? Settings.getBarWidgetsForScreen(screenName) : Settings.data.bar.widgets;
              if (!widgetsBySection)
                return {};
              const sections = ["left", "center", "right"];
              for (let i = 0; i < sections.length; i++) {
                const sectionWidgets = widgetsBySection[sections[i]] || [];
                for (let j = 0; j < sectionWidgets.length; j++) {
                  const widget = sectionWidgets[j];
                  if (widget && widget.id === "Launcher")
                    return widget;
                }
              }
              return {};
            }
            readonly property string launcherWidgetSection: {
              const widgetsBySection = screenName ? Settings.getBarWidgetsForScreen(screenName) : Settings.data.bar.widgets;
              if (!widgetsBySection)
                return "";
              const sections = ["left", "center", "right"];
              for (let i = 0; i < sections.length; i++) {
                const sectionWidgets = widgetsBySection[sections[i]] || [];
                for (let j = 0; j < sectionWidgets.length; j++) {
                  const widget = sectionWidgets[j];
                  if (widget && widget.id === "Launcher")
                    return sections[i];
                }
              }
              return "";
            }
            readonly property int launcherWidgetIndex: {
              const widgetsBySection = screenName ? Settings.getBarWidgetsForScreen(screenName) : Settings.data.bar.widgets;
              if (!widgetsBySection)
                return -1;
              const sections = ["left", "center", "right"];
              for (let i = 0; i < sections.length; i++) {
                const sectionWidgets = widgetsBySection[sections[i]] || [];
                for (let j = 0; j < sectionWidgets.length; j++) {
                  const widget = sectionWidgets[j];
                  if (widget && widget.id === "Launcher")
                    return j;
                }
              }
              return -1;
            }
            readonly property var launcherMetadata: DockHelpers.getProperty(BarWidgetRegistry.widgetMetadata, "Launcher")
            readonly property string launcherIcon: {
              if (Settings.data.dock.launcherIcon !== undefined && Settings.data.dock.launcherIcon !== "")
                return Settings.data.dock.launcherIcon;
              if (DockHelpers.getProperty(launcherWidgetSettings, "icon") !== undefined && DockHelpers.getProperty(launcherWidgetSettings, "icon") !== "")
                return DockHelpers.getProperty(launcherWidgetSettings, "icon");
              return (launcherMetadata && DockHelpers.getProperty(launcherMetadata, "icon")) ? DockHelpers.getProperty(launcherMetadata, "icon") : "search";
            }
            readonly property string launcherIconColorKey: {
              if (Settings.data.dock.launcherIconColor !== undefined)
                return Settings.data.dock.launcherIconColor;
              if (DockHelpers.getProperty(launcherWidgetSettings, "iconColor") !== undefined)
                return DockHelpers.getProperty(launcherWidgetSettings, "iconColor");
              if (launcherMetadata && DockHelpers.getProperty(launcherMetadata, "iconColor") !== undefined)
                return DockHelpers.getProperty(launcherMetadata, "iconColor");
              return "none";
            }
            // No distro logo on Windows (HostService.osLogo is empty).
            readonly property bool launcherUseDistroLogo: false

            Item {
              id: launcherIconContainer
              width: DockHelpers.getProperty(root.dockRoot, "iconSize")
              height: DockHelpers.getProperty(root.dockRoot, "iconSize")
              anchors.centerIn: parent

              scale: launcherMouseArea.containsMouse ? 1.15 : 1.0
              Behavior on scale {
                NumberAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.OutBack
                  easing.overshoot: 1.2
                }
              }

              NIcon {
                anchors.centerIn: parent
                icon: launcherButton.launcherIcon
                pointSize: DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.7
                color: Color.resolveColorKey(launcherButton.launcherIconColorKey)
                visible: !launcherButton.launcherUseDistroLogo
              }

              IconImage {
                anchors.centerIn: parent
                width: DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.8
                height: width
                source: launcherButton.launcherUseDistroLogo ? HostService.osLogo : ""
                visible: source !== ""
                smooth: true
                asynchronous: true
                layer.enabled: visible
                layer.effect: ShaderEffect {
                  property color targetColor: Color.resolveColorKey(launcherButton.launcherIconColorKey)
                  property real colorizeMode: 2.0

                  fragmentShader: Qt.resolvedUrl(ShellUrl.dir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                }
              }
            }

            MouseArea {
              id: launcherMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

              onEntered: {
                DockHelpers.setProperty(root.dockRoot, "anyAppHovered", true);
                if (DockHelpers.getProperty(root.dockRoot, "autoHide")) {
                  DockHelpers.timerAction(root.dockRoot, "showTimer", "stop");
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  DockHelpers.timerAction(root.dockRoot, "unloadTimer", "stop");
                  DockHelpers.setProperty(root.dockRoot, "hidden", false);
                }
              }

              onExited: {
                DockHelpers.setProperty(root.dockRoot, "anyAppHovered", false);
                if (DockHelpers.getProperty(root.dockRoot, "autoHide") && !DockHelpers.getProperty(root.dockRoot, "dockHovered") && !DockHelpers.getProperty(root.dockRoot, "peekHovered") && !DockHelpers.getProperty(root.dockRoot, "menuHovered") && DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === -1) {
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "restart");
                }
              }

              onClicked: mouse => {
                           const targetScreen = DockHelpers.getProperty(root.dockRoot, "modelData") || DockHelpers.getProperty(root.dockRoot, "screen") || null;
                           if (!targetScreen) {
                             return;
                           }

                           if (mouse.button === Qt.RightButton) {
                             if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === launcherContextMenu && launcherContextMenu.visible) {
                               root.dockRoot.closeAllContextMenus();
                               return;
                             }
                             root.dockRoot.closeAllContextMenus();
                             launcherContextMenu.show(launcherButton, null, targetScreen);
                             return;
                           }

                           if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                             root.dockRoot.closeAllContextMenus();
                             PanelService.toggleLauncher(targetScreen);
                           }
                         }
            }

            DockMenu {
              id: launcherContextMenu
              dockPosition: DockHelpers.getProperty(root.dockRoot, "dockPosition")
              menuMode: "launcher"
              launcherWidgetSection: launcherButton.launcherWidgetSection
              launcherWidgetIndex: launcherButton.launcherWidgetIndex
              launcherWidgetSettings: launcherButton.launcherWidgetSettings

              onHoveredChanged: {
                if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === launcherContextMenu && launcherContextMenu.visible) {
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", hovered);
                } else {
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                }
              }

              Connections {
                target: launcherContextMenu
                function onRequestClose() {
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", null);
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  launcherContextMenu.hide();
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                  DockHelpers.setProperty(root.dockRoot, "anyAppHovered", false);
                }
              }

              onVisibleChanged: {
                if (visible) {
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", launcherContextMenu);
                } else if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === launcherContextMenu) {
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", null);
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                  if (DockHelpers.getProperty(root.dockRoot, "autoHide") && !DockHelpers.getProperty(root.dockRoot, "dockHovered") && !DockHelpers.getProperty(root.dockRoot, "anyAppHovered") && !DockHelpers.getProperty(root.dockRoot, "peekHovered") && !DockHelpers.getProperty(root.dockRoot, "menuHovered")) {
                    DockHelpers.timerAction(root.dockRoot, "hideTimer", "restart");
                  }
                }
              }
            }
          }
        }

        Loader {
          id: launcherButtonStart
          active: Settings.data.dock.showLauncherIcon && Settings.data.dock.launcherPosition === "start"
          visible: active
          sourceComponent: launcherButtonComponent
          readonly property real indicatorMargin: Math.max(3, Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.18))
          Layout.preferredWidth: active ? (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2 : DockHelpers.getProperty(root.dockRoot, "iconSize")) : 0
          Layout.preferredHeight: active ? (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") : DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2) : 0
          Layout.minimumWidth: active ? Layout.preferredWidth : 0
          Layout.minimumHeight: active ? Layout.preferredHeight : 0
          Layout.maximumWidth: active ? Layout.preferredWidth : 0
          Layout.maximumHeight: active ? Layout.preferredHeight : 0
          Layout.alignment: Qt.AlignCenter
        }

        Repeater {
          model: DockHelpers.getProperty(root.dockRoot, "dockApps")

          delegate: Item {
            required property var modelData
            required property int index
            id: appButton
            readonly property real indicatorMargin: Math.max(3, Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.18))
            Layout.preferredWidth: DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2 : DockHelpers.getProperty(root.dockRoot, "iconSize")
            Layout.preferredHeight: DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") : DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2
            Layout.alignment: Qt.AlignCenter

            property var toplevels: DockHelpers.getValidToplevels(appButton.modelData, ToplevelManager)
            property bool isActive: ToplevelManager && ToplevelManager.activeToplevel && toplevels.includes(ToplevelManager.activeToplevel)
            property bool hovered: appMouseArea.containsMouse
            property string appId: appButton.modelData ? DockHelpers.getProperty(appButton.modelData, "appId") : ""
            property int groupedCount: DockHelpers.getProperty(toplevels, "length")
            property int focusedWindowIndex: {
              if (!ToplevelManager || !ToplevelManager.activeToplevel)
                return -1;
              return toplevels.indexOf(ToplevelManager.activeToplevel);
            }
            property string groupedIndicatorText: focusedWindowIndex >= 0 ? (focusedWindowIndex + 1) + "/" + groupedCount : groupedCount.toString()
            property string appTitle: {
              if (!appButton.modelData)
                return "";
              const primaryToplevel = dock.getPrimaryToplevel(appButton.modelData);
              if (primaryToplevel) {
                const toplevelTitle = DockHelpers.getProperty(primaryToplevel, "title") || "";
                // If title is "Loading..." or empty, use desktop entry name
                if (!toplevelTitle || toplevelTitle === "Loading..." || toplevelTitle.trim() === "") {
                  return root.dockRoot.getAppNameFromDesktopEntry(DockHelpers.getProperty(appButton.modelData, "appId")) || DockHelpers.getProperty(appButton.modelData, "appId");
                }
                return toplevelTitle;
              }
              // For pinned apps that aren't running, use the stored title
              return DockHelpers.getProperty(appButton.modelData, "title") || DockHelpers.getProperty(appButton.modelData, "appId") || "";
            }
            property bool isRunning: DockHelpers.getProperty(toplevels, "length") > 0
            readonly property bool baseIndicatorVisible: Settings.data.dock.inactiveIndicators ? isRunning : isActive
            // Grouped indicators should be visible whenever grouped windows are running, even if none is focused.
            readonly property bool showGroupedIndicator: Settings.data.dock.groupApps && groupedCount > 1 && isRunning

            // Store appButton.index for drag-and-drop
            property int modelIndex: appButton.index
            objectName: "dockAppButton"

            DropArea {
              anchors.fill: parent
              keys: ["dock-app"]
              onEntered: function (drag) {
                if (drag.source && DockHelpers.getProperty(drag.source, "objectName") === "dockAppButton") {
                  DockHelpers.setProperty(root.dockRoot, "dragTargetIndex", appButton.modelIndex);
                }
              }
              onExited: function () {
                if (DockHelpers.getProperty(root.dockRoot, "dragTargetIndex") === appButton.modelIndex) {
                  DockHelpers.setProperty(root.dockRoot, "dragTargetIndex", -1);
                }
              }
              onDropped: function (drop) {
                DockHelpers.setProperty(root.dockRoot, "dragSourceIndex", -1);
                DockHelpers.setProperty(root.dockRoot, "dragTargetIndex", -1);
                if (drop.source && DockHelpers.getProperty(drop.source, "objectName") === "dockAppButton" && drop.source !== appButton) {
                  root.dockRoot.reorderApps(DockHelpers.getProperty(drop.source, "modelIndex"), appButton.modelIndex);
                }
              }
            }

            // Listen for the toplevel being closed
            Connections {
              target: DockHelpers.getProperty(appButton.modelData, "toplevel")
              function onClosed() {
                Qt.callLater(DockHelpers.getProperty(root.dockRoot, "updateDockApps"));
              }
            }

            // Draggable container for the icon
            Item {
              id: iconContainer
              width: DockHelpers.getProperty(root.dockRoot, "iconSize")
              height: DockHelpers.getProperty(root.dockRoot, "iconSize")

              // When dragging, remove anchors so MouseArea can position it
              anchors.centerIn: dragging ? undefined : parent

              property bool dragging: appMouseArea.drag.active
              onDraggingChanged: {
                if (dragging) {
                  DockHelpers.setProperty(root.dockRoot, "dragSourceIndex", appButton.index);
                } else {
                  // Reset if not handled by drop (e.g. dropped outside)
                  Qt.callLater(() => {
                                 if (!appMouseArea.drag.active && DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === appButton.index) {
                                   DockHelpers.setProperty(root.dockRoot, "dragSourceIndex", -1);
                                   DockHelpers.setProperty(root.dockRoot, "dragTargetIndex", -1);
                                 }
                               });
                }
              }

              Drag.active: dragging
              Drag.source: appButton
              Drag.hotSpot.x: width / 2
              Drag.hotSpot.y: height / 2
              Drag.keys: ["dock-app"]

              z: (DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === appButton.index) ? 1000 : ((dragging ? 1000 : 0))
              scale: dragging ? 1.1 : (appButton.hovered ? 1.15 : 1.0)
              Behavior on scale {
                NumberAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.OutBack
                  easing.overshoot: 1.2
                }
              }

              // Visual shifting logic
              readonly property bool isDragged: DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === appButton.index
              property real shiftOffset

              Binding on shiftOffset {
                value: {
                  if (DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") !== -1 && DockHelpers.getProperty(root.dockRoot, "dragTargetIndex") !== -1 && !iconContainer.isDragged) {
                    if (DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") < DockHelpers.getProperty(root.dockRoot, "dragTargetIndex")) {
                      // Dragging Forward: Items between source and target shift Backward
                      if (appButton.index > DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") && appButton.index <= DockHelpers.getProperty(root.dockRoot, "dragTargetIndex")) {
                        return -1 * (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") + Style.marginS : DockHelpers.getProperty(root.dockRoot, "iconSize") + Style.marginS);
                      }
                    } else if (DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") > DockHelpers.getProperty(root.dockRoot, "dragTargetIndex")) {
                      // Dragging Backward: Items between target and source shift Forward
                      if (appButton.index >= DockHelpers.getProperty(root.dockRoot, "dragTargetIndex") && appButton.index < DockHelpers.getProperty(root.dockRoot, "dragSourceIndex")) {
                        return (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") + Style.marginS : DockHelpers.getProperty(root.dockRoot, "iconSize") + Style.marginS);
                      }
                    }
                  }
                  return 0;
                }
              }

              transform: Translate {
                x: !DockHelpers.getProperty(root.dockRoot, "isVertical") ? iconContainer.shiftOffset : 0
                y: DockHelpers.getProperty(root.dockRoot, "isVertical") ? iconContainer.shiftOffset : 0

                Behavior on x {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutQuad
                  }
                }
                Behavior on y {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutQuad
                  }
                }
              }

              IconImage {
                id: appIcon
                anchors.fill: parent
                source: {
                  DockHelpers.getProperty(root.dockRoot, "iconRevision") >= 0 ? dock.getAppIcon(appButton.modelData) : ""; // Force re-evaluation when revision changes
                  return DockHelpers.getProperty(root.dockRoot, "iconRevision") >= 0 ? dock.getAppIcon(appButton.modelData) : "";
                }
                visible: source.toString() !== ""
                smooth: true
                asynchronous: true

                // Dim pinned apps that aren't running
                opacity: appButton.isRunning ? 1.0 : Settings.data.dock.deadOpacity

                // Apply dock-specific colorization shader only to non-focused apps
                layer.enabled: !appButton.isActive && Settings.data.dock.colorizeIcons
                layer.smooth: true
                layer.effect: ShaderEffect {
                  property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
                  property real colorizeMode: 0.0 // Dock mode (grayscale)

                  fragmentShader: Qt.resolvedUrl(ShellUrl.dir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                }

                Behavior on opacity {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutQuad
                  }
                }
              }

              // Fall back if no icon
              NIcon {
                anchors.centerIn: parent
                visible: !appIcon.visible
                icon: "question-mark"
                pointSize: DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.7
                color: appButton.isActive ? Color.mPrimary : Color.mOnSurfaceVariant
                opacity: appButton.isRunning ? 1.0 : 0.6

                Behavior on opacity {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutQuad
                  }
                }
              }
            }

            // Context menu popup
            DockMenu {
              id: contextMenu
              dockPosition: DockHelpers.getProperty(root.dockRoot, "dockPosition") // Pass dock position for menu placement
              onHoveredChanged: {
                // Only update menuHovered if this menu is current and visible
                if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === contextMenu && contextMenu.visible) {
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", hovered);
                } else {
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                }
              }

              Connections {
                target: contextMenu
                function onRequestClose() {
                  // Clear current menu immediately to prevent hover updates
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", null);
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  contextMenu.hide();
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                  DockHelpers.setProperty(root.dockRoot, "anyAppHovered", false);
                }
              }
              onAppClosed: DockHelpers.getProperty(root.dockRoot, "updateDockApps") // Force immediate dock update when app is closed
              onVisibleChanged: {
                if (visible) {
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", contextMenu);
                } else if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === contextMenu) {
                  DockHelpers.setProperty(root.dockRoot, "currentContextMenu", null);
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                  // Restart hide timer after menu closes
                  if (DockHelpers.getProperty(root.dockRoot, "autoHide") && !DockHelpers.getProperty(root.dockRoot, "dockHovered") && !DockHelpers.getProperty(root.dockRoot, "anyAppHovered") && !DockHelpers.getProperty(root.dockRoot, "peekHovered") && !DockHelpers.getProperty(root.dockRoot, "menuHovered")) {
                    DockHelpers.timerAction(root.dockRoot, "hideTimer", "restart");
                  }
                }
              }
            }

            MouseArea {
              id: appMouseArea
              objectName: "appMouseArea"
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

              // Only allow left-click dragging via axis control
              drag.target: iconContainer
              drag.axis: (pressedButtons & Qt.LeftButton) ? (DockHelpers.getProperty(root.dockRoot, "isVertical") ? Drag.YAxis : Drag.XAxis) : Drag.None

              onPressed: {
                var p1 = appButton.mapFromItem(dockContainer, 0, 0);
                var p2 = appButton.mapFromItem(dockContainer, dockContainer.width, dockContainer.height);
                drag.minimumX = p1.x;
                drag.maximumX = p2.x - iconContainer.width;
                drag.minimumY = p1.y;
                drag.maximumY = p2.y - iconContainer.height;
              }

              onReleased: {
                if (iconContainer.Drag.active) {
                  iconContainer.Drag.drop();
                }
              }

              onEntered: {
                DockHelpers.setProperty(root.dockRoot, "anyAppHovered", true);
                if (DockHelpers.getProperty(root.dockRoot, "autoHide")) {
                  DockHelpers.timerAction(root.dockRoot, "showTimer", "stop");
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "stop");
                  DockHelpers.timerAction(root.dockRoot, "unloadTimer", "stop"); // Cancel unload if hovering app
                  DockHelpers.setProperty(root.dockRoot, "hidden", false); // Make sure dock is visible
                }
              }

              onExited: {
                DockHelpers.setProperty(root.dockRoot, "anyAppHovered", false);
                // Clear menuHovered if no current menu or menu not visible
                if (!DockHelpers.getProperty(root.dockRoot, "currentContextMenu") || !DockHelpers.getProperty(root.dockRoot, "currentContextMenu").visible) {
                  DockHelpers.setProperty(root.dockRoot, "menuHovered", false);
                }
                if (DockHelpers.getProperty(root.dockRoot, "autoHide") && !DockHelpers.getProperty(root.dockRoot, "dockHovered") && !DockHelpers.getProperty(root.dockRoot, "peekHovered") && !DockHelpers.getProperty(root.dockRoot, "menuHovered") && DockHelpers.getProperty(root.dockRoot, "dragSourceIndex") === -1) {
                  DockHelpers.timerAction(root.dockRoot, "hideTimer", "restart");
                }
              }

              onClicked: mouse => {
                           if (mouse.button === Qt.RightButton) {
                             const targetScreen = DockHelpers.getProperty(root.dockRoot, "modelData") || DockHelpers.getProperty(root.dockRoot, "screen") || null;
                             // If right-clicking on the same app with an open context menu, close it
                             if (DockHelpers.getProperty(root.dockRoot, "currentContextMenu") === contextMenu && contextMenu.visible) {
                               root.dockRoot.closeAllContextMenus();
                               return;
                             }
                             // Close any other existing context menu first
                             root.dockRoot.closeAllContextMenus();
                             contextMenu.show(appButton, appButton.modelData, targetScreen);
                             return;
                           }

                           // Close any existing context menu for non-right-click actions
                           root.dockRoot.closeAllContextMenus();

                           const runningToplevels = DockHelpers.getValidToplevels(appButton.modelData, ToplevelManager);
                           const primaryToplevel = dock.getPrimaryToplevel(appButton.modelData);

                           if (mouse.button === Qt.MiddleButton) {
                             if (primaryToplevel && DockHelpers.getProperty(primaryToplevel, "close")) {
                               primaryToplevel.close();
                               Qt.callLater(DockHelpers.getProperty(root.dockRoot, "updateDockApps"));
                             }
                           } else if (mouse.button === Qt.LeftButton) {
                             if (runningToplevels.length === 0) {
                               dock.launchAppById(DockHelpers.getProperty(appButton.modelData, "appId"));
                               return;
                             }

                             if (!Settings.data.dock.groupApps || runningToplevels.length <= 1) {
                               if (primaryToplevel && DockHelpers.getProperty(primaryToplevel, "activate")) {
                                 primaryToplevel.activate();
                               }
                               return;
                             }

                             const clickAction = Settings.data.dock.groupClickAction || "cycle";
                             if (clickAction === "list") {
                               const targetScreen = DockHelpers.getProperty(root.dockRoot, "modelData") || DockHelpers.getProperty(root.dockRoot, "screen") || null;
                               // Left-click list should always open the grouped window list view.
                               contextMenu.show(appButton, appButton.modelData, targetScreen, "list");
                             } else {
                               const appKey = DockHelpers.getProperty(appButton.modelData, "appId") || "";
                               const state = DockHelpers.getProperty(root.dockRoot, "groupCycleIndices") || {};
                               const nextIndex = (state[appKey] || 0) % runningToplevels.length;
                               const nextToplevel = runningToplevels[nextIndex];
                               if (nextToplevel && nextToplevel.activate) {
                                 nextToplevel.activate();
                               }
                               state[appKey] = (nextIndex + 1) % runningToplevels.length;
                               DockHelpers.setProperty(root.dockRoot, "groupCycleIndices", Object.assign({}, state));
                             }
                           }
                         }
            }

            // Active indicator - positioned at the edge of the delegate area
            Rectangle {
              visible: appButton.baseIndicatorVisible && !appButton.showGroupedIndicator
              width: DockHelpers.getProperty(root.dockRoot, "isVertical") ? appButton.indicatorMargin * 0.6 : DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.2
              height: DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.2 : appButton.indicatorMargin * 0.6
              color: Color.mPrimary
              radius: Style.radiusXS

              // Anchor to the edge facing the screen center
              x: DockHelpers.getProperty(root.dockRoot, "dockPosition") === "left" ? 2 : (DockHelpers.getProperty(root.dockRoot, "dockPosition") === "right" ? parent.width - width - 2 : (parent.width - width) / 2)
              y: DockHelpers.getProperty(root.dockRoot, "dockPosition") === "top" ? 2 : (DockHelpers.getProperty(root.dockRoot, "dockPosition") === "bottom" ? parent.height - height - 2 : (parent.height - height) / 2)
            }

            Loader {
              id: groupedIndicatorLoader
              active: appButton.showGroupedIndicator
              x: DockHelpers.getProperty(root.dockRoot, "dockPosition") === "left" ? 1 : (DockHelpers.getProperty(root.dockRoot, "dockPosition") === "right" ? parent.width - width - 1 : (parent.width - width) / 2)
              y: DockHelpers.getProperty(root.dockRoot, "dockPosition") === "top" ? 1 : (DockHelpers.getProperty(root.dockRoot, "dockPosition") === "bottom" ? parent.height - height - 1 : (parent.height - height) / 2)

              sourceComponent: Settings.data.dock.groupIndicatorStyle === "dots" ? groupDotsIndicatorComponent : groupNumberIndicatorComponent
            }

            Component {
              id: groupNumberIndicatorComponent
              Rectangle {
                radius: Style.radiusS
                color: Qt.alpha(Color.mSurface, 0.9)
                border.color: Qt.alpha(Color.mOutline, 0.7)
                border.width: Style.borderS
                width: Math.max(14, numberLabel.implicitWidth + Style.marginXS)
                height: Math.max(10, numberLabel.implicitHeight + 2)

                NText {
                  id: numberLabel
                  anchors.centerIn: parent
                  text: appButton.groupedIndicatorText
                  pointSize: Style.fontSizeXS
                  color: appButton.focusedWindowIndex >= 0 ? Color.mPrimary : Color.mOnSurfaceVariant
                }
              }
            }

            Component {
              id: groupDotsIndicatorComponent
              Item {
                id: groupDots
                readonly property int maxVisibleDots: 5
                readonly property int totalCount: Math.max(0, appButton.groupedCount)
                readonly property int focusedIndex: appButton.focusedWindowIndex >= 0 ? appButton.focusedWindowIndex : 0
                readonly property int visibleCount: Math.min(totalCount, maxVisibleDots)
                readonly property int dotSize: Math.max(2, Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.1))
                readonly property int dotSpacing: Math.max(1, Math.round(dotSize * 0.7))
                readonly property int pitch: dotSize + dotSpacing
                readonly property int windowStart: {
                  if (totalCount <= maxVisibleDots)
                    return 0;
                  const centeredStart = focusedIndex - Math.floor(maxVisibleDots / 2);
                  const maxStart = totalCount - maxVisibleDots;
                  return Math.max(0, Math.min(maxStart, centeredStart));
                }
                readonly property bool hasHiddenLeft: windowStart > 0
                readonly property bool hasHiddenRight: (windowStart + visibleCount) < totalCount
                width: DockHelpers.getProperty(root.dockRoot, "isVertical") ? dotSize : (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing)
                height: DockHelpers.getProperty(root.dockRoot, "isVertical") ? (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing) : dotSize

                Repeater {
                  model: groupDots.visibleCount
                  delegate: Rectangle {
                    id: groupDot
                    required property int index
                    readonly property int absoluteIndex: groupDots.windowStart + groupDot.index
                    readonly property bool isFocusedDot: appButton.focusedWindowIndex >= 0 && absoluteIndex === appButton.focusedWindowIndex
                    readonly property bool isOverflowHint: (groupDot.index === 0 && groupDots.hasHiddenLeft) || (groupDot.index === groupDots.visibleCount - 1 && groupDots.hasHiddenRight)
                    width: isOverflowHint && !isFocusedDot ? Math.max(2, Math.round(groupDots.dotSize * 0.72)) : groupDots.dotSize
                    height: width
                    radius: width / 2
                    x: DockHelpers.getProperty(root.dockRoot, "isVertical") ? Math.round((groupDots.dotSize - width) / 2) : (groupDot.index * groupDots.pitch + Math.round((groupDots.dotSize - width) / 2))
                    y: DockHelpers.getProperty(root.dockRoot, "isVertical") ? (groupDot.index * groupDots.pitch + Math.round((groupDots.dotSize - width) / 2)) : Math.round((groupDots.dotSize - width) / 2)
                    color: isFocusedDot ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.9)
                    opacity: isOverflowHint && !isFocusedDot ? 0.55 : 1.0
                  }
                }
              }
            }
          }
        }

        Loader {
          id: launcherButtonEnd
          active: Settings.data.dock.showLauncherIcon && Settings.data.dock.launcherPosition === "end"
          visible: active
          sourceComponent: launcherButtonComponent
          readonly property real indicatorMargin: Math.max(3, Math.round(DockHelpers.getProperty(root.dockRoot, "iconSize") * 0.18))
          Layout.preferredWidth: active ? (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2 : DockHelpers.getProperty(root.dockRoot, "iconSize")) : 0
          Layout.preferredHeight: active ? (DockHelpers.getProperty(root.dockRoot, "isVertical") ? DockHelpers.getProperty(root.dockRoot, "iconSize") : DockHelpers.getProperty(root.dockRoot, "iconSize") + indicatorMargin * 2) : 0
          Layout.minimumWidth: active ? Layout.preferredWidth : 0
          Layout.minimumHeight: active ? Layout.preferredHeight : 0
          Layout.maximumWidth: active ? Layout.preferredWidth : 0
          Layout.maximumHeight: active ? Layout.preferredHeight : 0
          Layout.alignment: Qt.AlignCenter
        }
      }
    }
  }
}
