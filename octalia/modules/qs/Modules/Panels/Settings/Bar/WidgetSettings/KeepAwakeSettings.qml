import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
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

  property string valueIconColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconColor")
  property string valueTextColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "textColor")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.iconColor = valueIconColor;
    settings.textColor = valueTextColor;
    settingsChanged(settings);
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
    defaultValue: SettingsValue.read(root.widgetMetadata, "textColor")
  }
}
