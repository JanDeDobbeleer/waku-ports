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
  property string valueHideMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideMode")
  // Deprecated: hideWhenIdle now folded into hideMode = "idle"
  property bool valueHideWhenIdle: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideWhenIdle")
  property bool valueShowAlbumArt: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showAlbumArt")
  property bool valuePanelShowAlbumArt: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "panelShowAlbumArt")
  property bool valueShowArtistFirst: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showArtistFirst")
  property bool valueShowVisualizer: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showVisualizer")
  property string valueVisualizerType: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "visualizerType")
  property string valueScrollingMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "scrollingMode")
  property int valueMaxWidth: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "maxWidth")
  property bool valueUseFixedWidth: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "useFixedWidth")
  property bool valueShowProgressRing: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showProgressRing")
  property bool valueCompactMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "compactMode")
  property string valueTextColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "textColor")

  Component.onCompleted: {
    if (widgetData && SettingsValue.read(widgetData, "hideMode") !== undefined) {
      valueHideMode = SettingsValue.read(widgetData, "hideMode");
    }
  }

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.hideMode = valueHideMode;
    // No longer store hideWhenIdle separately; kept for backward compatibility only
    settings.showAlbumArt = valueShowAlbumArt;
    settings.panelShowAlbumArt = valuePanelShowAlbumArt;
    settings.showArtistFirst = valueShowArtistFirst;
    settings.showVisualizer = valueShowVisualizer;
    settings.visualizerType = valueVisualizerType;
    settings.scrollingMode = valueScrollingMode;
    settings.maxWidth = parseInt(widthInput.text) || SettingsValue.read(widgetMetadata, "maxWidth");
    settings.useFixedWidth = valueUseFixedWidth;
    settings.showProgressRing = valueShowProgressRing;
    settings.compactMode = valueCompactMode;
    settings.textColor = valueTextColor;
    settingsChanged(settings);
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.hide-mode-label")
    description: I18n.tr("bar.media-mini.hide-mode-description")
    model: [
      {
        "key": "visible",
        "name": I18n.tr("hide-modes.visible")
      },
      {
        "key": "hidden",
        "name": I18n.tr("hide-modes.hidden")
      },
      {
        "key": "transparent",
        "name": I18n.tr("hide-modes.transparent")
      },
      {
        "key": "idle",
        "name": I18n.tr("hide-modes.idle")
      }
    ]
    currentKey: root.valueHideMode
    onSelected: key => {
                  root.valueHideMode = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideMode")
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-album-art-label")
    description: I18n.tr("bar.media-mini.show-album-art-description")
    checked: root.valueShowAlbumArt
    onToggled: checked => {
                 root.valueShowAlbumArt = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showAlbumArt")
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-artist-first-label")
    description: I18n.tr("bar.media-mini.show-artist-first-description")
    checked: root.valueShowArtistFirst
    onToggled: checked => {
                 root.valueShowArtistFirst = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showArtistFirst")
  }

  NTextInput {
    id: widthInput
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.max-width-label")
    description: I18n.tr("bar.media-mini.max-width-description")
    placeholderText: SettingsValue.read(root.widgetMetadata, "maxWidth")
    text: root.valueMaxWidth
    onTextChanged: root.saveSettings()
    defaultValue: String(SettingsValue.read(root.widgetMetadata, "maxWidth"))
  }

  NToggle {
    label: I18n.tr("bar.media-mini.use-fixed-width-label")
    description: I18n.tr("bar.media-mini.use-fixed-width-description")
    checked: root.valueUseFixedWidth
    onToggled: checked => {
                 root.valueUseFixedWidth = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "useFixedWidth")
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-progress-ring-label")
    description: I18n.tr("bar.media-mini.show-progress-ring-description")
    checked: root.valueShowProgressRing
    onToggled: checked => {
                 root.valueShowProgressRing = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showProgressRing")
  }

  NColorChoice {
    currentKey: root.valueTextColor
    onSelected: key => {
                  root.valueTextColor = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "textColor")
  }

  NComboBox {
    label: I18n.tr("bar.media-mini.scrolling-mode-label")
    description: I18n.tr("bar.media-mini.scrolling-mode-description")
    model: [
      {
        "key": "always",
        "name": I18n.tr("options.scrolling-modes.always")
      },
      {
        "key": "hover",
        "name": I18n.tr("options.scrolling-modes.hover")
      },
      {
        "key": "never",
        "name": I18n.tr("options.scrolling-modes.never")
      }
    ]
    currentKey: root.valueScrollingMode
    onSelected: key => {
                  root.valueScrollingMode = key;
                  root.saveSettings();
                }
    minimumWidth: 200
    defaultValue: SettingsValue.read(root.widgetMetadata, "scrollingMode")
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
  }

  NLabel {
    label: I18n.tr("bar.media-mini.panel-section-label")
    description: I18n.tr("bar.media-mini.panel-section-description")
    labelColor: Color.mPrimary
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-album-art-label")
    description: I18n.tr("bar.media-mini.show-album-art-description")
    checked: root.valuePanelShowAlbumArt
    onToggled: checked => {
                 root.valuePanelShowAlbumArt = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "panelShowAlbumArt")
  }

  NToggle {
    label: I18n.tr("bar.media-mini.compact-mode-label")
    description: I18n.tr("bar.media-mini.compact-mode-description")
    checked: root.valueCompactMode
    onToggled: checked => {
                 root.valueCompactMode = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "compactMode")
  }
}
