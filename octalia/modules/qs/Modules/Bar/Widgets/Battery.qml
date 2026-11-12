import QtQuick 6.10
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Modules.Bar.Extras
import qs.Services.Hardware
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
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  readonly property string displayMode: BarWidgetHelpers.readProperty(widgetSettings, "displayMode") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "displayMode") : BarWidgetHelpers.readProperty(widgetMetadata, "displayMode")
  readonly property bool useGraphicMode: displayMode === "graphic" || displayMode === "graphic-clean"

  readonly property bool hideIfNotDetected: BarWidgetHelpers.readProperty(widgetSettings, "hideIfNotDetected") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideIfNotDetected") : BarWidgetHelpers.readProperty(widgetMetadata, "hideIfNotDetected")
  readonly property bool hideIfIdle: BarWidgetHelpers.readProperty(widgetSettings, "hideIfIdle") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideIfIdle") : BarWidgetHelpers.readProperty(widgetMetadata, "hideIfIdle")

  // Check if selected device is actually present/connected
  readonly property bool isReady: BatteryService.isDeviceReady(selectedDevice)
  readonly property bool isPresent: BatteryService.isDevicePresent(selectedDevice)
  readonly property real percent: isReady ? BatteryService.getPercentage(selectedDevice) : -1
  readonly property bool isCharging: isReady ? BatteryService.isCharging(selectedDevice) : false
  readonly property bool isPluggedIn: isReady ? BatteryService.isPluggedIn(selectedDevice) : false
  readonly property bool isLowBattery: isReady ? BatteryService.isLowBattery(selectedDevice) : false
  readonly property bool isCriticalBattery: isReady ? BatteryService.isCriticalBattery(selectedDevice) : false

  // Visibility: show if hideIfNotDetected is false, or if battery is ready
  readonly property bool shouldShow: !hideIfNotDetected || (isReady && (hideIfIdle ? !isPluggedIn : true))
  readonly property string deviceNativePath: BarWidgetHelpers.readProperty(widgetSettings, "deviceNativePath") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "deviceNativePath") : BarWidgetHelpers.readProperty(widgetMetadata, "deviceNativePath")
  readonly property var selectedDevice: BatteryService.isDevicePresent(BatteryService.findDevice(deviceNativePath)) ? BatteryService.findDevice(deviceNativePath) : null

  visible: shouldShow
  opacity: shouldShow ? 1.0 : 0.0

  implicitWidth: useGraphicMode ? capsule.width : pill.width
  implicitHeight: useGraphicMode ? capsule.height : pill.height

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  // ==================== GRAPHIC MODE ====================

  // Capsule background (graphic mode only)
  Rectangle {
    id: capsule
    visible: root.useGraphicMode
    anchors.centerIn: nBattery
    width: root.isBarVertical ? root.capsuleHeight : nBattery.width + Style.margin2S
    height: root.isBarVertical ? nBattery.height + Style.margin2S : root.capsuleHeight
    radius: Math.min(Style.radiusL, width / 2)
    color: graphicMouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  NBattery {
    id: nBattery
    visible: root.useGraphicMode
    anchors.centerIn: parent
    baseSize: (Style.getBarHeightForScreen(root.screenName) / root.capsuleHeight) * Style.fontSizeXXS
    showPercentageText: root.displayMode !== "graphic-clean"
    vertical: root.isBarVertical
    percentage: root.percent
    ready: root.isReady
    charging: root.isCharging
    pluggedIn: root.isPluggedIn
    low: root.isLowBattery
    critical: root.isCriticalBattery
    baseColor: graphicMouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    textColor: graphicMouseArea.containsMouse ? Color.mHover : Color.mSurface
  }

  MouseArea {
    id: graphicMouseArea
    visible: root.useGraphicMode
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
                 if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, nBattery, root.screen, null);
                 } else {
                   root.toggleBatteryPanel();
                 }
               }
  }

  // ==================== ICON MODE ====================

  BarPill {
    id: pill
    visible: !root.useGraphicMode
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    icon: BatteryService.getIcon(root.percent, root.isCharging, root.isPluggedIn, root.isReady)
    text: root.isReady ? root.percent : "-"
    suffix: "%"
    autoHide: false
    forceOpen: root.isReady && root.displayMode === "icon-always"
    forceClose: root.displayMode === "icon-only" || !root.isReady
    customBackgroundColor: root.isCharging ? Color.mPrimary : ((root.isLowBattery || root.isCriticalBattery) ? Color.mError : "transparent")
    customTextIconColor: root.isCharging ? Color.mOnPrimary : ((root.isLowBattery || root.isCriticalBattery) ? Color.mOnError : "transparent")
    onClicked: root.toggleBatteryPanel()
    onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen, null)
  }

  // ==================== SHARED ====================

  function getBatteryPanel(): var {
    var panel = PanelService.getPanel("batteryPanel", screen);
    if (panel) {
      BarWidgetHelpers.writeProperty(panel, "panelID", {
        showPowerProfiles: BarWidgetHelpers.readProperty(widgetSettings, "showPowerProfiles") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showPowerProfiles") : BarWidgetHelpers.readProperty(widgetMetadata, "showPowerProfiles"),
        showOctaliaPerformance: BarWidgetHelpers.readProperty(widgetSettings, "showOctaliaPerformance") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showOctaliaPerformance") : BarWidgetHelpers.readProperty(widgetMetadata, "showOctaliaPerformance")
      });
    }
    return panel;
  }

  function toggleBatteryPanel() {
    BarWidgetHelpers.toggleIfPresent(getBatteryPanel(), root);
  }
}
