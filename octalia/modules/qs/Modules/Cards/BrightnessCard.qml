import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Hardware
import qs.Widgets

// Brightness control card for the ControlCenter
NBox {
  id: root

  Layout.fillWidth: true
  clip: true

  // Get the primary monitor (first screen)
  readonly property var brightnessMonitor: {
    if (Quickshell.screens.length > 0) {
      return BrightnessService.getMonitorForScreen(Quickshell.screens[0]);
    }
    return null;
  }

  property real localBrightness: 0
  property bool localBrightnessChanging: false

  Component.onCompleted: {
    if (brightnessMonitor) {
      localBrightness = brightnessMonitor.brightness || 0;
    }
  }

  // Update local brightness when monitor changes
  Connections {
    target: BrightnessService
    function onMonitorBrightnessChanged(monitor, newBrightness) {
      if (monitor === root.brightnessMonitor && !root.localBrightnessChanging) {
        root.localBrightness = newBrightness;
      }
    }
  }

  // Update local brightness when monitor's brightness property changes
  Connections {
    target: root.brightnessMonitor
    ignoreUnknownSignals: true
    function onBrightnessUpdated() {
      if (root.brightnessMonitor && !root.localBrightnessChanging) {
        root.localBrightness = root.brightnessMonitor.brightness || 0;
      }
    }
  }

  // Timer to debounce brightness changes - only runs when user is changing slider
  Timer {
    id: debounceTimer
    interval: 100
    running: false
    repeat: false
    onTriggered: {
      if (root.brightnessMonitor && Math.abs(root.localBrightness - root.brightnessMonitor.brightness) > 0.009) {
        root.brightnessMonitor.setBrightness(root.localBrightness);
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginM

    // Brightness Section
    ColumnLayout {
      spacing: Style.marginXXS
      Layout.fillWidth: true
      Layout.preferredWidth: 0
      opacity: root.brightnessMonitor && root.brightnessMonitor.brightnessControlAvailable ? 1.0 : 0.5
      enabled: root.brightnessMonitor && root.brightnessMonitor.brightnessControlAvailable

      // Brightness Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NIconButton {
          icon: {
            if (!root.brightnessMonitor)
              return "brightness-low";
            const brightness = root.brightnessMonitor.brightness || 0;
            if (brightness <= 0.001)
              return "sun-off";
            return brightness <= 0.5 ? "brightness-low" : "brightness-high";
          }
          baseSize: Style.baseWidgetSize * 0.5
          colorFg: Color.mOnSurface
          colorBg: "transparent"
          colorBgHover: Color.mHover
          colorFgHover: Color.mOnHover
        }

        NText {
          text: root.brightnessMonitor ? I18n.tr("common.brightness") : "No display"
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideRight
          Layout.fillWidth: true
          Layout.preferredWidth: 0
        }

        NText {
          text: root.brightnessMonitor ? Math.round(root.localBrightness * 100) + "%" : "N/A"
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
          opacity: root.brightnessMonitor && root.brightnessMonitor.brightnessControlAvailable ? 1.0 : 0.5
        }
      }

      // Brightness Slider
      NSlider {
        id: brightnessSlider
        Layout.fillWidth: true
        from: 0
        to: 1
        value: root.localBrightness
        stepSize: 0.01
        heightRatio: 0.5
        onMoved: {
          root.localBrightness = value;
          debounceTimer.restart();
        }
        onPressedChanged: root.localBrightnessChanging = pressed

        // MouseArea to handle wheel events when hovering over the slider
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          propagateComposedEvents: true

          onWheel: wheel => {
                     if (brightnessSlider.enabled && root.brightnessMonitor && root.brightnessMonitor.brightnessControlAvailable) {
                       const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                       const step = Settings.data.brightness.brightnessStep / 100.0; // Convert percentage to 0-1 range
                       const increment = delta > 0 ? step : -step;
                       const newValue = Math.max(0, Math.min(1, root.localBrightness + increment));
                       root.localBrightness = newValue;
                       debounceTimer.restart();
                     }
                   }
        }
      }
    }
  }
}
