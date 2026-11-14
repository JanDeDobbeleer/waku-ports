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

  // Local state
  property string valueDisplayMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "displayMode")
  property string valueIconColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconColor")
  property string valueTextColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "textColor")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.displayMode = valueDisplayMode;
    settings.iconColor = valueIconColor;
    settings.textColor = valueTextColor;
    settingsChanged(settings);
  }

  NComboBox {
    label: I18n.tr("common.display-mode")
    description: I18n.tr("bar.volume.display-mode-description")
    minimumWidth: 200
    model: [
      {
        "key": "onhover",
        "name": I18n.tr("display-modes.on-hover")
      },
      {
        "key": "alwaysShow",
        "name": I18n.tr("display-modes.always-show")
      },
      {
        "key": "alwaysHide",
        "name": I18n.tr("display-modes.always-hide")
      }
    ]
    currentKey: root.valueDisplayMode
    onSelected: key => {
                  root.valueDisplayMode = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "displayMode")
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
