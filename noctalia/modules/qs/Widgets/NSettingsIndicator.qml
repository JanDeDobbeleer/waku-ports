import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root

  property bool show: false

  implicitWidth: root.show ? 6 * Style.uiScaleRatio : 0
  implicitHeight: root.show ? 6 * Style.uiScaleRatio : 0
  width: root.show ? 6 * Style.uiScaleRatio : 0
  height: root.show ? 6 * Style.uiScaleRatio : 0
  radius: width / 2
  color: Color.mOnSurfaceVariant
  opacity: 0.6

  visible: root.show

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationFast
    }
  }
}
