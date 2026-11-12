import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Panels.ControlCenter
import qs.Widgets
import "../Panels/ControlCenter/ControlCenterPanelUtils.js" as ControlCenterPanelUtils

RowLayout {
  id: root
  objectName: "shortcutsCardRoot"

  property int shortcutsHeight: 0
  property var screen

  Layout.fillWidth: true
  spacing: Style.marginL

  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: root.shortcutsHeight
    visible: Settings.data.controlCenter.shortcuts.left.length > 0

    RowLayout {
      id: leftContent
      anchors.fill: parent
      spacing: Style.marginS

      Item {
        Layout.fillWidth: true
      }

      Repeater {
        model: Settings.data.controlCenter.shortcuts.left
        delegate: ControlCenterWidgetLoader {
          required property var modelData
          required property int index

          Layout.fillWidth: false
          widgetId: (ControlCenterPanelUtils.field(modelData, "id") !== undefined ? ControlCenterPanelUtils.field(modelData, "id") : "")
          widgetScreen: ControlCenterPanelUtils.ancestorField(parent, "shortcutsCardRoot", "screen")
          widgetProps: {
            "widgetId": ControlCenterPanelUtils.field(modelData, "id"),
            "section": "quickSettings",
            "sectionWidgetIndex": index,
            "sectionWidgetsCount": Settings.data.controlCenter.shortcuts.left.length,
            "widgetSettings": modelData
          }
          Layout.alignment: Qt.AlignVCenter
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: root.shortcutsHeight
    visible: Settings.data.controlCenter.shortcuts.right.length > 0

    RowLayout {
      id: rightContent
      anchors.fill: parent
      spacing: Style.marginS

      Item {
        Layout.fillWidth: true
      }

      Repeater {
        model: Settings.data.controlCenter.shortcuts.right
        delegate: ControlCenterWidgetLoader {
          required property var modelData
          required property int index

          Layout.fillWidth: false
          widgetId: (ControlCenterPanelUtils.field(modelData, "id") !== undefined ? ControlCenterPanelUtils.field(modelData, "id") : "")
          widgetScreen: ControlCenterPanelUtils.ancestorField(parent, "shortcutsCardRoot", "screen")
          widgetProps: {
            "widgetId": ControlCenterPanelUtils.field(modelData, "id"),
            "section": "quickSettings",
            "sectionWidgetIndex": index,
            "sectionWidgetsCount": Settings.data.controlCenter.shortcuts.right.length,
            "widgetSettings": modelData
          }
          Layout.alignment: Qt.AlignVCenter
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }
}
