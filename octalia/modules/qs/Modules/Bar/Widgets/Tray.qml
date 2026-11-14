pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import "../Extras/TrayMenuHelpers.js" as TrayMenuHelpers
import qs.compat

Item {
  id: root

  property ShellScreen screen

  // Trigger re-evaluation when window is registered
  property int popupMenuUpdateTrigger: 0

  // Get shared popup menu window from PanelService (reactive to trigger changes)
  readonly property var popupMenuWindow: {
    // Reference trigger to force re-evaluation
    var popupMenuUpdateTriggerRef = popupMenuUpdateTrigger;
    return PanelService.getPopupMenuWindow(screen);
  }

  readonly property var trayMenu: popupMenuWindow ? BarWidgetHelpers.readProperty(popupMenuWindow, "trayMenuLoader") : null

  Connections {
    target: PanelService
    function onPopupMenuWindowRegistered(registeredScreen: var): void {
      if (registeredScreen === root.screen) {
        root.popupMenuUpdateTrigger++;
      }
    }
  }

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property bool density: Settings.data.bar.density
  readonly property int iconSize: Style.toOdd(capsuleHeight * 0.65)

  property var blacklist: BarWidgetHelpers.readProperty(widgetSettings, "blacklist") || BarWidgetHelpers.readProperty(widgetMetadata, "blacklist") || [] // Read from settings
  property var pinned: BarWidgetHelpers.readProperty(widgetSettings, "pinned") || BarWidgetHelpers.readProperty(widgetMetadata, "pinned") || [] // Pinned items (shown inline)
  property bool drawerEnabled: BarWidgetHelpers.readProperty(widgetSettings, "drawerEnabled") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "drawerEnabled") : (BarWidgetHelpers.readProperty(widgetMetadata, "drawerEnabled") !== undefined ? BarWidgetHelpers.readProperty(widgetMetadata, "drawerEnabled") : true) // Enable drawer panel
  property bool hidePassive: BarWidgetHelpers.readProperty(widgetSettings, "hidePassive") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hidePassive") : true // Hide passive status items
  readonly property string chevronColorKey: BarWidgetHelpers.readProperty(widgetSettings, "chevronColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "chevronColor") : BarWidgetHelpers.readProperty(widgetMetadata, "chevronColor")
  readonly property color chevronColor: Color.resolveColorKey(chevronColorKey)
  property var filteredItems: [] // Items to show inline (pinned)
  property var dropdownItems: [] // Items to show in drawer (unpinned)
  property int hoveredItemIndex: -1 // Track hovered item for dot indicator

  Timer {
    id: updateDebounceTimer
    interval: 100 // milliseconds
    running: false
    repeat: false
    onTriggered: root._performFilteredItemsUpdate()
  }

  readonly property var statusSignature: {
    var i, item, s;
    if (!SystemTray.items || !SystemTray.items.values) {
      return "";
    }
    var sig = "";
    var items = SystemTray.items.values;
    for (i = 0; i < items.length; i++) {
      item = items[i];
      if (item) {
        // Direct property access creates reactive binding
        s = BarWidgetHelpers.readProperty(item, "status");
        sig += (BarWidgetHelpers.readProperty(item, "id") || i) + ":" + (s !== undefined ? s : -1);
      }
    }
    // Trigger update when signature changes (status changed)
    if (root.hidePassive) {
      Qt.callLater(root.updateFilteredItems);
    }
    return sig;
  }
  Repeater {
    id: statusConnectionsRepeater
    model: SystemTray.items && SystemTray.items.values ? SystemTray.items.values : []

    delegate: Item {
      id: statusItem
      required property var modelData
      Connections {
        target: statusItem.modelData
        enabled: statusItem.modelData !== null && statusItem.modelData !== undefined
        function onStatusChanged() {
          if (root.hidePassive) {
            root.updateFilteredItems();
          }
        }
      }
    }
  }

  function _performFilteredItemsUpdate() {
    var f, i, j, k, m, v, w;
    // Force a fresh read of settings to ensure we have the latest blacklist
    var currentSettings = {};
    if (section && sectionWidgetIndex >= 0 && screenName) {
      w = Settings.getBarWidgetsForScreen(screenName)[section];
      if (w && sectionWidgetIndex < w.length) {
        currentSettings = w[sectionWidgetIndex];
      }
    }

    // Update local properties with fresh data
    if (currentSettings.blacklist !== undefined)
      root.blacklist = currentSettings.blacklist;
    if (currentSettings.pinned !== undefined)
      root.pinned = currentSettings.pinned;

    let newItems = [];
    if (SystemTray.items && SystemTray.items.values) {
      const trayItems = SystemTray.items.values;
      for (i = 0; i < trayItems.length; i++) {
        const item = trayItems[i];
        if (!item) {
          continue;
        }

        const title = BarWidgetHelpers.readProperty(item, "tooltipTitle") || BarWidgetHelpers.readProperty(item, "name") || BarWidgetHelpers.readProperty(item, "id") || "";

        // Skip passive items if hidePassive is enabled
        if (root.hidePassive && BarWidgetHelpers.readProperty(item, "status") !== undefined && (BarWidgetHelpers.readProperty(item, "status") === Status.Passive || BarWidgetHelpers.readProperty(item, "status") === 0)) {
          continue;
        }

        // Check if blacklisted
        let isBlacklisted = false;
        if (root.blacklist && BarWidgetHelpers.readProperty(root.blacklist, "length") > 0) {
          for (j = 0; j < BarWidgetHelpers.readProperty(root.blacklist, "length"); j++) {
            const rule = root.blacklist[j];
            if (wildCardMatch(title, rule)) {
              isBlacklisted = true;
              break;
            }
          }
        }

        if (!isBlacklisted) {
          newItems.push(item);
        }
      }
    }

    // If drawer is disabled, show all items inline
    if (!root.drawerEnabled) {
      filteredItems = newItems;
      dropdownItems = [];
    } else {
      // Build inline (pinned) and drawer (unpinned) lists
      // If pinned list is empty, all items go to drawer (none inline)
      // If pinned list has items, pinned items are inline, rest go to drawer
      if (pinned && BarWidgetHelpers.readProperty(pinned, "length") > 0) {
        let pinnedItems = [];
        for (k = 0; k < newItems.length; k++) {
          const item2 = newItems[k];
          const title2 = BarWidgetHelpers.readProperty(item2, "tooltipTitle") || BarWidgetHelpers.readProperty(item2, "name") || BarWidgetHelpers.readProperty(item2, "id") || "";
          for (m = 0; m < BarWidgetHelpers.readProperty(pinned, "length"); m++) {
            const rule2 = pinned[m];
            if (wildCardMatch(title2, rule2)) {
              pinnedItems.push(item2);
              break;
            }
          }
        }
        filteredItems = pinnedItems;

        // Unpinned items go to drawer
        let unpinnedItems = [];
        for (v = 0; v < newItems.length; v++) {
          const cand = newItems[v];
          let isPinned = false;
          for (f = 0; f < BarWidgetHelpers.readProperty(filteredItems, "length"); f++) {
            if (filteredItems[f] === cand) {
              isPinned = true;
              break;
            }
          }
          if (!isPinned)
            unpinnedItems.push(cand);
        }
        dropdownItems = unpinnedItems;
      } else {
        // No pinned items: all items go to drawer (none inline)
        filteredItems = [];
        dropdownItems = newItems;
      }
    }
  }

  function updateFilteredItems() {
    updateDebounceTimer.restart();
  }

  function wildCardMatch(str: string, rule: string): bool {
    return BarWidgetHelpers.wildcardMatch(str, rule, Logger);
  }

  function toggleDrawer(button: var): void {
    // Close the popup menu if it's open
    if (popupMenuWindow && BarWidgetHelpers.readProperty(popupMenuWindow, "visible")) {
      popupMenuWindow.close();
    }

    const panel = PanelService.getPanel("trayDrawerPanel", root.screen);
    if (panel) {
      PanelService.setPanelProperties(panel, { "widgetSection": root.section, "widgetIndex": root.sectionWidgetIndex });
      PanelService.invokePanel(panel, "toggle", [this]);
    }
  }

  function onLoaded() {
    // When the widget is fully initialized with its props set the screen for the trayMenu
    if (trayMenu && BarWidgetHelpers.readProperty(trayMenu, "item")) {
      TrayMenuHelpers.setMenuScreen(BarWidgetHelpers.readProperty(trayMenu, "item"), screen);
    }
  }

  Connections {
    target: SystemTray.items
    function onValuesChanged() {
      root.updateFilteredItems();
      // Repeater will automatically update when items change
    }
  }

  Connections {
    target: Settings
    function onSettingsSaved() {
      root.updateFilteredItems();
    }
  }

  // Watch for hidePassive changes to update filtering immediately
  onHidePassiveChanged: {
    root.updateFilteredItems();
  }

  Component.onCompleted: {
    root.updateFilteredItems(); // Initial update
  }

  // Content dimensions for implicit sizing
  readonly property int visibleItemCount: (root.drawerEnabled && BarWidgetHelpers.readProperty(dropdownItems, "length") > 0 ? 1 : 0) + BarWidgetHelpers.readProperty(filteredItems, "length")
  readonly property real capsulePadding: 0
  readonly property real capsuleWidth: isVertical ? capsuleHeight : Math.round(trayFlow.implicitWidth + capsulePadding * 2)
  readonly property real capsuleContentHeight: isVertical ? Math.round(trayFlow.implicitHeight + capsulePadding * 2) : capsuleHeight

  implicitWidth: isVertical ? barHeight : Math.round(trayFlow.implicitWidth + capsulePadding * 2)
  implicitHeight: isVertical ? Math.round(trayFlow.implicitHeight + capsulePadding * 2) : barHeight
  visible: BarWidgetHelpers.readProperty(filteredItems, "length") > 0 || BarWidgetHelpers.readProperty(dropdownItems, "length") > 0
  opacity: (BarWidgetHelpers.readProperty(filteredItems, "length") > 0 || BarWidgetHelpers.readProperty(dropdownItems, "length") > 0) ? 1.0 : 0.0

  // Visual capsule centered in parent
  Rectangle {
    id: visualCapsule
    width: root.capsuleWidth
    height: root.capsuleContentHeight
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
  }

  NPopupContextMenu {
    id: chevronContextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   chevronContextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  Flow {
    id: trayFlow
    spacing: 0
    flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight

    // Position centered in capsule
    anchors.centerIn: visualCapsule

    // Drawer opener (before items if opposite direction)
    NIconButton {
      id: chevronIconBefore
      visible: root.drawerEnabled && BarWidgetHelpers.readProperty(root.dropdownItems, "length") > 0 && BarService.getPillDirection(root)
      width: root.isVertical ? root.barHeight : root.capsuleHeight
      height: root.isVertical ? root.capsuleHeight : root.barHeight
      baseSize: root.capsuleHeight
      applyUiScale: false
      customRadius: Style.radiusL
      colorBg: "transparent"
      colorFg: root.chevronColor
      colorBorder: "transparent"
      colorBorderHover: "transparent"
      icon: {
        switch (root.barPosition) {
        case "bottom":
          return "caret-up";
        case "left":
          return "caret-right";
        case "right":
          return "caret-left";
        case "top":
        default:
          return "caret-down";
        }
      }
      onClicked: root.toggleDrawer(this)
      onRightClicked: PanelService.showContextMenu(chevronContextMenu, this, root.screen, null)
    }

    // Pinned items
    Repeater {
      id: repeater
      model: root.filteredItems

      delegate: Item {
        id: trayDelegate
        required property var modelData
        required property int index
        width: root.isVertical ? root.barHeight : root.capsuleHeight
        height: root.isVertical ? root.capsuleHeight : root.barHeight
        visible: trayDelegate.modelData
        readonly property bool isHovered: root.hoveredItemIndex === trayDelegate.index

        // Anchor representing the visual area (for proper menu positioning)
        Item {
          id: visualAnchor
          width: root.capsuleHeight
          height: root.capsuleHeight
          x: Style.pixelAlignCenter(parent.width, width)
          y: Style.pixelAlignCenter(parent.height, height)
        }

        IconImage {
          id: trayIcon
          width: root.iconSize
          height: root.iconSize
          x: Style.pixelAlignCenter(parent.width, width)
          y: Style.pixelAlignCenter(parent.height, height)
          asynchronous: true
          backer.fillMode: Image.PreserveAspectFit

          source: {
            let icon = BarWidgetHelpers.optionalProperty(trayDelegate.modelData, "icon") || "";
            if (!icon) {
              return "";
            }

            // Process icon path
            if (icon.includes("?path=")) {
              const chunks = icon.split("?path=");
              const name = chunks[0];
              const path = chunks[1];
              const fileName = name.substring(name.lastIndexOf("/") + 1);
              return `file://${path}/${fileName}`;
            }
            return icon;
          }
          opacity: status === Image.Ready ? 1 : 0

          layer.enabled: BarWidgetHelpers.readProperty(root.widgetSettings, "colorizeIcons") !== false
          layer.effect: ShaderEffect {
            property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
            property real colorizeMode: 1.0

            fragmentShader: Qt.resolvedUrl(ShellUrl.dir + "/Shaders/qsb/appicon_colorize.frag.qsb")
          }
        }

        Rectangle {
          id: hoverIndicator
          anchors.bottom: trayIcon.bottom
          anchors.bottomMargin: -2
          anchors.horizontalCenter: trayIcon.horizontalCenter
          width: Style.toOdd(root.iconSize * 0.25)
          height: 4
          color: trayDelegate.isHovered ? Color.mHover : "transparent"
          radius: Math.min(Style.radiusXXS, width / 2)

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.OutCubic
            }
          }
        }

        MouseArea {
          id: itemMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onContainsMouseChanged: {
            if (containsMouse) {
              if (popupMenuWindow) {
                popupMenuWindow.close();
              }
              root.hoveredItemIndex = trayDelegate.index;
            } else if (root.hoveredItemIndex === trayDelegate.index) {
              root.hoveredItemIndex = -1;
            }
          }
          onClicked: mouse => {
                       if (!trayDelegate.modelData) {
                         return;
                       }

                       if (mouse.button === Qt.LeftButton) {
                         // Close any open menu first
                         if (popupMenuWindow) {
                           popupMenuWindow.close();
                         }

                         if (!trayDelegate.modelData.onlyMenu) {
                           trayDelegate.modelData.activate();
                         }
                       } else if (mouse.button === Qt.MiddleButton) {
                         // Close the menu if it was visible
                         if (popupMenuWindow && BarWidgetHelpers.readProperty(popupMenuWindow, "visible")) {
                           popupMenuWindow.close();
                           return;
                         }
                         trayDelegate.modelData.secondaryActivate && trayDelegate.modelData.secondaryActivate();
                       } else if (mouse.button === Qt.RightButton) {
                         // Close the menu if it was visible
                         if (popupMenuWindow && BarWidgetHelpers.readProperty(popupMenuWindow, "visible")) {
                           popupMenuWindow.close();
                           return;
                         }

                         // Close any opened panel
                         if ((PanelService.openedPanel !== null) && !PanelService.openedPanel.isClosing) {
                           PanelService.openedPanel.close();
                         }

                         if (trayDelegate.modelData.hasMenu && trayDelegate.modelData.menu && trayMenu && BarWidgetHelpers.readProperty(trayMenu, "item")) {
                           // Calculate menu position after ensuring menu is loaded
                           const calculateAndShow = () => {
                             // Position menu based on bar position, using visualAnchor for proper positioning
                             // Increased spacing for better alignment with other context menus
                             let menuX, menuY;
                             if (barPosition === "left") {
                               // For left bar: position menu to the right of the visual area
                               menuX = visualAnchor.width + Style.marginL;
                               menuY = 0;
                             } else if (barPosition === "right") {
                               // For right bar: position menu to the left of the visual area
                               menuX = -BarWidgetHelpers.readProperty(trayMenu, "item").implicitWidth - Style.marginL;
                               menuY = 0;
                             } else {
                               // For horizontal bars: center horizontally and position below visual area
                               menuX = (visualAnchor.width / 2) - (BarWidgetHelpers.readProperty(trayMenu, "item").implicitWidth / 2);
                               menuY = visualAnchor.height + Style.marginS;
                             }

                             PanelService.showTrayMenu(root.screen, trayDelegate.modelData, BarWidgetHelpers.readProperty(trayMenu, "item"), visualAnchor, menuX, menuY, root.section, root.sectionWidgetIndex);
                           };

                           // Use Qt.callLater to ensure menu dimensions are calculated
                           Qt.callLater(calculateAndShow);
                         } else {
                           Logger.d("Tray", "No menu available for", trayDelegate.modelData.id, "or trayMenu not set");
                         }
                       }
                     }
        }
      }
    }

    // Drawer opener (after items if normal direction)
    NIconButton {
      id: chevronIconAfter
      visible: root.drawerEnabled && BarWidgetHelpers.readProperty(dropdownItems, "length") > 0 && !BarService.getPillDirection(root)
      width: isVertical ? barHeight : capsuleHeight
      height: isVertical ? capsuleHeight : barHeight
      baseSize: capsuleHeight
      applyUiScale: false
      customRadius: Style.radiusL
      colorBg: "transparent"
      colorFg: root.chevronColor
      colorBorder: "transparent"
      colorBorderHover: "transparent"
      icon: {
        switch (barPosition) {
        case "bottom":
          return "caret-up";
        case "left":
          return "caret-right";
        case "right":
          return "caret-left";
        case "top":
        default:
          return "caret-down";
        }
      }
      onClicked: toggleDrawer(this)
      onRightClicked: PanelService.showContextMenu(chevronContextMenu, this, screen, null)
    }
  } // closes Flow
}
