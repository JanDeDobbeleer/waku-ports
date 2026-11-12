pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Services.System
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
  readonly property bool showUnreadBadge: BarWidgetHelpers.readProperty(widgetSettings, "showUnreadBadge") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showUnreadBadge") : BarWidgetHelpers.readProperty(widgetMetadata, "showUnreadBadge")
  readonly property bool hideWhenZero: BarWidgetHelpers.readProperty(widgetSettings, "hideWhenZero") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideWhenZero") : BarWidgetHelpers.readProperty(widgetMetadata, "hideWhenZero")
  readonly property bool hideWhenZeroUnread: BarWidgetHelpers.readProperty(widgetSettings, "hideWhenZeroUnread") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideWhenZeroUnread") : BarWidgetHelpers.readProperty(widgetMetadata, "hideWhenZeroUnread")
  readonly property string unreadBadgeColor: BarWidgetHelpers.readProperty(widgetSettings, "unreadBadgeColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "unreadBadgeColor") : BarWidgetHelpers.readProperty(widgetMetadata, "unreadBadgeColor")
  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")

  readonly property color badgeColor: Color.resolveColorKey(unreadBadgeColor)

  function computeUnreadCount(): int {
    return BarWidgetHelpers.unreadNotificationCount(NotificationService.historyModel, NotificationService.lastSeenTs);
  }

  readonly property int count: computeUnreadCount()

  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  customRadius: Style.radiusL
  icon: NotificationService.doNotDisturb ? "bell-off" : "bell"
  colorBg: Style.capsuleColor
  colorFg: Color.resolveColorKey(iconColorKey)
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth
  visible: !((hideWhenZero && BarWidgetHelpers.readProperty(NotificationService.historyModel, "count") === 0) || (hideWhenZeroUnread && count === 0))
  opacity: !((hideWhenZero && BarWidgetHelpers.readProperty(NotificationService.historyModel, "count") === 0) || (hideWhenZeroUnread && count === 0)) ? 1.0 : 0.0

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": NotificationService.doNotDisturb ? I18n.tr("actions.disable-dnd") : I18n.tr("actions.enable-dnd"),
        "action": "toggle-dnd",
        "icon": NotificationService.doNotDisturb ? "bell" : "bell-off"
      },
      {
        "label": I18n.tr("actions.clear-history"),
        "action": "clear-history",
        "icon": "trash"
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

                   if (action === "toggle-dnd") {
                     NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
                   } else if (action === "clear-history") {
                     NotificationService.clearHistory();
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  onClicked: {
    var panel = PanelService.getPanel("notificationHistoryPanel", screen);
    PanelService.invokePanel(panel, "toggle", [this]);
  }

  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen, null);
  }

  Loader {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.baseSize / 4
    anchors.verticalCenterOffset: -root.baseSize / 4
    z: 2
    active: root.showUnreadBadge
    sourceComponent: Rectangle {
      id: badge
      height: 7
      width: height
      radius: Style.radiusXS
      color: root.hovering ? Color.mOnHover : (root.badgeColor || Color.mError)
      border.color: Color.mSurface
      border.width: Style.borderS
      visible: root.count > 0
    }
  }
}
