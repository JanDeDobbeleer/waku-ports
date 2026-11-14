import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import qs.compat
import "../SettingsValue.js" as SettingsValue
import "DesktopWidgetSettingsDialog.js" as DesktopWidgetsData

Popup {
  id: root

  property int widgetIndex: -1
  property var widgetData: null
  property string widgetId: ""
  property string sectionId: "" // Not used for desktop widgets, but required by NSectionEditor
  property var screen: null
  property var settingsCache: ({})

  readonly property real maxHeight: (screen ? SettingsValue.read(screen, "height") : (parent ? parent.height : 800)) * 0.8

  signal updateWidgetSettings(string section, int index, var settings)

  width: Math.max(content.implicitWidth + padding * 2, 500)
  height: Math.min(content.implicitHeight + padding * 2, maxHeight)
  padding: Style.marginXL
  modal: true
  closePolicy: Popup.NoAutoClose
  dim: false

  // Center in parent
  x: Math.round((parent.width - width) / 2)
  y: Math.round((parent.height - height) / 2)

  onOpened: {
    if (widgetData && widgetId) {
      loadWidgetSettings();
    }
    forceActiveFocus();
  }

  background: Rectangle {
    id: bgRect
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Color.mPrimary
    border.width: Style.borderM
  }

  contentItem: FocusScope {
    id: focusScope
    focus: true

    ColumnLayout {
      id: content
      anchors.fill: parent
      spacing: Style.marginM

      RowLayout {
        id: titleRow
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight

        NText {
          text: I18n.trArgs("system.widget-settings-title", {
                          "widget": DesktopWidgetRegistry.getWidgetDisplayName(root.widgetId)
                        })
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "close"
          onClicked: root.saveAndClose()
        }
      }

      Rectangle {
        id: separator
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
      }

      // Scrollable settings area
      NScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        gradientColor: Color.mSurface

        ColumnLayout {
          width: scrollView.availableWidth
          spacing: Style.marginM

          Loader {
            id: settingsLoader
            Layout.fillWidth: true
            onLoaded: {
              if (item) {
                DesktopWidgetsData.focusFirstFocusable(item, focusScope);
              }
            }


          }
        }
      }
    }
  }

  // Mouse area for a draggable popup
  MouseArea {
    x: titleRow.x
    y: titleRow.y
    width: titleRow.width
    height: titleRow.height
    z: -1

    cursorShape: Qt.OpenHandCursor

    property real pressX: 0
    property real pressY: 0

    onPressed: mouse => {
                 pressX = mouse.x;
                 pressY = mouse.y;
                 cursorShape = Qt.ClosedHandCursor;
               }

    onReleased: {
      cursorShape = Qt.OpenHandCursor;
    }

    onPositionChanged: mouse => {
      var deltaX, deltaY;
                         if (pressed) {
                           deltaX = mouse.x - pressX;
                           deltaY = mouse.y - pressY;

                           root.x += deltaX;
                           root.y += deltaY;
                         }
                       }
  }

  Timer {
    id: saveTimer
    running: false
    interval: 150
    onTriggered: {
      root.updateWidgetSettings(root.sectionId, root.widgetIndex, root.settingsCache);
    }
  }

  Connections {
    target: settingsLoader.item
    ignoreUnknownSignals: true
    function onSettingsChanged(newSettings: var): void {
      if (newSettings) {
        root.settingsCache = newSettings;
        saveTimer.start();
      }
    }

    function onSettingsSaved(newSettings: var): void {
      if (newSettings) {
        root.updateWidgetSettings(root.sectionId, root.widgetIndex, newSettings);
      }
    }
  }

  function saveAndClose(): void {
    const newSettings = DesktopWidgetsData.saveSettings(settingsLoader.item);
    if (newSettings) {
      root.updateWidgetSettings(root.sectionId, root.widgetIndex, newSettings);
    }
    root.close();
  }

  function loadWidgetSettings(): void {
    DesktopWidgetsData.loadWidgetSettings(settingsLoader, DesktopWidgetRegistry, widgetData, Settings.data.desktopWidgets.monitorWidgets || [], sectionId, widgetIndex, widgetId, ShellUrl.dir);
  }

}
