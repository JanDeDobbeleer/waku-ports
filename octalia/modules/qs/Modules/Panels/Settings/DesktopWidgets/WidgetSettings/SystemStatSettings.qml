import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 700

  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property string valueStatType: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "statType")
  property string valueDiskPath: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "diskPath")
  property bool valueShowBackground: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showBackground")
  property bool valueRoundedCorners: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "roundedCorners")
  property string valueLayout: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "layout")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.statType = valueStatType;
    settings.diskPath = valueDiskPath;
    settings.showBackground = valueShowBackground;
    settings.roundedCorners = valueRoundedCorners;
    settings.layout = valueLayout;
    settingsChanged(settings);
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.system-stat-stat-type-label")
    description: I18n.tr("panels.desktop-widgets.system-stat-stat-type-description")
    currentKey: root.valueStatType
    minimumWidth: 260 * Style.uiScaleRatio
    model: {
      let items = [
            {
              "key": "CPU",
              "name": I18n.tr("system-monitor.cpu-usage")
            },
            {
              "key": "Memory",
              "name": I18n.tr("common.memory")
            },
            {
              "key": "Network",
              "name": I18n.tr("bar.system-monitor.network-traffic-label")
            },
            {
              "key": "Disk",
              "name": I18n.tr("system-monitor.disk")
            }
          ];
      if (Settings.data.systemMonitor.enableDgpuMonitoring)
        items.push({
                     "key": "GPU",
                     "name": I18n.tr("panels.system-monitor.gpu-section-label")
                   });
      return items;
    }
    onSelected: key => {
                  root.valueStatType = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "statType")
  }

  NComboBox {
    Layout.fillWidth: true
    visible: root.valueStatType === "Disk"
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

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.system-stat-show-background-label")
    description: I18n.tr("panels.desktop-widgets.system-stat-show-background-description")
    checked: root.valueShowBackground
    onToggled: checked => {
                 root.valueShowBackground = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showBackground")
  }

  NToggle {
    Layout.fillWidth: true
    visible: root.valueShowBackground
    label: I18n.tr("panels.desktop-widgets.system-stat-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.system-stat-rounded-corners-description")
    checked: root.valueRoundedCorners
    onToggled: checked => {
                 root.valueRoundedCorners = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "roundedCorners")
  }

  NDivider {
    Layout.fillWidth: true
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.system-stat-layout-label")
    description: I18n.tr("panels.desktop-widgets.system-stat-layout-description")
    currentKey: root.valueLayout
    minimumWidth: 260 * Style.uiScaleRatio
    model: [
      {
        "key": "side",
        "name": I18n.tr("panels.desktop-widgets.system-stat-layout-side")
      },
      {
        "key": "bottom",
        "name": I18n.tr("panels.desktop-widgets.system-stat-layout-bottom")
      }
    ]
    onSelected: key => {
                  root.valueLayout = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "layout")
  }
}
