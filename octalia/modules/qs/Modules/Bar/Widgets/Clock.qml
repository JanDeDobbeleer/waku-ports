pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
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
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property var now: Time.now

  // Resolve settings: try user settings or defaults from BarWidgetRegistry
  readonly property string clockColor: widgetSettings.clockColor !== undefined ? widgetSettings.clockColor : widgetMetadata.clockColor
  readonly property bool useCustomFont: widgetSettings.useCustomFont !== undefined ? widgetSettings.useCustomFont : widgetMetadata.useCustomFont
  readonly property string customFont: widgetSettings.customFont !== undefined ? widgetSettings.customFont : widgetMetadata.customFont
  readonly property string formatHorizontal: widgetSettings.formatHorizontal !== undefined ? widgetSettings.formatHorizontal : widgetMetadata.formatHorizontal
  readonly property string formatVertical: widgetSettings.formatVertical !== undefined ? widgetSettings.formatVertical : widgetMetadata.formatVertical

  readonly property color textColor: Color.resolveColorKey(clockColor)

  // Content dimensions for implicit sizing
  readonly property real contentWidth: isBarVertical ? capsuleHeight : Math.round((isBarVertical ? verticalLoader.implicitWidth : horizontalLoader.implicitWidth) + Style.margin2M)
  readonly property real contentHeight: isBarVertical ? Math.round(verticalLoader.implicitHeight + Style.margin2S) : capsuleHeight

  // Size: use implicit width/height
  // BarWidgetLoader sets explicit width/height to extend click area
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // Visual clock capsule - stays at content size, centered in parent
  Rectangle {
    id: visualClock
    width: root.contentWidth
    height: root.contentHeight
    anchors.centerIn: parent

    radius: Style.radiusL
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
      id: clockContainer
      anchors.centerIn: parent

      // Horizontal
      Loader {
        id: horizontalLoader
        active: !root.isBarVertical
        anchors.centerIn: parent
        sourceComponent: ColumnLayout {
          anchors.centerIn: parent
          spacing: Settings.data.bar.showCapsule ? -5 : -3
          Repeater {
            id: repeater
            model: I18n.locale.toString(root.now, root.formatHorizontal.trim()).split("\\n")
            NText {
              id: horizontalClockLine
              required property string modelData
              required property int index
              visible: text !== ""
              text: horizontalClockLine.modelData
              family: root.useCustomFont && root.customFont ? root.customFont : Settings.data.ui.fontDefault
              Binding on pointSize {
                value: {
                  if (repeater.model.length == 1) {
                    // Single line: Full size
                    return root.barFontSize;
                  } else if (repeater.model.length == 2) {
                    // Two lines: First line is bigger than the second
                    return (horizontalClockLine.index == 0) ? Math.round(root.barFontSize * 0.9) : Math.round(root.barFontSize * 0.75);
                  } else {
                    // More than two lines: Make it small!
                    return Math.round(root.barFontSize * 0.75);
                  }
                }
              }
              applyUiScale: false
              color: root.textColor
              wrapMode: Text.WordWrap
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              features: ({
                           "tnum": 1
                         })
            }
          }
        }
      }

      // Vertical
      Loader {
        id: verticalLoader
        active: root.isBarVertical
        anchors.centerIn: parent // Now this works without layout conflicts
        sourceComponent: ColumnLayout {
          anchors.centerIn: parent
          spacing: -2
          Repeater {
            model: I18n.locale.toString(root.now, root.formatVertical.trim()).split(" ")
            delegate: NText {
              id: verticalClockLine
              required property string modelData
              visible: text !== ""
              text: verticalClockLine.modelData
              family: root.useCustomFont && root.customFont ? root.customFont : Settings.data.ui.fontDefault
              pointSize: root.barFontSize
              applyUiScale: false
              color: root.textColor
              wrapMode: Text.WordWrap
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              features: ({
                           "tnum": 1
                         })
            }
          }
        }
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.open-calendar"),
        "action": "open-calendar",
        "icon": "calendar"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   // Close the context menu
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "open-calendar") {
                     PanelService.getPanel("clockPanel", screen)?.toggle(root);
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  MouseArea {
    id: clockMouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
                 if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, root, root.screen);
                 } else {
                   PanelService.getPanel("clockPanel", root.screen)?.toggle(this);
                 }
               }
  }
}
