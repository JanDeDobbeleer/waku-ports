pragma ComponentBehavior: Bound

import QtQuick 6.10
import "../DesktopWidgetHelpers.js" as DesktopWidgetHelpers
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets

DraggableDesktopWidget {
  id: root

  readonly property var now: Time.now
  readonly property var widgetMetadata: DesktopWidgetHelpers.field(DesktopWidgetRegistry.widgetMetadata, "Clock")

  readonly property color clockTextColor: Color.resolveColorKey(clockColor)
  readonly property real fontSize: Math.round(Style.fontSizeXXXL * 2.5 * widgetScale)
  readonly property real widgetOpacity: DesktopWidgetHelpers.field(widgetData, "opacity") !== undefined ? DesktopWidgetHelpers.field(widgetData, "opacity") : 1.0
  readonly property string clockStyle: DesktopWidgetHelpers.field(widgetData, "clockStyle") !== undefined ? DesktopWidgetHelpers.field(widgetData, "clockStyle") : DesktopWidgetHelpers.field(widgetMetadata, "clockStyle")
  readonly property string clockColor: DesktopWidgetHelpers.field(widgetData, "clockColor") !== undefined ? DesktopWidgetHelpers.field(widgetData, "clockColor") : DesktopWidgetHelpers.field(widgetMetadata, "clockColor")
  readonly property bool useCustomFont: DesktopWidgetHelpers.field(widgetData, "useCustomFont") !== undefined ? DesktopWidgetHelpers.field(widgetData, "useCustomFont") : DesktopWidgetHelpers.field(widgetMetadata, "useCustomFont")
  readonly property string customFont: DesktopWidgetHelpers.field(widgetData, "customFont") !== undefined ? DesktopWidgetHelpers.field(widgetData, "customFont") : DesktopWidgetHelpers.field(widgetMetadata, "customFont")
  readonly property string format: DesktopWidgetHelpers.field(widgetData, "format") !== undefined ? DesktopWidgetHelpers.field(widgetData, "format") : DesktopWidgetHelpers.field(widgetMetadata, "format")

  readonly property Item clockContent: contentLoader.item as Item
  readonly property real contentPadding: Math.round((clockStyle === "minimal" ? Style.marginL : Style.marginXL) * widgetScale)
  implicitWidth: clockContent ? Math.round((DesktopWidgetHelpers.field(clockContent, "implicitWidth") || clockContent.width || 0) + contentPadding * 2) : 0
  implicitHeight: clockContent ? Math.round((DesktopWidgetHelpers.field(clockContent, "implicitHeight") || clockContent.height || 0) + contentPadding * 2) : 0
  width: implicitWidth
  height: implicitHeight

  Component {
    id: nclockComponent
    NClock {
      now: root.now
      clockStyle: root.clockStyle
      backgroundColor: "transparent"
      clockColor: root.clockTextColor
      progressColor: Color.mPrimary
      opacity: root.widgetOpacity
      height: Math.round(root.fontSize * 1.9)
      width: height
      hoursFontSize: root.fontSize * 0.6
      minutesFontSize: root.fontSize * 0.4
      scaleRatio: root.widgetScale
    }
  }

  Component {
    id: minimalClockComponent
    ColumnLayout {
      spacing: -2
      opacity: root.widgetOpacity

      Repeater {
        id: clockLines
        model: I18n.locale.toString(root.now, root.format.trim()).split("\\n")
        delegate: NText {
          id: clockLine
          required property string modelData
          required property int index
          visible: text !== ""
          text: clockLine.modelData
          family: root.useCustomFont && root.customFont ? root.customFont : Settings.data.ui.fontDefault
          pointSize: {
            if (clockLines.count == 1) {
              return Math.round(Style.fontSizeXXL * root.widgetScale);
            } else {
              return Math.round((clockLine.index == 0) ? Style.fontSizeXXL * root.widgetScale : Style.fontSizeM * root.widgetScale);
            }
          }
          font.weight: Style.fontWeightBold
          color: root.clockTextColor
          wrapMode: Text.WordWrap
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
  }

  Loader {
    id: contentLoader
    anchors.centerIn: parent
    z: 2
    sourceComponent: root.clockStyle === "minimal" ? minimalClockComponent : nclockComponent
  }
}
