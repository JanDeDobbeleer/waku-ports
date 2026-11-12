import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"

  // Local, editable state for checkboxes
  property bool valueCompactMode: widgetData.compactMode !== undefined ? widgetData.compactMode : widgetMetadata.compactMode
  property string valueIconColor: widgetData.iconColor !== undefined ? widgetData.iconColor : widgetMetadata.iconColor
  property string valueTextColor: widgetData.textColor !== undefined ? widgetData.textColor : widgetMetadata.textColor
  property bool valueUseMonospaceFont: widgetData.useMonospaceFont !== undefined ? widgetData.useMonospaceFont : widgetMetadata.useMonospaceFont
  property bool valueUsePadding: widgetData.usePadding !== undefined ? widgetData.usePadding : widgetMetadata.usePadding
  property bool valueShowCpuUsage: widgetData.showCpuUsage !== undefined ? widgetData.showCpuUsage : widgetMetadata.showCpuUsage
  property bool valueShowCpuCores: widgetData.showCpuCores !== undefined ? widgetData.showCpuCores : widgetMetadata.showCpuCores
  property bool valueShowCpuFreq: widgetData.showCpuFreq !== undefined ? widgetData.showCpuFreq : widgetMetadata.showCpuFreq
  property bool valueShowCpuTemp: widgetData.showCpuTemp !== undefined ? widgetData.showCpuTemp : widgetMetadata.showCpuTemp
  property bool valueShowGpuTemp: widgetData.showGpuTemp !== undefined ? widgetData.showGpuTemp : widgetMetadata.showGpuTemp
  property bool valueShowMemoryUsage: widgetData.showMemoryUsage !== undefined ? widgetData.showMemoryUsage : widgetMetadata.showMemoryUsage
  property bool valueShowMemoryAsPercent: widgetData.showMemoryAsPercent !== undefined ? widgetData.showMemoryAsPercent : widgetMetadata.showMemoryAsPercent
  property bool valueShowSwapUsage: widgetData.showSwapUsage !== undefined ? widgetData.showSwapUsage : widgetMetadata.showSwapUsage
  property bool valueShowNetworkStats: widgetData.showNetworkStats !== undefined ? widgetData.showNetworkStats : widgetMetadata.showNetworkStats
  property bool valueShowDiskUsage: widgetData.showDiskUsage !== undefined ? widgetData.showDiskUsage : widgetMetadata.showDiskUsage
  property bool valueShowDiskUsageAsPercent: widgetData.showDiskUsageAsPercent !== undefined ? widgetData.showDiskUsageAsPercent : widgetMetadata.showDiskUsageAsPercent
  property bool valueShowDiskAvailable: widgetData.showDiskAvailable !== undefined ? widgetData.showDiskAvailable : widgetMetadata.showDiskAvailable
  property string valueDiskPath: widgetData.diskPath !== undefined ? widgetData.diskPath : widgetMetadata.diskPath

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.compactMode = valueCompactMode;
    settings.iconColor = valueIconColor;
    settings.textColor = valueTextColor;
    settings.useMonospaceFont = valueUseMonospaceFont;
    settings.usePadding = valueUsePadding;
    settings.showCpuUsage = valueShowCpuUsage;
    settings.showCpuCores = valueShowCpuCores;
    settings.showCpuFreq = valueShowCpuFreq;
    settings.showCpuTemp = valueShowCpuTemp;
    settings.showGpuTemp = valueShowGpuTemp;
    settings.showMemoryUsage = valueShowMemoryUsage;
    settings.showMemoryAsPercent = valueShowMemoryAsPercent;
    settings.showSwapUsage = valueShowSwapUsage;
    settings.showNetworkStats = valueShowNetworkStats;
    settings.showDiskUsage = valueShowDiskUsage;
    settings.showDiskUsageAsPercent = valueShowDiskUsageAsPercent;
    settings.showDiskAvailable = valueShowDiskAvailable;
    settings.diskPath = valueDiskPath;

    settingsChanged(settings);
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.compact-mode-label")
    description: I18n.tr("bar.system-monitor.compact-mode-description")
    checked: root.valueCompactMode
    onToggled: checked => {
                 root.valueCompactMode = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.compactMode
  }

  NColorChoice {
    label: I18n.tr("common.select-icon-color")
    currentKey: root.valueIconColor
    onSelected: key => {
                  root.valueIconColor = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.iconColor
  }

  NColorChoice {
    currentKey: root.valueTextColor
    onSelected: key => {
                  root.valueTextColor = key;
                  saveSettings();
                }
    visible: !root.valueCompactMode
    defaultValue: root.widgetMetadata.textColor
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.use-monospace-font-label")
    description: I18n.tr("bar.system-monitor.use-monospace-font-description")
    checked: root.valueUseMonospaceFont
    onToggled: checked => {
                 root.valueUseMonospaceFont = checked;
                 saveSettings();
               }
    visible: !root.valueCompactMode
    defaultValue: root.widgetMetadata.useMonospaceFont
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.use-padding-label")
    description: root.isVerticalBar ? I18n.tr("bar.system-monitor.use-padding-description-disabled-vertical") : !root.valueUseMonospaceFont ? I18n.tr("bar.system-monitor.use-padding-description-disabled-monospace-font") : I18n.tr("bar.system-monitor.use-padding-description")
    checked: root.valueUsePadding && !root.isVerticalBar && root.valueUseMonospaceFont
    onToggled: checked => {
                 root.valueUsePadding = checked;
                 saveSettings();
               }
    visible: !root.valueCompactMode
    enabled: !root.isVerticalBar && root.valueUseMonospaceFont
    defaultValue: root.widgetMetadata.usePadding
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    id: showCpuUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-usage-label")
    description: I18n.tr("bar.system-monitor.cpu-usage-description")
    checked: root.valueShowCpuUsage
    onToggled: checked => {
                 root.valueShowCpuUsage = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showCpuUsage
  }

  NToggle {
    id: showCpuCores
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-cores-label")
    description: I18n.tr("bar.system-monitor.cpu-cores-description")
    checked: root.valueShowCpuCores
    onToggled: checked => {
                 root.valueShowCpuCores = checked;
                 saveSettings();
               }
    visible: root.valueCompactMode
  }

  NToggle {
    id: showCpuFreq
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-frequency-label")
    description: I18n.tr("bar.system-monitor.cpu-frequency-description")
    checked: root.valueShowCpuFreq
    onToggled: checked => {
                 root.valueShowCpuFreq = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showCpuFreq
  }

  NToggle {
    id: showCpuTemp
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-temperature-label")
    description: I18n.tr("bar.system-monitor.cpu-temperature-description")
    checked: root.valueShowCpuTemp
    onToggled: checked => {
                 root.valueShowCpuTemp = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showCpuTemp
  }

  NToggle {
    id: showGpuTemp
    Layout.fillWidth: true
    label: I18n.tr("panels.system-monitor.gpu-section-label")
    description: I18n.tr("bar.system-monitor.gpu-temperature-description")
    checked: root.valueShowGpuTemp
    onToggled: checked => {
                 root.valueShowGpuTemp = checked;
                 saveSettings();
               }
    visible: SystemStatService.gpuAvailable
    defaultValue: root.widgetMetadata.showGpuTemp
  }

  NToggle {
    id: showMemoryUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.memory-usage-label")
    description: I18n.tr("bar.system-monitor.memory-usage-description")
    checked: root.valueShowMemoryUsage
    onToggled: checked => {
                 root.valueShowMemoryUsage = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showMemoryUsage
  }

  NToggle {
    id: showMemoryAsPercent
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.memory-percentage-label")
    description: I18n.tr("bar.system-monitor.memory-percentage-description")
    checked: root.valueShowMemoryAsPercent
    onToggled: checked => {
                 root.valueShowMemoryAsPercent = checked;
                 saveSettings();
               }
    visible: root.valueShowMemoryUsage
    defaultValue: root.widgetMetadata.showMemoryAsPercent
  }

  NToggle {
    id: showSwapUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.swap-usage-label")
    description: I18n.tr("bar.system-monitor.swap-usage-description")
    checked: root.valueShowSwapUsage
    onToggled: checked => {
                 root.valueShowSwapUsage = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showSwapUsage
  }

  NToggle {
    id: showNetworkStats
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.network-traffic-label")
    description: I18n.tr("bar.system-monitor.network-traffic-description")
    checked: root.valueShowNetworkStats
    onToggled: checked => {
                 root.valueShowNetworkStats = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showNetworkStats
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    id: showDiskUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.storage-usage-label")
    description: I18n.tr("bar.system-monitor.storage-usage-description")
    checked: root.valueShowDiskUsage
    onToggled: checked => {
                 root.valueShowDiskUsage = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showDiskUsage
  }

  NToggle {
    id: showDiskUsageAsPercent
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.storage-as-percentage-label")
    description: I18n.tr("bar.system-monitor.storage-as-percentage-description")
    checked: root.valueShowDiskUsageAsPercent
    onToggled: checked => {
                 root.valueShowDiskUsageAsPercent = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showDiskUsageAsPercent
  }

  NToggle {
    id: showDiskAvailable
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.storage-available-label")
    description: I18n.tr("bar.system-monitor.storage-available-description")
    checked: root.valueShowDiskAvailable
    onToggled: checked => {
                 root.valueShowDiskAvailable = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showDiskAvailable
  }

  NComboBox {
    id: diskPathComboBox
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.disk-path-label")
    description: I18n.tr("bar.system-monitor.disk-path-description")
    model: {
      const paths = Object.keys(SystemStatService.diskPercents).sort();
      return paths.map(path => ({
                                  key: path,
                                  name: path
                                }));
    }
    currentKey: root.valueDiskPath
    onSelected: key => {
                  root.valueDiskPath = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.diskPath
  }
}
