import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  // Local state
  property string valueHideMode: widgetData.hideMode !== undefined ? widgetData.hideMode : widgetMetadata.hideMode
  // Deprecated: hideWhenIdle now folded into hideMode = "idle"
  property bool valueHideWhenIdle: widgetData.hideWhenIdle !== undefined ? widgetData.hideWhenIdle : widgetMetadata.hideWhenIdle
  property bool valueShowAlbumArt: widgetData.showAlbumArt !== undefined ? widgetData.showAlbumArt : widgetMetadata.showAlbumArt
  property bool valuePanelShowAlbumArt: widgetData.panelShowAlbumArt !== undefined ? widgetData.panelShowAlbumArt : widgetMetadata.panelShowAlbumArt
  property bool valueShowArtistFirst: widgetData.showArtistFirst !== undefined ? widgetData.showArtistFirst : widgetMetadata.showArtistFirst
  property bool valueShowVisualizer: widgetData.showVisualizer !== undefined ? widgetData.showVisualizer : widgetMetadata.showVisualizer
  property string valueVisualizerType: widgetData.visualizerType !== undefined ? widgetData.visualizerType : widgetMetadata.visualizerType
  property string valueScrollingMode: widgetData.scrollingMode !== undefined ? widgetData.scrollingMode : widgetMetadata.scrollingMode
  property int valueMaxWidth: widgetData.maxWidth !== undefined ? widgetData.maxWidth : widgetMetadata.maxWidth
  property bool valueUseFixedWidth: widgetData.useFixedWidth !== undefined ? widgetData.useFixedWidth : widgetMetadata.useFixedWidth
  property bool valueShowProgressRing: widgetData.showProgressRing !== undefined ? widgetData.showProgressRing : widgetMetadata.showProgressRing
  property bool valueCompactMode: widgetData.compactMode !== undefined ? widgetData.compactMode : widgetMetadata.compactMode
  property string valueTextColor: widgetData.textColor !== undefined ? widgetData.textColor : widgetMetadata.textColor

  Component.onCompleted: {
    if (widgetData && widgetData.hideMode !== undefined) {
      valueHideMode = widgetData.hideMode;
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
    settings.maxWidth = parseInt(widthInput.text) || widgetMetadata.maxWidth;
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
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.hideMode
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-album-art-label")
    description: I18n.tr("bar.media-mini.show-album-art-description")
    checked: root.valueShowAlbumArt
    onToggled: checked => {
                 root.valueShowAlbumArt = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showAlbumArt
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-artist-first-label")
    description: I18n.tr("bar.media-mini.show-artist-first-description")
    checked: root.valueShowArtistFirst
    onToggled: checked => {
                 root.valueShowArtistFirst = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showArtistFirst
  }

  NTextInput {
    id: widthInput
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.max-width-label")
    description: I18n.tr("bar.media-mini.max-width-description")
    placeholderText: root.widgetMetadata.maxWidth
    text: root.valueMaxWidth
    onTextChanged: saveSettings()
    defaultValue: String(root.widgetMetadata.maxWidth)
  }

  NToggle {
    label: I18n.tr("bar.media-mini.use-fixed-width-label")
    description: I18n.tr("bar.media-mini.use-fixed-width-description")
    checked: root.valueUseFixedWidth
    onToggled: checked => {
                 root.valueUseFixedWidth = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.useFixedWidth
  }

  NToggle {
    label: I18n.tr("bar.media-mini.show-progress-ring-label")
    description: I18n.tr("bar.media-mini.show-progress-ring-description")
    checked: root.valueShowProgressRing
    onToggled: checked => {
                 root.valueShowProgressRing = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showProgressRing
  }

  NColorChoice {
    currentKey: root.valueTextColor
    onSelected: key => {
                  root.valueTextColor = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.textColor
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
                  saveSettings();
                }
    minimumWidth: 200
    defaultValue: root.widgetMetadata.scrollingMode
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
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.panelShowAlbumArt
  }

  NToggle {
    label: I18n.tr("bar.media-mini.compact-mode-label")
    description: I18n.tr("bar.media-mini.compact-mode-description")
    checked: root.valueCompactMode
    onToggled: checked => {
                 root.valueCompactMode = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.compactMode
  }
}
