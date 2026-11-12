pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Services.Hardware
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  ColumnLayout {
    spacing: Style.marginL

    Repeater {
      model: Quickshell.screens || []
      delegate: NBox {
        id: monitorSettings
        required property ShellScreen modelData
        Layout.fillWidth: true
        implicitHeight: Math.round(contentCol.implicitHeight + Style.margin2L)
        color: Color.mSurface

        property var brightnessMonitor: BrightnessService.getMonitorForScreen(monitorSettings.modelData)
        property real localBrightness: 0.5
        property bool localBrightnessChanging: false
        readonly property string automaticOptionLabel: {
          var baseLabel = I18n.tr("panels.display.monitors-backlight-device-auto-option");
          var autoDevicePath = (BrightnessService.availableBacklightDevices && BrightnessService.availableBacklightDevices.length > 0) ? BrightnessService.availableBacklightDevices[0] : "";
          if (autoDevicePath === "")
            return baseLabel;

          var autoDeviceName = BrightnessService.getBacklightDeviceName(autoDevicePath) || autoDevicePath;
          return baseLabel + "(" + autoDeviceName + ")";
        }
        readonly property var backlightDeviceOptions: {
          var deviceName, devicePath, i;
          var options = [
                {
                  "key": "",
                  "name": automaticOptionLabel
                }
              ];

          var devices = BrightnessService.availableBacklightDevices || [];
          for (i = 0; i < devices.length; i++) {
            devicePath = devices[i];
            deviceName = BrightnessService.getBacklightDeviceName(devicePath) || devicePath;
            options.push({
                           "key": devicePath,
                           "name": deviceName
                         });
          }
          return options;
        }

        onBrightnessMonitorChanged: {
          if (brightnessMonitor && !localBrightnessChanging)
            localBrightness = brightnessMonitor.brightness || 0.5;
        }

        Connections {
          target: BrightnessService
          function onMonitorBrightnessChanged(monitor, newBrightness) {
            if (monitor === brightnessMonitor && !localBrightnessChanging) {
              localBrightness = newBrightness;
            }
          }
        }
        Connections {
          target: brightnessMonitor
          ignoreUnknownSignals: true
          function onBrightnessUpdated() {
            if (brightnessMonitor && !localBrightnessChanging) {
              localBrightness = brightnessMonitor.brightness || 0;
            }
          }
        }
        Timer {
          id: debounceTimer
          interval: 120
          repeat: false
          onTriggered: {
            if (brightnessMonitor && brightnessMonitor.brightnessControlAvailable && Math.abs(localBrightness - brightnessMonitor.brightness) >= 0.005) {
              brightnessMonitor.setBrightness(localBrightness);
            }
          }
        }

        ColumnLayout {
          id: contentCol
          width: parent.width - Style.margin2L
          x: Style.marginL
          y: Style.marginL
          spacing: Style.marginXXS

          RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom

            NText {
              text: monitorSettings.modelData.name || "Unknown"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightSemiBold
              Layout.alignment: Qt.AlignBottom
            }

            NText {
              Layout.fillWidth: true
              readonly property real compositorScale: {
                const info = CompositorService.displayScales[monitorSettings.modelData.name];
                return (info && info.scale) ? info.scale : 1.0;
              }
              text: {
                I18n.tr("system.monitor-description", {
                          "model": monitorSettings.modelData.model,
                          "width": monitorSettings.modelData.width * compositorScale,
                          "height": monitorSettings.modelData.height * compositorScale,
                          "scale": compositorScale
                        });
              }
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignRight
              Layout.alignment: Qt.AlignBottom
            }
          }

          ColumnLayout {
            spacing: Style.marginS
            Layout.fillWidth: true
            visible: brightnessMonitor !== undefined && brightnessMonitor !== null

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginL

              NText {
                text: I18n.tr("common.brightness")
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignVCenter
              }

              NValueSlider {
                id: brightnessSlider
                from: 0
                to: 1
                value: localBrightness
                stepSize: 0.01
                enabled: brightnessMonitor ? brightnessMonitor.brightnessControlAvailable : false
                onMoved: value => {
                           if (brightnessMonitor && brightnessMonitor.brightnessControlAvailable) {
                             localBrightness = value;
                             debounceTimer.restart();
                           }
                         }
                onPressedChanged: (pressed, value) => {
                                    localBrightnessChanging = pressed;
                                    if (brightnessMonitor && brightnessMonitor.brightnessControlAvailable) {
                                      if (pressed) {
                                        localBrightness = value;
                                        debounceTimer.restart();
                                      } else {
                                        localBrightness = value;
                                        debounceTimer.restart();
                                      }
                                    }
                                  }
                Layout.fillWidth: true
              }

              NText {
                text: brightnessMonitor ? Math.round(localBrightness * 100) + "%" : "N/A"
                Layout.preferredWidth: 55
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                opacity: brightnessMonitor && !brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
              }

              Item {
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                NIcon {
                  icon: brightnessMonitor && brightnessMonitor.method == "internal" ? "device-laptop" : "device-desktop"
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  opacity: brightnessMonitor && !brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
                }
              }
            }

            NText {
              visible: brightnessMonitor && !brightnessMonitor.brightnessControlAvailable && !(brightnessMonitor.method === "internal" && brightnessMonitor.initInProgress)
              text: I18n.tr("panels.display.monitors-brightness-unavailable-generic")
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }

            NComboBox {
              Layout.fillWidth: true
              visible: brightnessMonitor && brightnessMonitor.method === "internal"
              label: I18n.tr("panels.display.monitors-backlight-device-label")
              description: I18n.tr("panels.display.monitors-backlight-device-description")
              model: backlightDeviceOptions
              currentKey: BrightnessService.getMappedBacklightDevice(monitorSettings.modelData.name) || ""
              onSelected: key => BrightnessService.setMappedBacklightDevice(monitorSettings.modelData.name, key)
            }
          }
        }
      }
    }

    NSpinBox {
      Layout.fillWidth: true
      label: I18n.tr("panels.display.monitors-brightness-step-label")
      description: I18n.tr("panels.display.monitors-brightness-step-description")
      minimum: 1
      maximum: 50
      value: Settings.data.brightness.brightnessStep
      stepSize: 1
      suffix: "%"
      onValueChanged: Settings.data.brightness.brightnessStep = value
      defaultValue: Settings.getDefaultValue("brightness.brightnessStep")
    }

    NToggle {
      Layout.fillWidth: true
      label: I18n.tr("panels.display.monitors-enforce-minimum-label")
      description: I18n.tr("panels.display.monitors-enforce-minimum-description")
      checked: Settings.data.brightness.enforceMinimum
      onToggled: checked => Settings.data.brightness.enforceMinimum = checked
      defaultValue: Settings.getDefaultValue("brightness.enforceMinimum")
    }
  }
}
