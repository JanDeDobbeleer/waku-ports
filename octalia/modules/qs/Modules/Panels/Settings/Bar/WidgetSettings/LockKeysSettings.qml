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
  property bool valueShowCapsLock: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showCapsLock")
  property bool valueShowNumLock: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showNumLock")
  property bool valueShowScrollLock: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showScrollLock")

  property string capsIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "capsLockIcon")
  property string numIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "numLockIcon")
  property string scrollIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "scrollLockIcon")

  property bool valueHideWhenOff: SettingsValue.undefinedFallbackDefault(widgetData, widgetMetadata, "hideWhenOff", false)

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.showCapsLock = valueShowCapsLock;
    settings.showNumLock = valueShowNumLock;
    settings.showScrollLock = valueShowScrollLock;
    settings.capsLockIcon = capsIcon;
    settings.numLockIcon = numIcon;
    settings.scrollLockIcon = scrollIcon;
    settings.hideWhenOff = valueHideWhenOff;
    settingsChanged(settings);
  }

  RowLayout {
    spacing: Style.marginM

    NToggle {
      label: I18n.tr("bar.lock-keys.show-caps-lock-label")
      description: I18n.tr("bar.lock-keys.show-caps-lock-description")
      checked: root.valueShowCapsLock
      onToggled: checked => {
                   root.valueShowCapsLock = checked;
                   root.saveSettings();
                 }
      defaultValue: SettingsValue.read(root.widgetMetadata, "showCapsLock")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.capsIcon
      pointSize: Style.fontSizeXL
      visible: root.capsIcon !== ""
    }

    NButton {
      text: I18n.tr("common.browse")
      onClicked: capsPicker.open()
      enabled: root.valueShowCapsLock
    }
  }

  NIconPicker {
    id: capsPicker
    initialIcon: root.capsIcon
    query: "letter-c"
    onIconSelected: function (iconName) {
      root.capsIcon = iconName;
      root.saveSettings();
    }
  }

  RowLayout {
    spacing: Style.marginM

    NToggle {
      label: I18n.tr("bar.lock-keys.show-num-lock-label")
      description: I18n.tr("bar.lock-keys.show-num-lock-description")
      checked: root.valueShowNumLock
      onToggled: checked => {
                   root.valueShowNumLock = checked;
                   root.saveSettings();
                 }
      defaultValue: SettingsValue.read(root.widgetMetadata, "showNumLock")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.numIcon
      pointSize: Style.fontSizeXL
      visible: root.numIcon !== ""
    }

    NButton {
      text: I18n.tr("common.browse")
      onClicked: numPicker.open()
      enabled: root.valueShowNumLock
    }
  }

  NIconPicker {
    id: numPicker
    initialIcon: root.numIcon
    query: "letter-n"
    onIconSelected: function (iconName) {
      root.numIcon = iconName;
      root.saveSettings();
    }
  }

  RowLayout {
    spacing: Style.marginM

    NToggle {
      label: I18n.tr("bar.lock-keys.show-scroll-lock-label")
      description: I18n.tr("bar.lock-keys.show-scroll-lock-description")
      checked: root.valueShowScrollLock
      onToggled: checked => {
                   root.valueShowScrollLock = checked;
                   root.saveSettings();
                 }
      defaultValue: SettingsValue.read(root.widgetMetadata, "showScrollLock")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.scrollIcon
      pointSize: Style.fontSizeXL
      visible: root.scrollIcon !== ""
    }

    NButton {
      text: I18n.tr("common.browse")
      onClicked: scrollPicker.open()
      enabled: root.valueShowScrollLock
    }
  }

  NIconPicker {
    id: scrollPicker
    initialIcon: root.scrollIcon
    query: "letter-s"
    onIconSelected: function (iconName) {
      root.scrollIcon = iconName;
      root.saveSettings();
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.lock-keys.hide-when-off-label")
    description: I18n.tr("bar.lock-keys.hide-when-off-description")
    checked: root.valueHideWhenOff
    onToggled: checked => {
                 root.valueHideWhenOff = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideWhenOff")
  }
}
