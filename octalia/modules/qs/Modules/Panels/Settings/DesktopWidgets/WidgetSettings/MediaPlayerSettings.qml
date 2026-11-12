import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property bool valueShowBackground: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showBackground")
  property string valueVisualizerType: SettingsValue.truthyFallback(widgetData, widgetMetadata, "visualizerType")
  property string valueHideMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideMode")
  property bool valueShowButtons: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showButtons")
  property bool valueShowAlbumArt: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showAlbumArt")
  property bool valueShowVisualizer: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showVisualizer")
  property bool valueRoundedCorners: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "roundedCorners")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.showBackground = valueShowBackground;
    settings.visualizerType = valueVisualizerType;
    settings.hideMode = valueHideMode;
    settings.showButtons = valueShowButtons;
    settings.showAlbumArt = valueShowAlbumArt;
    settings.showVisualizer = valueShowVisualizer;
    settings.roundedCorners = valueRoundedCorners;
    settingsChanged(settings);
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-show-background-label")
    description: I18n.tr("panels.desktop-widgets.media-player-show-background-description")
    checked: root.valueShowBackground
    onToggled: checked => {
                 root.valueShowBackground = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showBackground")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.media-player-rounded-corners-description")
    checked: root.valueRoundedCorners
    onToggled: checked => {
                 root.valueRoundedCorners = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "roundedCorners")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.media-player-show-album-art-label")
    description: I18n.tr("panels.desktop-widgets.media-player-show-album-art-description")
    checked: root.valueShowAlbumArt
    onToggled: checked => {
                 root.valueShowAlbumArt = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showAlbumArt")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.media-player-show-buttons-label")
    description: I18n.tr("panels.desktop-widgets.media-player-show-buttons-description")
    checked: root.valueShowButtons
    onToggled: checked => {
                 root.valueShowButtons = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showButtons")
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.hide-mode-label")
    description: I18n.tr("bar.media-mini.hide-mode-description")
    model: [
      {
        "key": "hidden",
        "name": I18n.tr("hide-modes.hidden")
      },
      {
        "key": "idle",
        "name": I18n.tr("hide-modes.idle")
      },
      {
        "key": "visible",
        "name": I18n.tr("hide-modes.visible")
      }
    ]
    currentKey: root.valueHideMode
    onSelected: key => {
                  root.valueHideMode = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideMode")
  }
}
