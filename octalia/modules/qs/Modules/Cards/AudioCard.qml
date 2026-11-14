import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.Media
import qs.Widgets
import "AudioCardUtils.js" as AudioCardUtils

// Audio controls card: output and input volume controls
NBox {
  id: root

  property real localOutputVolume: 0
  property bool localOutputVolumeChanging: false
  property string lastSinkName: ""

  property real localInputVolume: 0
  property bool localInputVolumeChanging: false
  property string lastSourceName: ""

  readonly property bool outputVolumeGuard: outputVolumeSlider.sliderActive || localOutputVolumeChanging
  readonly property bool inputVolumeGuard: inputVolumeSlider.sliderActive || localInputVolumeChanging

  Component.onCompleted: {
    var vol = AudioService.volume;
    localOutputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
    var inputVol = AudioService.inputVolume;
    localInputVolume = (inputVol !== undefined && !isNaN(inputVol)) ? inputVol : 0;
    if (AudioService.sink) {
      lastSinkName = AudioCardUtils.field(AudioService.sink, "name");
    }
    if (AudioService.source) {
      lastSourceName = AudioCardUtils.field(AudioService.source, "name");
    }
  }

  // Reset local volume when device changes - use current device's volume
  Connections {
    target: AudioService
    function onSinkChanged() {
      var vol;
      if (AudioService.sink) {
        const newSinkName = AudioCardUtils.field(AudioService.sink, "name");
        if (newSinkName !== root.lastSinkName) {
          root.lastSinkName = newSinkName;
          // Immediately set local volume to current device's volume
          vol = AudioService.volume;
          root.localOutputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
        }
      } else {
        root.lastSinkName = "";
        root.localOutputVolume = 0;
      }
    }
  }

  Connections {
    target: AudioService
    function onSourceChanged() {
      var vol;
      if (AudioService.source) {
        const newSourceName = AudioCardUtils.field(AudioService.source, "name");
        if (newSourceName !== root.lastSourceName) {
          root.lastSourceName = newSourceName;
          // Immediately set local volume to current device's volume
          vol = AudioService.inputVolume;
          root.localInputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
        }
      } else {
        root.lastSourceName = "";
        root.localInputVolume = 0;
      }
    }
  }

  // Timer to debounce volume changes
  // Only sync if the device hasn't changed (check by comparing IDs)
  Timer {
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      // Only sync if sink hasn't changed
      if (AudioService.sink && AudioCardUtils.field(AudioService.sink, "name") === root.lastSinkName) {
        if (Math.abs(root.localOutputVolume - AudioService.volume) >= 0.01) {
          AudioService.setVolume(root.localOutputVolume);
        }
      }
      // Only sync if source hasn't changed
      if (AudioService.source && AudioCardUtils.field(AudioService.source, "name") === root.lastSourceName) {
        if (Math.abs(root.localInputVolume - AudioService.inputVolume) >= 0.01) {
          AudioService.setInputVolume(root.localInputVolume);
        }
      }
    }
  }

  Connections {
    target: AudioService
    function onVolumeChanged() {
      var vol;
      if (!root.outputVolumeGuard && !AudioService.isSettingOutputVolume && AudioService.sink && AudioCardUtils.field(AudioService.sink, "name") === root.lastSinkName) {
        vol = AudioService.volume;
        root.localOutputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
      }
    }
  }

  Connections {
    target: AudioService
    function onInputVolumeChanged() {
      var vol;
      if (!root.inputVolumeGuard && !AudioService.isSettingInputVolume && AudioService.source && AudioCardUtils.field(AudioService.source, "name") === root.lastSourceName) {
        vol = AudioService.inputVolume;
        root.localInputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
      }
    }
  }

  Connections {
    target: outputVolumeSlider
    function onSliderActiveChanged() {
      var vol;
      if (!outputVolumeSlider.sliderActive && AudioService.sink && AudioCardUtils.field(AudioService.sink, "name") === root.lastSinkName) {
        vol = AudioService.volume;
        root.localOutputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
      }
    }
  }

  Connections {
    target: inputVolumeSlider
    function onSliderActiveChanged() {
      var vol;
      if (!inputVolumeSlider.sliderActive && AudioService.source && AudioCardUtils.field(AudioService.source, "name") === root.lastSourceName) {
        vol = AudioService.inputVolume;
        root.localInputVolume = (vol !== undefined && !isNaN(vol)) ? vol : 0;
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginM

    // Output Volume Section
    ColumnLayout {
      spacing: Style.marginXXS
      Layout.fillWidth: true
      Layout.preferredWidth: 0
      opacity: AudioService.sink ? 1.0 : 0.5
      enabled: AudioService.sink

      // Output Volume Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NIconButton {
          icon: AudioService.muted ? "volume-off" : "volume-high"
          baseSize: Style.baseWidgetSize * 0.5
          colorFg: AudioService.muted ? Color.mError : Color.mOnSurface
          colorBg: "transparent"
          colorBgHover: Color.mHover
          colorFgHover: Color.mOnHover
          onClicked: AudioService.setOutputMuted(!AudioService.muted)
        }

        NText {
          text: AudioService.sink ? AudioCardUtils.field(AudioService.sink, "description") : "No output device"
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideRight
          Layout.fillWidth: true
          Layout.preferredWidth: 0
        }
      }

      // Output Volume Slider
      NSlider {
        id: outputVolumeSlider
        Layout.fillWidth: true
        from: 0
        to: Settings.data.audio.volumeOverdrive ? 1.5 : 1.0
        value: root.localOutputVolume
        stepSize: 0.01
        heightRatio: 0.5
        onMoved: root.localOutputVolume = value
        onPressedChanged: root.localOutputVolumeChanging = pressed

        // MouseArea to handle wheel events when hovering over the slider
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          propagateComposedEvents: true

          onWheel: wheel => {
                     if (outputVolumeSlider.enabled && AudioService.sink) {
                       const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                       const step = Settings.data.audio.volumeStep / 100.0; // Convert percentage to 0-1 range
                       const increment = delta > 0 ? step : -step;
                       const maxVolume = Settings.data.audio.volumeOverdrive ? 1.5 : 1.0;
                       const newValue = Math.max(0, Math.min(maxVolume, root.localOutputVolume + increment));
                       root.localOutputVolume = newValue;
                     }
                   }
        }
      }
    }

    // Input Volume Section
    ColumnLayout {
      spacing: Style.marginXXS
      Layout.fillWidth: true
      Layout.preferredWidth: 0
      opacity: AudioService.source ? 1.0 : 0.5
      enabled: AudioService.source

      // Input Volume Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NIconButton {
          icon: AudioService.inputMuted ? "microphone-off" : "microphone"
          baseSize: Style.baseWidgetSize * 0.5
          colorFg: AudioService.inputMuted ? Color.mError : Color.mOnSurface
          colorBg: "transparent"
          colorBgHover: Color.mHover
          colorFgHover: Color.mOnHover
          onClicked: AudioService.setInputMuted(!AudioService.inputMuted)
        }

        NText {
          text: AudioService.source ? AudioCardUtils.field(AudioService.source, "description") : "No input device"
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideRight
          Layout.fillWidth: true
          Layout.preferredWidth: 0
        }
      }

      // Input Volume Slider
      NSlider {
        id: inputVolumeSlider
        Layout.fillWidth: true
        from: 0
        to: Settings.data.audio.volumeOverdrive ? 1.5 : 1.0
        value: root.localInputVolume
        stepSize: 0.01
        heightRatio: 0.5
        onMoved: root.localInputVolume = value
        onPressedChanged: root.localInputVolumeChanging = pressed

        // MouseArea to handle wheel events when hovering over the slider
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          propagateComposedEvents: true

          onWheel: wheel => {
                     if (inputVolumeSlider.enabled && AudioService.source) {
                       const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                       const step = Settings.data.audio.volumeStep / 100.0; // Convert percentage to 0-1 range
                       const increment = delta > 0 ? step : -step;
                       const maxVolume = Settings.data.audio.volumeOverdrive ? 1.5 : 1.0;
                       const newValue = Math.max(0, Math.min(maxVolume, root.localInputVolume + increment));
                       root.localInputVolume = newValue;
                     }
                   }
        }
      }
    }
  }
}
