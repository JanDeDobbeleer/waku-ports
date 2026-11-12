import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

NIconButton {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
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

  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor

  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: PowerProfileService.octaliaPerformanceMode ? Color.mPrimary : Style.capsuleColor
  colorFg: PowerProfileService.octaliaPerformanceMode ? Color.mOnPrimary : Color.resolveColorKey(iconColorKey)
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  icon: PowerProfileService.octaliaPerformanceMode ? "rocket" : "rocket-off"
  onClicked: PowerProfileService.toggleOctaliaPerformance()

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

  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }
}
