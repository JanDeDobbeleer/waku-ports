pragma ComponentBehavior: Bound

import "NColorChoiceUtils.js" as ColorChoiceUtils

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root

  property string label: I18n.tr("common.select-color")
  property string description: I18n.tr("common.select-color-description")
  property string currentKey: ""
  property var defaultValue: undefined
  property var noneColor: undefined      // color declared as var so we can nullify
  property var noneOnColor: undefined    // color declared as var so we can nullify

  readonly property bool isValueChanged: (defaultValue !== undefined) && (currentKey !== defaultValue)

  readonly property int diameter: Style.baseWidgetSize * 0.9 * Style.uiScaleRatio

  signal selected(string key)

  NLabel {
    label: root.label
    description: root.description
    showIndicator: root.isValueChanged
  }

  RowLayout {
    id: colourRow

    opacity: enabled ? 1.0 : 0.6
    Layout.minimumWidth: root.diameter * ColorChoiceUtils.length(Color.colorKeyModel)

    Repeater {
      model: Color.colorKeyModel

      Rectangle {
        required property var modelData
        id: colorCircle

        property bool isSelected: root.currentKey === ColorChoiceUtils.key(colorCircle.modelData)
        property bool isHovered: circleMouseArea.containsMouse

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.diameter
        implicitHeight: root.diameter
        radius: root.diameter * 0.5
        color: (ColorChoiceUtils.key(colorCircle.modelData) === "none" && root.noneColor !== undefined) ? root.noneColor : Color.resolveColorKey(ColorChoiceUtils.key(colorCircle.modelData))
        border.color: (isSelected || isHovered) ? Color.mOnSurface : Color.mOutline
        border.width: Style.borderM

        MouseArea {
          id: circleMouseArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.currentKey = ColorChoiceUtils.key(colorCircle.modelData);
            root.selected(ColorChoiceUtils.key(colorCircle.modelData));
          }
        }

        NIcon {
          anchors.centerIn: parent
          icon: "check"
          pointSize: Math.max(Style.fontSizeXS, colorCircle.width * 0.4)
          color: (ColorChoiceUtils.key(colorCircle.modelData) === "none" && root.noneOnColor !== undefined) ? root.noneOnColor : Color.resolveOnColorKey(ColorChoiceUtils.key(colorCircle.modelData))
          font.weight: Style.fontWeightBold
          visible: colorCircle.isSelected
        }

        Behavior on border.color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }
    }
  }
}
