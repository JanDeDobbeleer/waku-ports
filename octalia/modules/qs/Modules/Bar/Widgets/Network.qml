import QtQuick 6.10
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings // For SettingsPanel
import qs.Services.Networking
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
  readonly property string displayMode: BarWidgetHelpers.readProperty(widgetSettings, "displayMode") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "displayMode") : BarWidgetHelpers.readProperty(widgetMetadata, "displayMode")
  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")
  readonly property string textColorKey: BarWidgetHelpers.readProperty(widgetSettings, "textColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textColor") : BarWidgetHelpers.readProperty(widgetMetadata, "textColor")

  implicitWidth: pill.width
  implicitHeight: pill.height

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": NetworkService.wifiEnabled ? I18n.tr("actions.disable-wifi") : I18n.tr("actions.enable-wifi"),
        "action": "toggle-wifi",
        "icon": NetworkService.wifiEnabled ? "wifi-off" : "wifi",
        "enabled": !NetworkService.airplaneModeEnabled && NetworkService.wifiAvailable
      },
      {
        "label": I18n.tr("common.wifi") + " " + I18n.tr("tooltips.open-settings"),
        "action": "wifi-settings",
        "icon": "settings"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "toggle-wifi") {
                     NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
                   } else if (action === "wifi-settings") {
                     SettingsPanelService.openToTab(SettingsPanel.Tab.Connections, 0, screen);
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  BarPill {
    id: pill
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: NetworkService.getIcon(undefined)
    text: NetworkService.getStatusText(false)
    autoHide: false
    forceOpen: !root.isBarVertical && root.displayMode === "alwaysShow"
    forceClose: root.isBarVertical || root.displayMode === "alwaysHide" || text === ""
    onClicked: {
      var panel = PanelService.getPanel("networkPanel", screen);
      PanelService.invokePanel(panel, "toggle", [this]);
    }
    onRightClicked: {
      PanelService.showContextMenu(contextMenu, pill, screen, null);
    }
  }
}
