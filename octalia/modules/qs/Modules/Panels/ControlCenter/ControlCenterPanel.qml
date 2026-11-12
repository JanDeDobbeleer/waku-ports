pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen
import qs.Services.Media
import "./ControlCenterPanelUtils.js" as ControlCenterPanelUtils

SmartPanel {
  id: root

  // Positioning
  readonly property string controlCenterPosition: Settings.data.controlCenter.position

  // Check if there's a bar on this screen
  readonly property bool hasBarOnScreen: {
    var monitors = Settings.data.bar.monitors || [];
    return ControlCenterPanelUtils.hasBar(monitors, screen?.name);
  }

  // When position is "close_to_bar_button" but there's no bar, fall back to center
  readonly property bool shouldCenter: controlCenterPosition === "close_to_bar_button" && !hasBarOnScreen

  panelAnchorHorizontalCenter: shouldCenter || (controlCenterPosition !== "close_to_bar_button" && (controlCenterPosition.endsWith("_center") || controlCenterPosition === "center"))
  panelAnchorVerticalCenter: shouldCenter || controlCenterPosition === "center"
  panelAnchorLeft: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_left")
  panelAnchorRight: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_right")
  panelAnchorBottom: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("bottom_")
  panelAnchorTop: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("top_")

  preferredWidth: Math.round(440 * Style.uiScaleRatio)
  preferredHeight: ControlCenterPanelUtils.preferredHeight(Settings.data.controlCenter.cards, Settings.data.location.weatherEnabled, Style.marginL, {
    "profile-card": profileHeight,
    "shortcuts-card": shortcutsHeight,
    "audio-card": audioHeight,
    "brightness-card": brightnessHeight,
    "weather-card": weatherHeight,
    "media-sysmon-card": mediaSysMonHeight
  })

  readonly property int profileHeight: Math.round(64 * Style.uiScaleRatio)
  readonly property int shortcutsHeight: Math.round(52 * Style.uiScaleRatio)
  readonly property int audioHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int brightnessHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int mediaSysMonHeight: Math.round(260 * Style.uiScaleRatio)

  // We keep a dynamic weather height due to a more complex layout and font scaling
  property int weatherHeight: Math.round(210 * Style.uiScaleRatio)

  onOpened: {
    MediaService.autoSwitchingPaused = true;
  }

  onClosed: {
    MediaService.autoSwitchingPaused = false;
  }

  panelContent: Item {
    id: panelContent

    ColumnLayout {
      id: layout
      x: Style.marginL
      y: Style.marginL
      width: parent.width - Style.margin2L
      spacing: Style.marginL

      Repeater {
        model: ControlCenterPanelUtils.cardModels(Settings.data.controlCenter.cards, Settings.data.location.weatherEnabled, {
          "profile-card": { "height": root.profileHeight, "component": profileCard },
          "shortcuts-card": { "height": root.shortcutsHeight, "component": shortcutsCard },
          "audio-card": { "height": root.audioHeight, "component": audioCard },
          "brightness-card": { "height": root.brightnessHeight, "component": brightnessCard },
          "weather-card": { "height": root.weatherHeight, "component": weatherCard },
          "media-sysmon-card": { "height": root.mediaSysMonHeight, "component": mediaSysMonCard }
        })
        Loader {
          id: cardLoader
          required property var modelData
          active: ControlCenterPanelUtils.field(cardLoader.modelData, "active")
          visible: active
          Layout.fillWidth: true
          Layout.preferredHeight: ControlCenterPanelUtils.field(cardLoader.modelData, "height")
          sourceComponent: ControlCenterPanelUtils.field(cardLoader.modelData, "component")
        }
      }
    }

    Component {
      id: profileCard
      ProfileCard {}
    }

    Component {
      id: shortcutsCard
      ShortcutsCard {
        shortcutsHeight: root.shortcutsHeight
        screen: root.screen
      }
    }

    Component {
      id: audioCard
      AudioCard {}
    }

    Component {
      id: brightnessCard
      BrightnessCard {}
    }

    Component {
      id: weatherCard
      WeatherCard {
        Component.onCompleted: {
          root.weatherHeight = this.height;
        }
      }
    }

    Component {
      id: mediaSysMonCard
      RowLayout {
        spacing: Style.marginL

        // Media card
        MediaCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
        }

        // System monitors combined in one card
        SystemMonitorCard {
          Layout.preferredWidth: Math.round(Style.baseWidgetSize * 2.625)
          Layout.fillHeight: true
        }
      }
    }
  }
}
