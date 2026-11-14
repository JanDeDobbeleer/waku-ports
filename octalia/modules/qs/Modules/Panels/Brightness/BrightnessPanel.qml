pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Compositor
import qs.Services.Hardware
import qs.Services.UI
import qs.Widgets
import "./BrightnessPanelUtils.js" as BrightnessPanelUtils

SmartPanel {
  id: root

  preferredWidth: Math.round(440 * Style.uiScaleRatio)
  preferredHeight: Math.round(420 * Style.uiScaleRatio)

  panelContent: Item {
    id: panelContent
    property real contentPreferredHeight: mainColumn.implicitHeight + Style.margin2L

    property var brightnessWidgetInstance: BarService.lookupWidget("Brightness", root.screen ? root.screen.name : null)
    readonly property var brightnessWidgetSettings: BrightnessPanelUtils.field(brightnessWidgetInstance, "widgetSettings")
    readonly property var brightnessWidgetMetadata: BrightnessPanelUtils.field(BarWidgetRegistry.widgetMetadata, "Brightness")

    function resolveWidgetSetting(key: string, defaultValue: var): var {
      return BrightnessPanelUtils.resolveWidgetSetting(brightnessWidgetSettings, brightnessWidgetMetadata, key, defaultValue);
    }

    Connections {
      target: BarService
      function onActiveWidgetsChanged() {
        panelContent.brightnessWidgetInstance = BarService.lookupWidget("Brightness", root.screen ? root.screen.name : null);
      }
    }

    property real globalBrightness: 0
    property bool globalBrightnessChanging: false
    property int globalBrightnessCapableMonitors: 0

    function getIcon(brightness: real): string {
      return brightness <= 0.5 ? "brightness-low" : "brightness-high";
    }

    function updateGlobalBrightness(): void {
      const state = BrightnessPanelUtils.globalBrightnessState(BrightnessService.monitors, panelContent.globalBrightnessChanging);
      panelContent.globalBrightnessCapableMonitors = state.count;
      if (state.update)
        panelContent.globalBrightness = state.value;
    }

    function applyGlobalBrightness(value: real): void {
      BrightnessPanelUtils.applyGlobalBrightness(BrightnessService.monitors, value);
    }

    Component.onCompleted: updateGlobalBrightness()

    Connections {
      target: BrightnessService
      function onMonitorBrightnessChanged(monitor: var, newBrightness: real): void {
        panelContent.updateGlobalBrightness();
      }
      function onMonitorsChanged() {
        panelContent.updateGlobalBrightness();
      }
      function onDdcMonitorsChanged() {
        panelContent.updateGlobalBrightness();
      }
    }

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // HEADER
      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "settings-display"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NText {
            text: I18n.tr("panels.display.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "close"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              root.close();
            }
          }
        }
      }

      NScrollView {
        id: brightnessScrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalPolicy: ScrollBar.AlwaysOff
        verticalPolicy: ScrollBar.AsNeeded
        contentWidth: availableWidth
        reserveScrollbarSpace: false
        gradientColor: Color.mSurface

        // AudioService Devices
        ColumnLayout {
          spacing: Style.marginM
          width: brightnessScrollView.availableWidth

          NBox {
            Layout.fillWidth: true
            visible: panelContent.globalBrightnessCapableMonitors > 1 && panelContent.resolveWidgetSetting("applyToAllMonitors", false)
            implicitHeight: globalBrightnessContent.implicitHeight + (Style.marginXL)

            ColumnLayout {
              id: globalBrightnessContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.marginM
              spacing: Style.marginS

              NLabel {
                label: I18n.tr("panels.display.monitors-global-brightness-label")
                description: I18n.tr("panels.display.monitors-global-brightness-description")
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                  icon: panelContent.getIcon(panelContent.globalBrightness)
                  pointSize: Style.fontSizeXL
                  color: Color.mOnSurface
                }

                NValueSlider {
                  id: globalBrightnessSlider
                  from: 0
                  to: 1
                  value: panelContent.globalBrightness
                  stepSize: 0.01
                  enabled: panelContent.globalBrightnessCapableMonitors > 0
                  onMoved: value => {
                             panelContent.globalBrightness = value;
                             panelContent.applyGlobalBrightness(value);
                           }
                  onPressedChanged: (pressed, value) => {
                                      panelContent.globalBrightnessChanging = pressed;
                                      panelContent.globalBrightness = value;
                                      panelContent.applyGlobalBrightness(value);
                                    }
                  Layout.fillWidth: true
                  text: ""
                }

                NText {
                  text: panelContent.globalBrightnessCapableMonitors > 0 ? Math.round(panelContent.globalBrightness * 100) + "%" : "N/A"
                  Layout.preferredWidth: 55
                  horizontalAlignment: Text.AlignRight
                  Layout.alignment: Qt.AlignVCenter
                }
              }
            }
          }

          Repeater {
            model: Quickshell.screens || []
            delegate: NBox {
              id: monitorControl
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: outputColumn.implicitHeight + Style.margin2M

              property var brightnessMonitor: BrightnessService.getMonitorForScreen(monitorControl.modelData)
              readonly property real compositorScale: {
                const info = CompositorService.displayScales[BrightnessPanelUtils.field(monitorControl.modelData, "name")];
                return BrightnessPanelUtils.field(info, "scale") || 1.0;
              }

              ColumnLayout {
                id: outputColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.marginM
                spacing: Style.marginS

                NLabel {
                  label: BrightnessPanelUtils.field(monitorControl.modelData, "name") || "Unknown"
                  labelColor: Color.mPrimary
                  description: {
                    I18n.trArgs("system.monitor-description", {
                              "model": BrightnessPanelUtils.field(monitorControl.modelData, "model"),
                              "width": BrightnessPanelUtils.field(monitorControl.modelData, "width") * monitorControl.compositorScale,
                              "height": BrightnessPanelUtils.field(monitorControl.modelData, "height") * monitorControl.compositorScale,
                              "scale": monitorControl.compositorScale
                            });
                  }
                }

                RowLayout {

                  Layout.fillWidth: true
                  spacing: Style.marginS
                  NIcon {
                    icon: panelContent.getIcon(BrightnessPanelUtils.brightness(monitorControl.brightnessMonitor, 0))
                    pointSize: Style.fontSizeXL
                    color: Color.mOnSurface
                  }

                  NValueSlider {
                    id: brightnessSlider
                    from: 0
                    to: 1
                    value: BrightnessPanelUtils.brightness(monitorControl.brightnessMonitor, 0.5)
                    stepSize: 0.01
                    enabled: BrightnessPanelUtils.controlAvailable(monitorControl.brightnessMonitor)
                    onMoved: value => {
                               if (BrightnessPanelUtils.controlAvailable(monitorControl.brightnessMonitor)) {
                                 BrightnessPanelUtils.setBrightness(monitorControl.brightnessMonitor, value);
                               }
                             }
                    onPressedChanged: (pressed, value) => {
                                        if (BrightnessPanelUtils.controlAvailable(monitorControl.brightnessMonitor)) {
                                          BrightnessPanelUtils.setBrightness(monitorControl.brightnessMonitor, value);
                                        }
                                      }
                    Layout.fillWidth: true
                    text: monitorControl.brightnessMonitor ? Math.round(brightnessSlider.value * 100) + "%" : "N/A"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
