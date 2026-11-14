import "NColorPickerUtils.js" as ColorPickerUtils

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var screen
  property color selectedColor: "black"

  signal colorSelected(color color)

  Layout.margins: Style.borderS
  implicitWidth: 150
  implicitHeight: Math.round(Style.baseWidgetSize * 1.1)

  radius: Style.iRadiusM
  color: Color.mSurface
  border.color: Color.mOutline
  border.width: Style.borderS

  // Minimized Look
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      const component = Qt.createComponent("NColorPickerDialog.qml");
      ColorPickerUtils.openDialog(component, root, Overlay.overlay);
    }

    RowLayout {
      anchors.fill: parent
      anchors {
        leftMargin: Style.marginL
        rightMargin: Style.marginL
      }
      spacing: Style.marginS

      // Color preview circle
      Rectangle {
        Layout.preferredWidth: root.height * 0.6
        Layout.preferredHeight: root.height * 0.6
        radius: Math.min(Style.iRadiusL, Layout.preferredWidth / 2)
        color: root.selectedColor
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: root.selectedColor.toString().toUpperCase()
        family: Settings.data.ui.fontFixed
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }

      NIcon {
        icon: "color-picker"
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }
}
