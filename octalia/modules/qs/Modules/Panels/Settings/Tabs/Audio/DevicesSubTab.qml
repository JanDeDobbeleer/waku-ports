import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Services.Media
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  // Output Devices
  ButtonGroup {
    id: sinks
  }

  ColumnLayout {
    spacing: Style.marginXS
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL

    NLabel {
      label: I18n.tr("panels.audio.devices-output-device-label")
      description: I18n.tr("panels.audio.devices-output-device-description")
    }

    Repeater {
      model: SettingsValue.attachButtonGroup(AudioService.sinks, sinks)
      NRadioButton {
        required property PwNode device
        required property var groupRef
        ButtonGroup.group: groupRef
        text: device.description
        checked: SettingsValue.audioNodeSelected(AudioService.sink, device)
        onClicked: {
          AudioService.setAudioSink(device);
        }
        Layout.fillWidth: true
      }
    }
  }

  // Input Devices
  ButtonGroup {
    id: sources
  }

  ColumnLayout {
    spacing: Style.marginXS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("panels.audio.devices-input-device-label")
      description: I18n.tr("panels.audio.devices-input-device-description")
    }

    Repeater {
      model: SettingsValue.attachButtonGroup(AudioService.sources, sources)
      NRadioButton {
        required property PwNode device
        required property var groupRef
        ButtonGroup.group: groupRef
        text: device.description
        checked: SettingsValue.audioNodeSelected(AudioService.source, device)
        onClicked: AudioService.setAudioSource(device)
        Layout.fillWidth: true
      }
    }
  }
}
