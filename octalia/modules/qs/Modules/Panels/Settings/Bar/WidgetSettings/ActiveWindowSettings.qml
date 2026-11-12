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
  property bool valueShowIcon: widgetData.showIcon !== undefined ? widgetData.showIcon : widgetMetadata.showIcon
  property bool valueShowText: widgetData.showText !== undefined ? widgetData.showText : widgetMetadata.showText
  property string valueHideMode: widgetData.hideMode !== undefined ? widgetData.hideMode : widgetMetadata.hideMode
  property string valueScrollingMode: widgetData.scrollingMode || widgetMetadata.scrollingMode
  property int valueMaxWidth: widgetData.maxWidth !== undefined ? widgetData.maxWidth : widgetMetadata.maxWidth
  property bool valueUseFixedWidth: widgetData.useFixedWidth !== undefined ? widgetData.useFixedWidth : widgetMetadata.useFixedWidth
  property bool valueColorizeIcons: widgetData.colorizeIcons !== undefined ? widgetData.colorizeIcons : widgetMetadata.colorizeIcons
  property string valueTextColor: widgetData.textColor !== undefined ? widgetData.textColor : widgetMetadata.textColor

  Component.onCompleted: {
    if (widgetData && widgetData.hideMode !== undefined) {
      valueHideMode = widgetData.hideMode;
    }
  }

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.hideMode = valueHideMode;
    settings.showIcon = valueShowIcon;
    settings.showText = valueShowText;
    settings.scrollingMode = valueScrollingMode;
    settings.maxWidth = parseInt(widthInput.text) || widgetMetadata.maxWidth;
    settings.useFixedWidth = valueUseFixedWidth;
    settings.colorizeIcons = valueColorizeIcons;
    settings.textColor = valueTextColor;
    settingsChanged(settings);
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.hide-mode-label")
    description: I18n.tr("bar.active-window.hide-mode-description")
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
      }
    ]
    currentKey: root.valueHideMode
    onSelected: key => {
                  root.valueHideMode = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.hideMode
  }

  NColorChoice {
    label: I18n.tr("common.select-color")
    currentKey: root.valueTextColor
    onSelected: key => {
                  root.valueTextColor = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.textColor
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.active-window.show-app-text-label")
    description: I18n.tr("bar.active-window.show-app-text-description")
    checked: root.valueShowText
    onToggled: checked => {
                 root.valueShowText = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showText
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.active-window.show-app-icon-label")
    description: I18n.tr("bar.active-window.show-app-icon-description")
    checked: root.valueShowIcon
    onToggled: checked => {
                 root.valueShowIcon = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showIcon
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.tray.colorize-icons-label")
    description: I18n.tr("bar.active-window.colorize-icons-description")
    checked: root.valueColorizeIcons
    onToggled: checked => {
                 root.valueColorizeIcons = checked;
                 saveSettings();
               }
    visible: root.valueShowIcon
    defaultValue: root.widgetMetadata.colorizeIcons
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
    Layout.fillWidth: true
    label: I18n.tr("bar.media-mini.use-fixed-width-label")
    description: I18n.tr("bar.media-mini.use-fixed-width-description")
    checked: root.valueUseFixedWidth
    onToggled: checked => {
                 root.valueUseFixedWidth = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.useFixedWidth
  }

  NComboBox {
    label: I18n.tr("bar.media-mini.scrolling-mode-label")
    description: I18n.tr("bar.active-window.scrolling-mode-description")
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
    defaultValue: root.widgetMetadata.scrollingMode
    onSelected: key => {
                  root.valueScrollingMode = key;
                  saveSettings();
                }
    minimumWidth: 200
  }
}
