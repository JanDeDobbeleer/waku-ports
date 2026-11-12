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
  property bool valueHideWhenIdle: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideWhenIdle")
  property string valueColorName: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "colorName")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.width = parseInt(widthInput.text) || SettingsValue.read(widgetMetadata, "width");
    settings.hideWhenIdle = valueHideWhenIdle;
    settings.colorName = valueColorName;
    settingsChanged(settings);
  }

  NTextInput {
    id: widthInput
    Layout.fillWidth: true
    label: I18n.tr("common.width")
    description: I18n.tr("bar.audio-visualizer.width-description")
    text: SettingsValue.read(root.widgetData, "width") || SettingsValue.read(root.widgetMetadata, "width")
    placeholderText: I18n.tr("placeholders.enter-width-pixels")
    onTextChanged: root.saveSettings()
    defaultValue: String(SettingsValue.read(root.widgetMetadata, "width"))
  }

  NColorChoice {
    Layout.fillWidth: true
    label: I18n.tr("bar.audio-visualizer.color-name-label")
    description: I18n.tr("bar.audio-visualizer.color-name-description")
    currentKey: root.valueColorName
    onSelected: key => {
                  root.valueColorName = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "colorName")
  }

  NToggle {
    label: I18n.tr("bar.audio-visualizer.hide-when-idle-label")
    description: I18n.tr("bar.audio-visualizer.hide-when-idle-description")
    checked: root.valueHideWhenIdle
    onToggled: checked => {
                 root.valueHideWhenIdle = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideWhenIdle")
  }
}
