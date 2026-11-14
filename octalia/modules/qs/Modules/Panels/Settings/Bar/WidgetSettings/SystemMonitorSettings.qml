import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  readonly property string barPosition: Settings.getBarPositionForScreen(SettingsValue.optionalRead(screen, "name"))
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"

  // Local, editable state for checkboxes
  property bool valueCompactMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "compactMode")
  property string valueIconColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconColor")
  property string valueTextColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "textColor")
  property bool valueUseMonospaceFont: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "useMonospaceFont")
  property bool valueUsePadding: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "usePadding")
  property bool valueShowCpuUsage: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showCpuUsage")
  property bool valueShowCpuCores: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showCpuCores")
  property bool valueShowCpuFreq: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showCpuFreq")
  property bool valueShowCpuTemp: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showCpuTemp")
  property bool valueShowGpuTemp: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showGpuTemp")
  property bool valueShowMemoryUsage: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showMemoryUsage")
  property bool valueShowMemoryAsPercent: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showMemoryAsPercent")
  property bool valueShowSwapUsage: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showSwapUsage")
  property bool valueShowNetworkStats: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showNetworkStats")
  property bool valueShowDiskUsage: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showDiskUsage")
  property bool valueShowDiskUsageAsPercent: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showDiskUsageAsPercent")
  property bool valueShowDiskAvailable: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showDiskAvailable")
  property string valueDiskPath: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "diskPath")

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
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "compactMode")
  }

  NColorChoice {
    label: I18n.tr("common.select-icon-color")
    currentKey: root.valueIconColor
    onSelected: key => {
                  root.valueIconColor = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "iconColor")
  }

  NColorChoice {
    currentKey: root.valueTextColor
    onSelected: key => {
                  root.valueTextColor = key;
                  root.saveSettings();
                }
    visible: !root.valueCompactMode
    defaultValue: SettingsValue.read(root.widgetMetadata, "textColor")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.use-monospace-font-label")
    description: I18n.tr("bar.system-monitor.use-monospace-font-description")
    checked: root.valueUseMonospaceFont
    onToggled: checked => {
                 root.valueUseMonospaceFont = checked;
                 root.saveSettings();
               }
    visible: !root.valueCompactMode
    defaultValue: SettingsValue.read(root.widgetMetadata, "useMonospaceFont")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.use-padding-label")
    description: root.isVerticalBar ? I18n.tr("bar.system-monitor.use-padding-description-disabled-vertical") : !root.valueUseMonospaceFont ? I18n.tr("bar.system-monitor.use-padding-description-disabled-monospace-font") : I18n.tr("bar.system-monitor.use-padding-description")
    checked: root.valueUsePadding && !root.isVerticalBar && root.valueUseMonospaceFont
    onToggled: checked => {
                 root.valueUsePadding = checked;
                 root.saveSettings();
               }
    visible: !root.valueCompactMode
    enabled: !root.isVerticalBar && root.valueUseMonospaceFont
    defaultValue: SettingsValue.read(root.widgetMetadata, "usePadding")
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
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showCpuUsage")
  }

  NToggle {
    id: showCpuCores
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-cores-label")
    description: I18n.tr("bar.system-monitor.cpu-cores-description")
    checked: root.valueShowCpuCores
    onToggled: checked => {
                 root.valueShowCpuCores = checked;
                 root.saveSettings();
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
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showCpuFreq")
  }

  NToggle {
    id: showCpuTemp
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.cpu-temperature-label")
    description: I18n.tr("bar.system-monitor.cpu-temperature-description")
    checked: root.valueShowCpuTemp
    onToggled: checked => {
                 root.valueShowCpuTemp = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showCpuTemp")
  }

  NToggle {
    id: showGpuTemp
    Layout.fillWidth: true
    label: I18n.tr("panels.system-monitor.gpu-section-label")
    description: I18n.tr("bar.system-monitor.gpu-temperature-description")
    checked: root.valueShowGpuTemp
    onToggled: checked => {
                 root.valueShowGpuTemp = checked;
                 root.saveSettings();
               }
    visible: SystemStatService.gpuAvailable
    defaultValue: SettingsValue.read(root.widgetMetadata, "showGpuTemp")
  }

  NToggle {
    id: showMemoryUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.memory-usage-label")
    description: I18n.tr("bar.system-monitor.memory-usage-description")
    checked: root.valueShowMemoryUsage
    onToggled: checked => {
                 root.valueShowMemoryUsage = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showMemoryUsage")
  }

  NToggle {
    id: showMemoryAsPercent
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.memory-percentage-label")
    description: I18n.tr("bar.system-monitor.memory-percentage-description")
    checked: root.valueShowMemoryAsPercent
    onToggled: checked => {
                 root.valueShowMemoryAsPercent = checked;
                 root.saveSettings();
               }
    visible: root.valueShowMemoryUsage
    defaultValue: SettingsValue.read(root.widgetMetadata, "showMemoryAsPercent")
  }

  NToggle {
    id: showSwapUsage
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.swap-usage-label")
    description: I18n.tr("bar.system-monitor.swap-usage-description")
    checked: root.valueShowSwapUsage
    onToggled: checked => {
                 root.valueShowSwapUsage = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showSwapUsage")
  }

  NToggle {
    id: showNetworkStats
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.network-traffic-label")
    description: I18n.tr("bar.system-monitor.network-traffic-description")
    checked: root.valueShowNetworkStats
    onToggled: checked => {
                 root.valueShowNetworkStats = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showNetworkStats")
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
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showDiskUsage")
  }

  NToggle {
    id: showDiskUsageAsPercent
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.storage-as-percentage-label")
    description: I18n.tr("bar.system-monitor.storage-as-percentage-description")
    checked: root.valueShowDiskUsageAsPercent
    onToggled: checked => {
                 root.valueShowDiskUsageAsPercent = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showDiskUsageAsPercent")
  }

  NToggle {
    id: showDiskAvailable
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.storage-available-label")
    description: I18n.tr("bar.system-monitor.storage-available-description")
    checked: root.valueShowDiskAvailable
    onToggled: checked => {
                 root.valueShowDiskAvailable = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showDiskAvailable")
  }

  NComboBox {
    id: diskPathComboBox
    Layout.fillWidth: true
    label: I18n.tr("bar.system-monitor.disk-path-label")
    description: I18n.tr("bar.system-monitor.disk-path-description")
    model: SettingsValue.diskPathOptions(SystemStatService.diskPercents)
    currentKey: root.valueDiskPath
    onSelected: key => {
                  root.valueDiskPath = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "diskPath")
  }
}
