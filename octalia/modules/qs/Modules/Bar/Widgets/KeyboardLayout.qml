import QtQuick 6.10
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Modules.Bar.Extras
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

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
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"

  readonly property string displayMode: (BarWidgetHelpers.readProperty(widgetSettings, "displayMode") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "displayMode") : BarWidgetHelpers.readProperty(widgetMetadata, "displayMode")
  readonly property bool showIcon: (BarWidgetHelpers.readProperty(widgetSettings, "showIcon") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "showIcon") : BarWidgetHelpers.readProperty(widgetMetadata, "showIcon")
  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")
  readonly property string textColorKey: BarWidgetHelpers.readProperty(widgetSettings, "textColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textColor") : BarWidgetHelpers.readProperty(widgetMetadata, "textColor")

  // Use the shared service for keyboard layout
  property string currentLayout: KeyboardLayoutService.currentLayout

  implicitWidth: pill.width
  implicitHeight: pill.height

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  BarPill {
    id: pill
    anchors.verticalCenter: parent.verticalCenter
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: root.showIcon ? "keyboard" : ""
    autoHide: false // Important to be false so we can hover as long as we want
    text: root.isBarVertical ? root.currentLayout.substring(0, 3).toUpperCase() : root.currentLayout
    // When icon is disabled, always show the layout text
    forceOpen: !root.showIcon || root.displayMode === "forceOpen"
    forceClose: root.showIcon && root.displayMode === "alwaysHide"
    onRightClicked: {
      PanelService.showContextMenu(contextMenu, pill, screen, null);
    }
  }
}
