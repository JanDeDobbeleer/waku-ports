import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property string value: ""

  signal editClicked

  spacing: Style.marginM

  NLabel {
    label: root.label
    description: root.description
    labelColor: root.value ? Color.mPrimary : Color.mOnSurface
  }

  NIconButton {
    icon: "settings"
    onClicked: root.editClicked()
  }
}
