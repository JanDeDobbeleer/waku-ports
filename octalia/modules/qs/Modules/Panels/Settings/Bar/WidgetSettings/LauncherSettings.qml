import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
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
  property string valueIcon: widgetData.icon !== undefined ? widgetData.icon : widgetMetadata.icon
  // No distro logo on Windows (HostService.osLogo is empty).
  readonly property bool valueUseDistroLogo: false
  property string valueCustomIconPath: widgetData.customIconPath !== undefined ? widgetData.customIconPath : widgetMetadata.customIconPath
  property bool valueEnableColorization: widgetData.enableColorization !== undefined ? widgetData.enableColorization : widgetMetadata.enableColorization
  property string valueColorizeSystemIcon: widgetData.colorizeSystemIcon !== undefined ? widgetData.colorizeSystemIcon : widgetMetadata.colorizeSystemIcon

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.icon = valueIcon;
    settings.useDistroLogo = valueUseDistroLogo;
    settings.customIconPath = valueCustomIconPath;
    settings.enableColorization = valueEnableColorization;
    settings.colorizeSystemIcon = valueColorizeSystemIcon;
    settingsChanged(settings);
  }

  NToggle {
    label: I18n.tr("bar.custom-button.enable-colorization-label")
    description: I18n.tr("bar.control-center.enable-colorization-description")
    checked: root.valueEnableColorization
    onToggled: checked => {
                 root.valueEnableColorization = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.enableColorization
  }

  NColorChoice {
    visible: root.valueEnableColorization
    label: I18n.tr("common.select-icon-color")
    description: I18n.tr("bar.control-center.color-selection-description")
    currentKey: root.valueColorizeSystemIcon
    onSelected: function (key) {
      root.valueColorizeSystemIcon = key;
      saveSettings();
    }
    defaultValue: root.widgetMetadata.colorizeSystemIcon
  }

  RowLayout {
    spacing: Style.marginM

    NLabel {
      label: I18n.tr("common.icon")
      description: I18n.tr("bar.control-center.icon-description")
    }

    NImageRounded {
      Layout.preferredWidth: Style.fontSizeXL * 2
      Layout.preferredHeight: Style.fontSizeXL * 2
      Layout.alignment: Qt.AlignVCenter
      radius: Math.min(Style.radiusL, Layout.preferredWidth / 2)
      imagePath: root.valueCustomIconPath
      visible: root.valueCustomIconPath !== "" && !root.valueUseDistroLogo
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.valueIcon
      pointSize: Style.fontSizeXXL * 1.5
      visible: root.valueIcon !== "" && root.valueCustomIconPath === "" && !root.valueUseDistroLogo
    }
  }

  RowLayout {
    spacing: Style.marginM
    NButton {
      enabled: !root.valueUseDistroLogo
      text: I18n.tr("bar.control-center.browse-library")
      onClicked: iconPicker.open()
    }

    NButton {
      enabled: !root.valueUseDistroLogo
      text: I18n.tr("bar.control-center.browse-file")
      onClicked: imagePicker.openFilePicker()
    }
  }

  NIconPicker {
    id: iconPicker
    initialIcon: root.valueIcon
    onIconSelected: iconName => {
                      root.valueIcon = iconName;
                      root.valueCustomIconPath = "";
                      saveSettings();
                    }
  }

  NFilePicker {
    id: imagePicker
    title: I18n.tr("bar.control-center.select-custom-icon")
    selectionMode: "files"
    nameFilters: ImageCacheService.basicImageFilters.concat(["*.svg"])
    initialPath: Quickshell.env("USERPROFILE") || Quickshell.env("HOME")
    onAccepted: paths => {
                  if (paths.length > 0) {
                    root.valueCustomIconPath = paths[0];
                    saveSettings();
                  }
                }
  }
}
