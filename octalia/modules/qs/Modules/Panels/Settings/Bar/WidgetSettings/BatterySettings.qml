import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.Hardware
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

  // Local state
  property string valueDisplayMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "displayMode")
  property string valueDeviceNativePath: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "deviceNativePath")
  property bool valueShowPowerProfiles: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showPowerProfiles")
  property bool valueShowOctaliaPerformance: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showOctaliaPerformance")
  property bool valueHideIfNotDetected: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideIfNotDetected")
  property bool valueHideIfIdle: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideIfIdle")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    if (widgetData && SettingsValue.read(widgetData, "id")) {
      settings.id = SettingsValue.read(widgetData, "id");
    }
    settings.displayMode = valueDisplayMode;
    settings.showPowerProfiles = valueShowPowerProfiles;
    settings.showOctaliaPerformance = valueShowOctaliaPerformance;
    settings.hideIfNotDetected = valueHideIfNotDetected;
    settings.hideIfIdle = valueHideIfIdle;
    settings.deviceNativePath = valueDeviceNativePath;
    settingsChanged(settings);
  }

  NComboBox {
    id: deviceComboBox
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.device-label")
    description: I18n.tr("bar.battery.device-description")
    minimumWidth: 240
    model: BatteryService.deviceModel
    currentKey: root.valueDeviceNativePath
    onSelected: key => {
                  root.valueDeviceNativePath = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "deviceNativePath")
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("common.display-mode")
    description: I18n.tr("bar.battery.display-mode-description")
    minimumWidth: 240
    model: [
      {
        "key": "graphic",
        "name": I18n.tr("bar.battery.display-mode-graphic")
      },
      {
        "key": "graphic-clean",
        "name": I18n.tr("bar.battery.display-mode-graphic-clean")
      },
      {
        "key": "icon-hover",
        "name": I18n.tr("bar.battery.display-mode-icon-hover")
      },
      {
        "key": "icon-always",
        "name": I18n.tr("bar.battery.display-mode-icon-always")
      },
      {
        "key": "icon-only",
        "name": I18n.tr("bar.battery.display-mode-icon-only")
      }
    ]
    currentKey: root.valueDisplayMode
    onSelected: key => {
                  root.valueDisplayMode = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "displayMode")
  }

  NToggle {
    label: I18n.tr("bar.battery.hide-if-not-detected-label")
    description: I18n.tr("bar.battery.hide-if-not-detected-description")
    checked: root.valueHideIfNotDetected
    onToggled: checked => {
                 root.valueHideIfNotDetected = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideIfNotDetected")
  }

  NToggle {
    label: I18n.tr("bar.battery.hide-if-idle-label")
    description: I18n.tr("bar.battery.hide-if-idle-description")
    checked: root.valueHideIfIdle
    onToggled: checked => {
                 root.valueHideIfIdle = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideIfIdle")
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    label: I18n.tr("bar.battery.show-power-profile-label")
    description: I18n.tr("bar.battery.show-power-profile-description")
    checked: root.valueShowPowerProfiles
    onToggled: checked => {
                 root.valueShowPowerProfiles = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showPowerProfiles")
  }

  NToggle {
    label: I18n.tr("bar.battery.show-octalia-performance-label")
    description: I18n.tr("bar.battery.show-octalia-performance-description")
    checked: root.valueShowOctaliaPerformance
    onToggled: checked => {
                 root.valueShowOctaliaPerformance = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showOctaliaPerformance")
  }
}
