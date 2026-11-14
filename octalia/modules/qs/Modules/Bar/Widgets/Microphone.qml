import QtQuick 6.10
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Modules.Bar.Extras
import qs.Services.Media
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
  readonly property string displayMode: (BarWidgetHelpers.readProperty(widgetSettings, "displayMode") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "displayMode") : BarWidgetHelpers.readProperty(widgetMetadata, "displayMode")
  readonly property string middleClickCommand: (BarWidgetHelpers.readProperty(widgetSettings, "middleClickCommand") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "middleClickCommand") : BarWidgetHelpers.readProperty(widgetMetadata, "middleClickCommand")
  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")
  readonly property string textColorKey: BarWidgetHelpers.readProperty(widgetSettings, "textColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textColor") : BarWidgetHelpers.readProperty(widgetMetadata, "textColor")

  // Used to avoid opening the pill on Quickshell startup
  property bool firstInputVolumeReceived: false
  property int wheelAccumulator: 0

  implicitWidth: pill.width
  implicitHeight: pill.height

  // Connection used to open the pill when input volume changes
  Connections {
    target: BarWidgetHelpers.optionalProperty(AudioService.source, "audio") ? BarWidgetHelpers.optionalProperty(AudioService.source, "audio") : null
    function onVolumeChanged() {
      // Logger.i("Bar:Microphone", "onInputVolumeChanged")
      if (!root.firstInputVolumeReceived) {
        // Ignore the first volume change
        root.firstInputVolumeReceived = true;
      } else {
        pill.show();
        externalHideTimer.restart();
      }
    }
  }

  // Connection used to open the pill when input mute state changes
  Connections {
    target: BarWidgetHelpers.optionalProperty(AudioService.source, "audio") ? BarWidgetHelpers.optionalProperty(AudioService.source, "audio") : null
    function onMutedChanged() {
      // Logger.i("Bar:Microphone", "onInputMutedChanged")
      if (!root.firstInputVolumeReceived) {
        // Ignore the first mute change
        root.firstInputVolumeReceived = true;
      } else {
        pill.show();
        externalHideTimer.restart();
      }
    }
  }

  Timer {
    id: externalHideTimer
    running: false
    interval: 1500
    onTriggered: {
      pill.hide();
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.toggle-mute"),
        "action": "toggle-mute",
        "icon": AudioService.inputMuted ? "microphone-off" : "microphone"
      },
      {
        "label": I18n.tr("actions.run-custom-command"),
        "action": "custom-command",
        "icon": "adjustments"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "toggle-mute") {
                     AudioService.setInputMuted(!AudioService.inputMuted);
                   } else if (action === "custom-command") {
                     Quickshell.execDetached(["cmd", "/c", root.middleClickCommand]);
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  BarPill {
    id: pill

    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: AudioService.getInputIcon()
    autoHide: false // Important to be false so we can hover as long as we want
    text: {
      const maxVolume = Settings.data.audio.volumeOverdrive ? 1.5 : 1.0;
      const displayVolume = Math.min(maxVolume, AudioService.inputVolume);
      return Math.round(displayVolume * 100);
    }
    suffix: "%"
    forceOpen: root.displayMode === "alwaysShow"
    forceClose: root.displayMode === "alwaysHide"

    onWheel: function (delta) {
      root.wheelAccumulator += delta;
      if (root.wheelAccumulator >= 120) {
        root.wheelAccumulator = 0;
        AudioService.setInputVolume(AudioService.inputVolume + AudioService.stepVolume);
      } else if (root.wheelAccumulator <= -120) {
        root.wheelAccumulator = 0;
        AudioService.setInputVolume(AudioService.inputVolume - AudioService.stepVolume);
      }
    }
    onClicked: {
      PanelService.invokePanel(PanelService.getPanel("audioPanel", screen), "toggle", [this]);
    }
    onRightClicked: {
      PanelService.showContextMenu(contextMenu, pill, screen, null);
    }
    onMiddleClicked: {
      Quickshell.execDetached(["cmd", "/c", root.middleClickCommand]);
    }
  }
}
