import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Octalia
import qs.Services.UI
import qs.Widgets
import qs.compat

Popup {
  id: root

  property int widgetIndex: -1
  property var widgetData: null
  property string widgetId: ""
  property string sectionId: "" // Not used for desktop widgets, but required by NSectionEditor
  property var screen: null
  property var settingsCache: ({})

  readonly property real maxHeight: (screen ? screen.height : (parent ? parent.height : 800)) * 0.8

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
          text: I18n.tr("system.widget-settings-title", {
                          "widget": DesktopWidgetRegistry.getWidgetDisplayName(root.widgetId)
                        })
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "close"
          onClicked: saveAndClose()
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
                Qt.callLater(() => {
                               var firstInput = findFirstFocusable(item);
                               if (firstInput) {
                                 firstInput.forceActiveFocus();
                               } else {
                                 focusScope.forceActiveFocus();
                               }
                             });
              }
            }

            function findFirstFocusable(item) {
              var child, found, i;
              if (!item)
                return null;
              if (item.focus !== undefined && item.focus === true)
                return item;
              if (item.children) {
                for (i = 0; i < item.children.length; i++) {
                  child = item.children[i];
                  if (child && child.focus !== undefined && child.focus === true)
                    return child;
                  found = findFirstFocusable(child);
                  if (found)
                    return found;
                }
              }
              return null;
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
    function onSettingsChanged(newSettings) {
      if (newSettings) {
        root.settingsCache = newSettings;
        saveTimer.start();
      }
    }

    function onSettingsSaved(newSettings) {
      if (newSettings) {
        root.updateWidgetSettings(root.sectionId, root.widgetIndex, newSettings);
      }
    }
  }

  function saveAndClose() {
    var newSettings;
    if (settingsLoader.item && typeof settingsLoader.item.saveSettings === 'function') {
      newSettings = settingsLoader.item.saveSettings();
      if (newSettings) {
        root.updateWidgetSettings(root.sectionId, root.widgetIndex, newSettings);
      }
    }
    root.close();
  }

  function loadWidgetSettings() {
    var currentWidgetData, fullPath, i, monitorWidgets, widgets;
    // Handle core widgets
    const source = DesktopWidgetRegistry.widgetSettingsMap[widgetId];
    if (source) {
      currentWidgetData = widgetData;
      monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
      for (i = 0; i < monitorWidgets.length; i++) {
        if (monitorWidgets[i].name === sectionId) {
          widgets = monitorWidgets[i].widgets || [];
          if (widgetIndex >= 0 && widgetIndex < widgets.length) {
            currentWidgetData = widgets[widgetIndex];
          }
          break;
        }
      }
      fullPath = Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/DesktopWidgets/" + source);
      settingsLoader.setSource(fullPath, {
                                 "widgetData": currentWidgetData,
                                 "widgetMetadata": DesktopWidgetRegistry.widgetMetadata[widgetId]
                               });
    }
  }
}
