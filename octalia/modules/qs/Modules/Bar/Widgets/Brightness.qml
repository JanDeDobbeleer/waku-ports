import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.Hardware
import qs.Services.UI
import qs.Widgets
import "../BarWidgetHelpers.js" as BarWidgetHelpers

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
  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")
  readonly property string textColorKey: BarWidgetHelpers.readProperty(widgetSettings, "textColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textColor") : BarWidgetHelpers.readProperty(widgetMetadata, "textColor")
  readonly property bool applyToAllMonitors: {
    const syncAllMonitors = BarWidgetHelpers.getProperty(Settings.data.brightness, "syncAllMonitors");
    return BarWidgetHelpers.readProperty(widgetSettings, "applyToAllMonitors") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "applyToAllMonitors") : (syncAllMonitors !== undefined ? syncAllMonitors : BarWidgetHelpers.readProperty(widgetMetadata, "applyToAllMonitors"));
  }
  readonly property bool reverseScroll: Settings.data.general.reverseScroll

  // Used to avoid opening the pill on Quickshell startup
  property bool firstBrightnessReceived: false

  implicitWidth: pill.width
  implicitHeight: pill.height

  // Track the brightness monitor reactively via declarative binding so it
  // updates atomically when monitors change, avoiding a transient undefined
  // state that occurs when Monitor QtObjects are destroyed before the
  // imperative updateMonitor() call would run.
  property var brightnessMonitor: {
    var _ = BrightnessService.monitors; // reactive dependency
    var __ = BrightnessService.ddcMonitors; // reactive dependency
    if (!screen)
      return null;
    return BrightnessService.getMonitorForScreen(screen) ?? null;
  }

  function getControllableMonitorCount(): int {
    return BarWidgetHelpers.countControllableMonitors(BrightnessService.monitors || []);
  }

  visible: brightnessMonitor !== null
  opacity: brightnessMonitor !== null ? 1.0 : 0.0

  function getIcon(): string {
    var monitor = brightnessMonitor;
    if (!monitor || !BarWidgetHelpers.readProperty(monitor, "brightnessControlAvailable") || isNaN(BarWidgetHelpers.readProperty(monitor, "brightness")))
      return "sun-off";
    var brightness = BarWidgetHelpers.readProperty(monitor, "brightness");
    if (brightness <= 0.001)
      return "sun-off";
    return brightness <= 0.5 ? "brightness-low" : "brightness-high";
  }

  // Connection used to open the pill when brightness changes
  Connections {
    target: root.brightnessMonitor
    ignoreUnknownSignals: true
    function onBrightnessUpdated() {
      // Ignore if this is the first time we receive an update.
      // Most likely service just kicked off.
      if (!root.firstBrightnessReceived) {
        root.firstBrightnessReceived = true;
        return;
      }

      pill.show();
      hideTimerAfterChange.restart();
    }
  }

  Timer {
    id: hideTimerAfterChange
    interval: 2500
    running: false
    repeat: false
    onTriggered: pill.hide()
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.open-display-settings"),
        "action": "open-display-settings",
        "icon": "sun"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      var settingsPanel;
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "open-display-settings") {
                     settingsPanel = PanelService.getPanel("settingsPanel", screen);
                     PanelService.openSettingsPanel(settingsPanel, SettingsPanel.Tab.Display);
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
    icon: root.getIcon()
    autoHide: false // Important to be false so we can hover as long as we want
    text: {
      var monitor = root.brightnessMonitor;
      if (!monitor || !BarWidgetHelpers.readProperty(monitor, "brightnessControlAvailable") || isNaN(BarWidgetHelpers.readProperty(monitor, "brightness")))
        return "";
      return Math.round(BarWidgetHelpers.readProperty(monitor, "brightness") * 100);
    }
    suffix: text.length > 0 ? "%" : "-"
    forceOpen: root.displayMode === "alwaysShow"
    forceClose: root.displayMode === "alwaysHide"

    onWheel: function (angle) {
      var monitor = root.brightnessMonitor;
      if (!monitor || !BarWidgetHelpers.readProperty(monitor, "brightnessControlAvailable"))
        return;

      if (root.reverseScroll)
        angle *= -1;

      if (angle === 0)
        return;

      var shouldApplyToAll = root.applyToAllMonitors && root.getControllableMonitorCount() > 1;
      if (angle > 0) {
        if (shouldApplyToAll) {
          BrightnessService.increaseBrightness();
        } else {
          monitor.increaseBrightness();
        }
      } else if (angle < 0) {
        if (shouldApplyToAll) {
          BrightnessService.decreaseBrightness();
        } else {
          monitor.decreaseBrightness();
        }
      }
    }

    onClicked: PanelService.invokePanel(PanelService.getPanel("brightnessPanel", screen), "toggle", [this])

    onRightClicked: {
      PanelService.showContextMenu(contextMenu, pill, screen, null);
    }
  }
}
