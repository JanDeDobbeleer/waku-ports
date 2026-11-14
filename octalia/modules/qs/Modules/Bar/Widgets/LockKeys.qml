import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

//test
Item {
  id: root

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Settings
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
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  // Content dimensions for implicit sizing
  readonly property real contentWidth: isVertical ? capsuleHeight : Math.round(layout.implicitWidth + Style.margin2M)
  readonly property real contentHeight: isVertical ? Math.round(layout.implicitHeight + Style.margin2M) : capsuleHeight

  readonly property bool hideWhenOff: (BarWidgetHelpers.readProperty(widgetSettings, "hideWhenOff") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "hideWhenOff") : (BarWidgetHelpers.readProperty(widgetMetadata, "hideWhenOff") !== undefined ? BarWidgetHelpers.readProperty(widgetMetadata, "hideWhenOff") : false)

  readonly property string capsIcon: BarWidgetHelpers.readProperty(widgetSettings, "capsLockIcon") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "capsLockIcon") : BarWidgetHelpers.readProperty(widgetMetadata, "capsLockIcon")
  readonly property string numIcon: BarWidgetHelpers.readProperty(widgetSettings, "numLockIcon") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "numLockIcon") : BarWidgetHelpers.readProperty(widgetMetadata, "numLockIcon")
  readonly property string scrollIcon: BarWidgetHelpers.readProperty(widgetSettings, "scrollLockIcon") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "scrollLockIcon") : BarWidgetHelpers.readProperty(widgetMetadata, "scrollLockIcon")
  readonly property bool showCaps: (BarWidgetHelpers.readProperty(widgetSettings, "showCapsLock") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "showCapsLock") : BarWidgetHelpers.readProperty(widgetMetadata, "showCapsLock")
  readonly property bool showNum: (BarWidgetHelpers.readProperty(widgetSettings, "showNumLock") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "showNumLock") : BarWidgetHelpers.readProperty(widgetMetadata, "showNumLock")
  readonly property bool showScroll: (BarWidgetHelpers.readProperty(widgetSettings, "showScrollLock") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "showScrollLock") : BarWidgetHelpers.readProperty(widgetMetadata, "showScrollLock")

  visible: !root.hideWhenOff || (root.showCaps && LockKeysService.capsLockOn) || (root.showNum && LockKeysService.numLockOn) || (root.showScroll && LockKeysService.scrollLockOn)

  Component.onCompleted: LockKeysService.registerComponent("bar-lockkeys:" + (screen?.name || "unknown"))
  Component.onDestruction: LockKeysService.unregisterComponent("bar-lockkeys:" + (screen?.name || "unknown"))

  implicitHeight: contentHeight
  implicitWidth: contentWidth

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

  // Visual capsule centered in parent
  Rectangle {
    id: visualCapsule
    anchors.centerIn: parent
    color: Style.capsuleColor
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusM
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
      id: layout

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight
      implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth

      RowLayout {
        id: rowLayout

        spacing: 0
        visible: !root.isVertical

        NIcon {
          color: LockKeysService.capsLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.capsIcon
          visible: root.showCaps && (!root.hideWhenOff || LockKeysService.capsLockOn)
        }

        NIcon {
          color: LockKeysService.numLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.numIcon
          visible: root.showNum && (!root.hideWhenOff || LockKeysService.numLockOn)
        }

        NIcon {
          color: LockKeysService.scrollLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.scrollIcon
          visible: root.showScroll && (!root.hideWhenOff || LockKeysService.scrollLockOn)
        }
      }

      ColumnLayout {
        id: colLayout

        spacing: 0
        visible: root.isVertical

        NIcon {
          color: LockKeysService.capsLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.capsIcon
          visible: root.showCaps && (!root.hideWhenOff || LockKeysService.capsLockOn)
        }

        NIcon {
          color: LockKeysService.numLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.numIcon
          visible: root.showNum && (!root.hideWhenOff || LockKeysService.numLockOn)
        }

        NIcon {
          color: LockKeysService.scrollLockOn ? Color.mTertiary : Qt.alpha(Color.mOnSurfaceVariant, 0.3)
          icon: root.scrollIcon
          visible: root.showScroll && (!root.hideWhenOff || LockKeysService.scrollLockOn)
        }
      }
    }
  }

  // MouseArea at root level for extended click area
  MouseArea {
    acceptedButtons: Qt.RightButton
    anchors.fill: parent

    onClicked: mouse => {
                 if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, root, root.screen, null);
                 }
               }
  }
}
