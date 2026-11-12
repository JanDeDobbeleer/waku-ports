pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.System
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
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property bool compactMode: widgetSettings.compactMode !== undefined ? widgetSettings.compactMode : widgetMetadata.compactMode
  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor
  readonly property string textColorKey: widgetSettings.textColor !== undefined ? widgetSettings.textColor : widgetMetadata.textColor

  readonly property bool useMonospaceFont: widgetSettings.useMonospaceFont !== undefined ? widgetSettings.useMonospaceFont : widgetMetadata.useMonospaceFont
  readonly property bool usePadding: !compactMode && !isVertical && useMonospaceFont && ((widgetSettings.usePadding !== undefined) ? widgetSettings.usePadding : widgetMetadata.usePadding)

  readonly property bool showCpuUsage: (widgetSettings.showCpuUsage !== undefined) ? widgetSettings.showCpuUsage : widgetMetadata.showCpuUsage
  readonly property bool showCpuCores: (widgetSettings.showCpuCores !== undefined) ? widgetSettings.showCpuCores : widgetMetadata.showCpuCores
  readonly property bool showCpuFreq: (widgetSettings.showCpuFreq !== undefined) ? widgetSettings.showCpuFreq : widgetMetadata.showCpuFreq
  readonly property bool showCpuTemp: (widgetSettings.showCpuTemp !== undefined) ? widgetSettings.showCpuTemp : widgetMetadata.showCpuTemp
  readonly property bool showGpuTemp: (widgetSettings.showGpuTemp !== undefined) ? widgetSettings.showGpuTemp : widgetMetadata.showGpuTemp
  readonly property bool showMemoryUsage: (widgetSettings.showMemoryUsage !== undefined) ? widgetSettings.showMemoryUsage : widgetMetadata.showMemoryUsage
  readonly property bool showMemoryAsPercent: (widgetSettings.showMemoryAsPercent !== undefined) ? widgetSettings.showMemoryAsPercent : widgetMetadata.showMemoryAsPercent
  readonly property bool showSwapUsage: (widgetSettings.showSwapUsage !== undefined) ? widgetSettings.showSwapUsage : widgetMetadata.showSwapUsage
  readonly property bool showNetworkStats: (widgetSettings.showNetworkStats !== undefined) ? widgetSettings.showNetworkStats : widgetMetadata.showNetworkStats
  readonly property bool showDiskUsage: (widgetSettings.showDiskUsage !== undefined) ? widgetSettings.showDiskUsage : widgetMetadata.showDiskUsage
  readonly property bool showDiskUsageAsPercent: (widgetSettings.showDiskUsageAsPercent !== undefined) ? widgetSettings.showDiskUsageAsPercent : widgetMetadata.showDiskUsageAsPercent
  readonly property bool showDiskAvailable: (widgetSettings.showDiskAvailable !== undefined) ? widgetSettings.showDiskAvailable : widgetMetadata.showDiskAvailable
  // Load average does not exist on Windows (always 0), so the block stays hidden
  readonly property bool showLoadAverage: false
  readonly property string diskPath: (widgetSettings.diskPath !== undefined) ? widgetSettings.diskPath : widgetMetadata.diskPath
  readonly property string fontFamily: useMonospaceFont ? Settings.data.ui.fontFixed : Settings.data.ui.fontDefault

  readonly property int paddingPercent: usePadding ? String("100%").length : 0
  readonly property int paddingTemp: usePadding ? String("999°").length : 0
  readonly property int paddingCpuFreq: usePadding ? String("9.9").length : 0
  readonly property int paddingSpeed: usePadding ? String("9999G").length : 0

  readonly property real iconSize: Style.toOdd(capsuleHeight * 0.48)
  readonly property real miniGaugeWidth: Math.max(3, Style.toOdd(root.iconSize * 0.25))

  // Content dimensions for implicit sizing
  readonly property real contentWidth: isVertical ? capsuleHeight : Math.round(mainGrid.implicitWidth + Style.margin2M)
  readonly property real contentHeight: isVertical ? Math.round(mainGrid.implicitHeight + Style.margin2M) : capsuleHeight

  readonly property color iconColor: Color.resolveColorKey(iconColorKey)
  readonly property color textColor: Color.resolveColorKey(textColorKey)

  // Size: use implicit width/height
  // BarWidgetLoader sets explicit width/height to extend click area
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Component.onCompleted: SystemStatService.registerComponent("bar-sysmon:" + (screen?.name || "unknown"))
  Component.onDestruction: SystemStatService.unregisterComponent("bar-sysmon:" + (screen?.name || "unknown"))

  function openExternalMonitor() {
    Quickshell.execDetached(["cmd", "/c", Settings.data.systemMonitor.externalMonitor]);
  }

  // Visibility-aware warning/critical states (delegates to service)
  readonly property bool cpuWarning: showCpuUsage && SystemStatService.cpuWarning
  readonly property bool cpuCritical: showCpuUsage && SystemStatService.cpuCritical
  readonly property bool tempWarning: showCpuTemp && SystemStatService.tempWarning
  readonly property bool tempCritical: showCpuTemp && SystemStatService.tempCritical
  readonly property bool gpuWarning: showGpuTemp && SystemStatService.gpuWarning
  readonly property bool gpuCritical: showGpuTemp && SystemStatService.gpuCritical
  readonly property bool memWarning: showMemoryUsage && SystemStatService.memWarning
  readonly property bool memCritical: showMemoryUsage && SystemStatService.memCritical
  readonly property bool swapWarning: showSwapUsage && SystemStatService.swapWarning
  readonly property bool swapCritical: showSwapUsage && SystemStatService.swapCritical
  readonly property bool diskWarning: showDiskUsage && SystemStatService.isDiskWarning(diskPath)
  readonly property bool diskCritical: showDiskUsage && SystemStatService.isDiskCritical(diskPath)

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("system-monitor.title"),
        "action": "sysmon-settings",
        "icon": "settings"
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

                   if (action === "sysmon-settings") {
                     let monitorCmd = Settings.data.systemMonitor.externalMonitor;
                     if (monitorCmd && monitorCmd.trim() !== "") {
                       root.openExternalMonitor();
                     } else {
                       SettingsPanelService.openToTab(SettingsPanel.Tab.System, 0, screen);
                     }
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  // Visual capsule centered in parent
  Rectangle {
    id: visualCapsule
    width: root.contentWidth
    height: root.contentHeight
    anchors.centerIn: parent
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Mini gauge component for compact mode, vertical gauge that fills from bottom
    Component {
      id: miniGaugeComponent

      NLinearGauge {
        ratio: 0
        orientation: Qt.Vertical
        fillColor: Color.mPrimary
        width: root.miniGaugeWidth
        height: root.iconSize
      }
    }

    GridLayout {
      id: mainGrid
      anchors.centerIn: parent
      flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rows: root.isVertical ? -1 : 1
      columns: root.isVertical ? 1 : -1
      rowSpacing: root.isVertical ? (root.compactMode ? Style.marginL : Style.marginXL) : 0
      columnSpacing: root.isVertical ? 0 : Style.marginM

      // CPU Usage Component
      Item {
        id: cpuUsageContainer
        implicitWidth: cpuUsageContent.implicitWidth
        implicitHeight: cpuUsageContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showCpuUsage

        GridLayout {
          id: cpuUsageContent
          anchors.centerIn: parent

          property bool verticalDisplay: root.isVertical && (!root.compactMode || root.showCpuCores)
          flow: verticalDisplay ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: verticalDisplay ? -1 : 1
          columns: verticalDisplay ? 1 : -1
          rowSpacing: root.compactMode ? 3 : Style.marginXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "cpu-usage"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.cpuWarning || root.cpuCritical) ? SystemStatService.cpuColor : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: `${Math.round(SystemStatService.cpuUsage)}%`.padStart(root.paddingPercent, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.cpuWarning || root.cpuCritical) ? SystemStatService.cpuColor : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode general cpu
          Loader {
            active: root.compactMode && !root.showCpuCores
            visible: root.compactMode && !root.showCpuCores
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.cpuUsage / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.cpuColor);
            }
          }

          // Compact mode for cores
          Repeater {
            model: (root.compactMode && root.showCpuCores) ? SystemStatService.coresUsage : []

            delegate: NLinearGauge {
              id: coreGauge
              required property var modelData
              width: root.isVertical ? root.iconSize : root.miniGaugeWidth
              height: root.isVertical ? root.miniGaugeWidth : root.iconSize
              orientation: root.isVertical ? Qt.Horizontal : Qt.Vertical
              ratio: coreGauge.modelData / 100
              fillColor: SystemStatService.getCoreUsageColor(coreGauge.modelData)
            }
          }
        }
      }

      // CPU Frequency Component
      Item {
        id: cpuFreqContainer
        implicitWidth: cpuFreqContent.implicitWidth
        implicitHeight: cpuFreqContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showCpuFreq && (!root.isVertical || root.compactMode)

        GridLayout {
          id: cpuFreqContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "cpu-usage"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: SystemStatService.cpuFreq.replace("Hz", "").replace(" ", "").padStart(root.paddingCpuFreq, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.cpuFreqRatio);
            }
          }
        }
      }

      // CPU Temperature Component
      Item {
        id: cpuTempContainer
        implicitWidth: cpuTempContent.implicitWidth
        implicitHeight: cpuTempContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showCpuTemp

        GridLayout {
          id: cpuTempContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "cpu-temperature"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.tempWarning || root.tempCritical) ? SystemStatService.tempColor : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: `${Math.round(SystemStatService.cpuTemp)}°`.padStart(root.paddingTemp, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.tempWarning || root.tempCritical) ? SystemStatService.tempColor : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode, mini gauge (to the right of icon)
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.cpuTemp / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.tempColor);
            }
          }
        }
      }

      // GPU Temperature Component
      Item {
        id: gpuTempContainer
        implicitWidth: gpuTempContent.implicitWidth
        implicitHeight: gpuTempContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showGpuTemp && SystemStatService.gpuAvailable

        GridLayout {
          id: gpuTempContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "gpu-temperature"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.gpuWarning || root.gpuCritical) ? SystemStatService.gpuColor : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: `${Math.round(SystemStatService.gpuTemp)}°`.padStart(root.paddingTemp, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.gpuWarning || root.gpuCritical) ? SystemStatService.gpuColor : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.gpuTemp / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.gpuColor);
            }
          }
        }
      }

      // Load Average Component
      Item {
        id: loadAvgContainer
        implicitWidth: loadAvgContent.implicitWidth
        implicitHeight: loadAvgContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showLoadAverage && SystemStatService.nproc > 0 && SystemStatService.loadAvg1 > 0

        GridLayout {
          id: loadAvgContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "weight"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: `${SystemStatService.loadAvg1.toFixed(1)}`.padStart(root.usePadding ? `${SystemStatService.nproc.toFixed(1)}`.length : 0, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => Math.min(1, SystemStatService.loadAvg1 / SystemStatService.nproc));
            }
          }
        }
      }

      // Memory Usage Component
      Item {
        id: memoryContainer
        implicitWidth: memoryContent.implicitWidth
        implicitHeight: memoryContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showMemoryUsage

        GridLayout {
          id: memoryContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "memory"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.memWarning || root.memCritical) ? SystemStatService.memColor : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: SystemStatService.formatRamDisplay({
                                                       percent: root.showMemoryAsPercent,
                                                       padding: root.usePadding
                                                     })
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.memWarning || root.memCritical) ? SystemStatService.memColor : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.memPercent / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.memColor);
            }
          }
        }
      }

      // Swap Usage Component
      Item {
        id: swapContainer
        implicitWidth: swapContent.implicitWidth
        implicitHeight: swapContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showSwapUsage && SystemStatService.swapTotalGb > 0

        GridLayout {
          id: swapContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "exchange"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.swapWarning || root.swapCritical) ? SystemStatService.swapColor : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: SystemStatService.formatRamDisplay({
                                                       swap: true,
                                                       percent: true,
                                                       padding: root.usePadding
                                                     })
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.swapWarning || root.swapCritical) ? SystemStatService.swapColor : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.swapPercent / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.swapColor);
            }
          }
        }
      }

      // Network Download Speed Component
      Item {
        implicitWidth: downloadContent.implicitWidth
        implicitHeight: downloadContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showNetworkStats

        GridLayout {
          id: downloadContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "download-speed"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: root.isVertical ? SystemStatService.formatCompactSpeed(SystemStatService.rxSpeed) : SystemStatService.formatSpeed(SystemStatService.rxSpeed).padStart(root.paddingSpeed, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.rxRatio);
            }
          }
        }
      }

      // Network Upload Speed Component
      Item {
        implicitWidth: uploadContent.implicitWidth
        implicitHeight: uploadContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showNetworkStats

        GridLayout {
          id: uploadContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "upload-speed"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: root.isVertical ? SystemStatService.formatCompactSpeed(SystemStatService.txSpeed) : SystemStatService.formatSpeed(SystemStatService.txSpeed).padStart(root.paddingSpeed, " ")
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => SystemStatService.txRatio);
            }
          }
        }
      }

      // Disk Usage Component (primary drive)
      Item {
        id: diskContainer
        implicitWidth: diskContent.implicitWidth
        implicitHeight: diskContent.implicitHeight
        Layout.preferredWidth: root.isVertical ? root.width : implicitWidth
        Layout.preferredHeight: root.compactMode ? implicitHeight : root.capsuleHeight
        Layout.alignment: root.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: root.showDiskUsage

        GridLayout {
          id: diskContent
          anchors.centerIn: parent
          flow: (root.isVertical && !root.compactMode) ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: (root.isVertical && !root.compactMode) ? 2 : 1
          columns: (root.isVertical && !root.compactMode) ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: root.compactMode ? 3 : Style.marginXS

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: (root.compactMode || root.isVertical) ? root.iconSize : root.capsuleHeight
            Layout.alignment: Qt.AlignCenter
            Layout.row: (root.isVertical && !root.compactMode) ? 1 : 0
            Layout.column: 0

            NIcon {
              icon: "storage"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: (root.diskWarning || root.diskCritical) ? SystemStatService.getDiskColor(root.diskPath) : root.iconColor
            }
          }

          // Text mode
          NText {
            visible: !root.compactMode
            text: SystemStatService.formatDiskDisplay(root.diskPath, {
                                                        percent: root.showDiskUsageAsPercent,
                                                        available: root.showDiskAvailable,
                                                        padding: root.usePadding
                                                      })
            family: root.fontFamily
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: (root.diskWarning || root.diskCritical) ? SystemStatService.getDiskColor(root.diskPath) : root.textColor
            Layout.row: root.isVertical ? 0 : 0
            Layout.column: root.isVertical ? 0 : 1
          }

          // Compact mode
          Loader {
            active: root.compactMode
            visible: root.compactMode
            sourceComponent: miniGaugeComponent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 1

            onLoaded: {
              (item as NLinearGauge).ratio = Qt.binding(() => (root.showDiskAvailable ? SystemStatService.diskAvailPercents[root.diskPath] : SystemStatService.diskPercents[root.diskPath] ?? 0) / 100);
              (item as NLinearGauge).fillColor = Qt.binding(() => SystemStatService.getDiskColor(root.diskPath, root.showDiskAvailable));
            }
          }
        }
      }
    }
  }

  // MouseArea at root level for extended click area
  MouseArea {
    id: mainMouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   PanelService.getPanel("systemStatsPanel", root.screen)?.toggle(root);
                 } else if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, root, root.screen);
                 } else if (mouse.button === Qt.MiddleButton) {
                   root.openExternalMonitor();
                 }
               }
  }
}
