pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.UI
import qs.compat
import "./TrayDrawerUtils.js" as TrayDrawerUtils

// A compact grid panel listing all tray items, opened from the Tray widget
SmartPanel {
  id: root

  // Do not give exclusive focus to the TrayDrawer or it will prevent the dropdown menu to request it.
  exclusiveKeyboard: false

  // Widget info for menu functionality (set by Tray widget when opening)
  property int settingsVersion: 0
  property string widgetSection: ""
  property int widgetIndex: -1

  // Sizing properties must stay at root for preferredWidth/Height
  readonly property int maxColumns: 8
  readonly property real cellSize: Math.round(Style.capsuleHeight * 0.65)
  readonly property real outerPadding: Style.marginM
  readonly property real innerSpacing: Style.marginM

  // All tray items from SystemTray
  readonly property var trayValuesAll: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []

  // Filtered items - computed in panelContent where isPinned is available
  property var trayValues: []

  readonly property int itemCount: TrayDrawerUtils.arrayLength(trayValues)
  readonly property int columns: Math.max(1, Math.min(maxColumns, itemCount))
  readonly property int rows: Math.max(1, Math.ceil(itemCount / Math.max(1, columns)))

  preferredWidth: (columns * cellSize) + ((columns - 1) * innerSpacing) + (2 * outerPadding)
  preferredHeight: (rows * cellSize) + ((rows - 1) * innerSpacing) + (2 * outerPadding)

  // Auto-close drawer when all items are pinned (drawer becomes empty)
  onTrayValuesChanged: {
    if (visible && itemCount === 0) {
      close();
    }
  }

  // Force refresh panelContent settings when drawer opens
  onOpened: root.settingsVersion++

  panelContent: Item {
    id: panelContent

    readonly property var widgetSettings: {
      // Reference settingsVersion to force recalculation when it changes
      void (root.settingsVersion);
      if (root.widgetSection === "" || root.widgetIndex < 0)
        return {};
      var widgets = Settings.getBarWidgetsForScreen(root.screen?.name)[root.widgetSection];
      if (!widgets || root.widgetIndex >= widgets.length)
        return {};
      var settings = widgets[root.widgetIndex];
      if (!settings || settings.id !== "Tray")
        return {};
      return settings;
    }

    readonly property var pinnedList: TrayDrawerUtils.field(widgetSettings, "pinned") || []
    readonly property bool hidePassive: TrayDrawerUtils.fieldOrDefault(widgetSettings, "hidePassive", true)

    // Filter tray items - this runs in panelContent context where isPinned is available
    function updateFilteredItems() {
      var i, item;
      var filtered = [];
      for (i = 0; i < TrayDrawerUtils.arrayLength(root.trayValuesAll); i++) {
        item = root.trayValuesAll[i];
        if (!item)
          continue;

        // Filter out passive items if hidePassive is enabled
        if (hidePassive && TrayDrawerUtils.isPassive(TrayDrawerUtils.field(item, "status"), SystemTray)) {
          continue;
        }

        // Filter out pinned items
        if (TrayDrawerUtils.isPinned(item, pinnedList)) {
          continue;
        }

        filtered.push(item);
      }
      root.trayValues = filtered;
    }

    // Update filtered items when dependencies change
    Component.onCompleted: updateFilteredItems()
    onPinnedListChanged: updateFilteredItems()
    onHidePassiveChanged: updateFilteredItems()

    Connections {
      target: root
      function onTrayValuesAllChanged() {
        panelContent.updateFilteredItems();
      }
    }

    // Popup menu state (lazy-loaded with panelContent)
    property int popupMenuUpdateTrigger: 0

    readonly property var popupMenuWindow: {
      void (popupMenuUpdateTrigger);
      return PanelService.getPopupMenuWindow(root.screen);
    }

    readonly property var trayMenu: TrayDrawerUtils.trayMenuLoader(popupMenuWindow)

    // Dynamic content sizing
    property real contentPreferredWidth: (root.columns * root.cellSize) + ((root.columns - 1) * root.innerSpacing) + (2 * root.outerPadding)
    property real contentPreferredHeight: (root.rows * root.cellSize) + ((root.rows - 1) * root.innerSpacing) + (2 * root.outerPadding)

    // Connections (lazy-loaded with panelContent)
    Connections {
      target: Settings
      function onSettingsSaved(): void {
        root.settingsVersion++;
      }
    }

    Connections {
      target: PanelService
      function onPopupMenuWindowRegistered(registeredScreen: var): void {
        if (registeredScreen === root.screen) {
          panelContent.popupMenuUpdateTrigger++;
        }
      }
    }

    Grid {
      id: grid
      anchors.fill: parent
      anchors.margins: root.outerPadding
      spacing: root.innerSpacing
      columns: root.columns
      rowSpacing: root.innerSpacing
      columnSpacing: root.innerSpacing

      Repeater {
        id: repeater
        model: root.trayValues

        delegate: Item {
          id: trayEntry
          required property var modelData
          width: root.cellSize
          height: root.cellSize

          IconImage {
            id: trayIcon
            anchors.fill: parent
            asynchronous: true
            backer.fillMode: Image.PreserveAspectFit
            source: {
              return TrayDrawerUtils.iconSource(trayEntry.modelData);
            }

            layer.enabled: TrayDrawerUtils.fieldOrDefault(panelContent.widgetSettings, "colorizeIcons", true) !== false
            layer.effect: ShaderEffect {
              property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
              property real colorizeMode: 1.0
              fragmentShader: Qt.resolvedUrl(ShellUrl.dir + "/Shaders/qsb/appicon_colorize.frag.qsb")
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

              onClicked: mouse => {
                           if (!trayEntry.modelData)
                           return;
                           if (mouse.button === Qt.LeftButton) {
                             if (!TrayDrawerUtils.field(trayEntry.modelData, "onlyMenu"))
                               TrayDrawerUtils.activate(trayEntry.modelData);
                             TrayDrawerUtils.closeOpenedPanel(PanelService.openedPanel);
                           } else if (mouse.button === Qt.MiddleButton) {
                             TrayDrawerUtils.secondaryActivate(trayEntry.modelData);
                             TrayDrawerUtils.closeOpenedPanel(PanelService.openedPanel);
                           } else if (mouse.button === Qt.RightButton) {
                             if (TrayDrawerUtils.popupVisible(panelContent.popupMenuWindow)) {
                               TrayDrawerUtils.closePopup(panelContent.popupMenuWindow);
                               return;
                             }

                             if (TrayDrawerUtils.hasMenu(trayEntry.modelData) && panelContent.trayMenu) {
                               TrayDrawerUtils.showTrayMenu(PanelService, root.screen, trayEntry.modelData, panelContent.trayMenu, trayIcon, Settings.getBarPositionForScreen(root.screen?.name), Style.marginL, root.widgetSection, root.widgetIndex);
                             }
                           }
                         }

              onWheel: wheel => {
                         if (wheel.angleDelta.y > 0)
                           TrayDrawerUtils.scroll(trayEntry.modelData, true);
                         else if (wheel.angleDelta.y < 0)
                           TrayDrawerUtils.scroll(trayEntry.modelData, false);
                       }

              onEntered: {
                TrayDrawerUtils.closePopup(panelContent.popupMenuWindow)
              }
            }
          }
        }
      }
    }
  }
}
