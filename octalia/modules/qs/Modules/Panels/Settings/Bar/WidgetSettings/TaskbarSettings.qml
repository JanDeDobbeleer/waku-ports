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

  readonly property bool isVerticalBar: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

  // Local state
  property string valueHideMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideMode")
  property bool valueOnlyActiveWorkspaces: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "onlyActiveWorkspaces")
  property bool valueOnlySameOutput: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "onlySameOutput")
  property bool valueColorizeIcons: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "colorizeIcons")
  property bool valueShowTitle: isVerticalBar ? false : SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showTitle")
  property bool valueSmartWidth: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "smartWidth")
  property int valueMaxTaskbarWidth: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "maxTaskbarWidth")
  property int valueTitleWidth: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "titleWidth")
  property bool valueShowPinnedApps: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showPinnedApps")
  property real valueIconScale: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconScale")

  Component.onCompleted: {
    if (widgetData && SettingsValue.read(widgetData, "hideMode") !== undefined) {
      valueHideMode = SettingsValue.read(widgetData, "hideMode");
    } else if (widgetMetadata && SettingsValue.read(widgetMetadata, "hideMode") !== undefined) {
      valueHideMode = SettingsValue.read(widgetMetadata, "hideMode");
    }
  }

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.hideMode = valueHideMode;
    settings.onlySameOutput = valueOnlySameOutput;
    settings.onlyActiveWorkspaces = valueOnlyActiveWorkspaces;
    settings.colorizeIcons = valueColorizeIcons;
    settings.showTitle = valueShowTitle;
    settings.smartWidth = valueSmartWidth;
    settings.maxTaskbarWidth = valueMaxTaskbarWidth;
    settings.titleWidth = parseInt(titleWidthInput.text) || SettingsValue.read(widgetMetadata, "titleWidth");
    settings.showPinnedApps = valueShowPinnedApps;
    settings.iconScale = valueIconScale;
    settingsChanged(settings);
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.hide-mode-label")
    description: I18n.tr("bar.taskbar.hide-mode-description")
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
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideMode")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.only-same-monitor-label")
    description: I18n.tr("bar.taskbar.only-same-monitor-description")
    checked: root.valueOnlySameOutput
    onToggled: checked => {
                 root.valueOnlySameOutput = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "onlySameOutput")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.only-active-workspaces-label")
    description: I18n.tr("bar.taskbar.only-active-workspaces-description")
    checked: root.valueOnlyActiveWorkspaces
    onToggled: checked => {
                 root.valueOnlyActiveWorkspaces = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "onlyActiveWorkspaces")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.tray.colorize-icons-label")
    description: I18n.tr("bar.taskbar.colorize-icons-description")
    checked: root.valueColorizeIcons
    onToggled: checked => {
                 root.valueColorizeIcons = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "colorizeIcons")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.show-pinned-apps-label")
    description: I18n.tr("bar.taskbar.show-pinned-apps-description")
    checked: root.valueShowPinnedApps
    onToggled: checked => {
                 root.valueShowPinnedApps = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showPinnedApps")
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.icon-scale-label")
    description: I18n.tr("bar.taskbar.icon-scale-description")
    from: 0.5
    to: 1
    stepSize: 0.01
    showReset: true
    value: root.valueIconScale
    defaultValue: SettingsValue.read(root.widgetMetadata, "iconScale")
    onMoved: value => {
               root.valueIconScale = value;
               root.saveSettings();
             }
    text: Math.round(root.valueIconScale * 100) + "%"
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.show-title-label")
    description: root.isVerticalBar ? I18n.tr("bar.taskbar.show-title-description-disabled") : I18n.tr("bar.taskbar.show-title-description")
    checked: root.valueShowTitle
    onToggled: checked => {
                 root.valueShowTitle = checked;
                 root.saveSettings();
               }
    enabled: !root.isVerticalBar
    defaultValue: SettingsValue.read(root.widgetMetadata, "showTitle")
  }

  NTextInput {
    id: titleWidthInput
    visible: root.valueShowTitle && !root.isVerticalBar
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.title-width-label")
    description: I18n.tr("bar.taskbar.title-width-description")
    text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "titleWidth")
    placeholderText: I18n.tr("placeholders.enter-width-pixels")
    onTextChanged: root.saveSettings()
    defaultValue: String(SettingsValue.read(root.widgetMetadata, "titleWidth"))
  }

  NToggle {
    Layout.fillWidth: true
    visible: !root.isVerticalBar && root.valueShowTitle
    label: I18n.tr("bar.taskbar.smart-width-label")
    description: I18n.tr("bar.taskbar.smart-width-description")
    checked: root.valueSmartWidth
    onToggled: checked => {
                 root.valueSmartWidth = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "smartWidth")
  }

  NValueSlider {
    visible: root.valueSmartWidth && !root.isVerticalBar
    Layout.fillWidth: true
    label: I18n.tr("bar.taskbar.max-width-label")
    description: I18n.tr("bar.taskbar.max-width-description")
    from: 10
    to: 100
    stepSize: 5
    showReset: true
    value: root.valueMaxTaskbarWidth
    defaultValue: SettingsValue.read(root.widgetMetadata, "maxTaskbarWidth")
    onMoved: value => {
               root.valueMaxTaskbarWidth = Math.round(value);
               root.saveSettings();
             }
    text: Math.round(root.valueMaxTaskbarWidth) + "%"
  }
}
