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

  property string valueLabelMode: widgetData.labelMode !== undefined ? widgetData.labelMode : widgetMetadata.labelMode
  property bool valueHideUnoccupied: widgetData.hideUnoccupied !== undefined ? widgetData.hideUnoccupied : widgetMetadata.hideUnoccupied
  property bool valueFollowFocusedScreen: widgetData.followFocusedScreen !== undefined ? widgetData.followFocusedScreen : widgetMetadata.followFocusedScreen
  property int valueCharacterCount: widgetData.characterCount !== undefined ? widgetData.characterCount : widgetMetadata.characterCount

  // Grouped mode settings
  property bool valueShowApplications: widgetData.showApplications !== undefined ? widgetData.showApplications : widgetMetadata.showApplications
  property bool valueShowApplicationsHover: widgetData.showApplicationsHover !== undefined ? widgetData.showApplicationsHover : widgetMetadata.showApplicationsHover
  property bool valueShowLabelsOnlyWhenOccupied: widgetData.showLabelsOnlyWhenOccupied !== undefined ? widgetData.showLabelsOnlyWhenOccupied : widgetMetadata.showLabelsOnlyWhenOccupied
  property bool valueColorizeIcons: widgetData.colorizeIcons !== undefined ? widgetData.colorizeIcons : widgetMetadata.colorizeIcons
  property real valueUnfocusedIconsOpacity: widgetData.unfocusedIconsOpacity !== undefined ? widgetData.unfocusedIconsOpacity : widgetMetadata.unfocusedIconsOpacity
  property real valueGroupedBorderOpacity: widgetData.groupedBorderOpacity !== undefined ? widgetData.groupedBorderOpacity : widgetMetadata.groupedBorderOpacity
  property bool valueEnableScrollWheel: widgetData.enableScrollWheel !== undefined ? widgetData.enableScrollWheel : widgetMetadata.enableScrollWheel
  property real valueIconScale: widgetData.iconScale !== undefined ? widgetData.iconScale : widgetMetadata.iconScale
  property string valueFocusedColor: widgetData.focusedColor !== undefined ? widgetData.focusedColor : widgetMetadata.focusedColor
  property string valueOccupiedColor: widgetData.occupiedColor !== undefined ? widgetData.occupiedColor : widgetMetadata.occupiedColor
  property string valueEmptyColor: widgetData.emptyColor !== undefined ? widgetData.emptyColor : widgetMetadata.emptyColor
  property bool valueShowBadge: widgetData.showBadge !== undefined ? widgetData.showBadge : widgetMetadata.showBadge
  property real valuePillSize: widgetData.pillSize !== undefined ? widgetData.pillSize : widgetMetadata.pillSize
  property string valueFontWeight: widgetData.fontWeight !== undefined ? widgetData.fontWeight : widgetMetadata.fontWeight

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.labelMode = valueLabelMode;
    settings.hideUnoccupied = valueHideUnoccupied;
    settings.characterCount = valueCharacterCount;
    settings.followFocusedScreen = valueFollowFocusedScreen;
    settings.showApplications = valueShowApplications;
    settings.showApplicationsHover = valueShowApplicationsHover;
    settings.showLabelsOnlyWhenOccupied = valueShowLabelsOnlyWhenOccupied;
    settings.colorizeIcons = valueColorizeIcons;
    settings.unfocusedIconsOpacity = valueUnfocusedIconsOpacity;
    settings.groupedBorderOpacity = valueGroupedBorderOpacity;
    settings.enableScrollWheel = valueEnableScrollWheel;
    settings.iconScale = valueIconScale;
    settings.focusedColor = valueFocusedColor;
    settings.occupiedColor = valueOccupiedColor;
    settings.emptyColor = valueEmptyColor;
    settings.showBadge = valueShowBadge;
    settings.pillSize = valuePillSize;
    settings.fontWeight = valueFontWeight;
    settingsChanged(settings);
  }

  NComboBox {
    id: labelModeCombo
    label: I18n.tr("bar.workspace.label-mode-label")
    description: I18n.tr("bar.workspace.label-mode-description")
    model: [
      {
        "key": "none",
        "name": I18n.tr("common.none")
      },
      {
        "key": "index",
        "name": I18n.tr("options.workspace-labels.index")
      },
      {
        "key": "name",
        "name": I18n.tr("options.workspace-labels.name")
      },
      {
        "key": "index+name",
        "name": I18n.tr("options.workspace-labels.index-and-name")
      }
    ]
    currentKey: root.widgetData.labelMode || root.widgetMetadata.labelMode
    onSelected: key => {
                  root.valueLabelMode = key;
                  saveSettings();
                }
    minimumWidth: 200
  }

  NSpinBox {
    label: I18n.tr("bar.workspace.character-count-label")
    description: I18n.tr("bar.workspace.character-count-description")
    from: 1
    to: 10
    value: root.valueCharacterCount
    onValueChanged: {
      root.valueCharacterCount = value;
      saveSettings();
    }
    visible: root.valueLabelMode === "name"
  }

  NValueSlider {
    label: I18n.tr("bar.workspace.pill-size-label")
    description: I18n.tr("bar.workspace.pill-size-description")
    from: 0.4
    to: 1.0
    stepSize: 0.01
    value: root.valuePillSize
    defaultValue: root.widgetMetadata.pillSize
    showReset: true
    onMoved: value => {
               root.valuePillSize = value;
               saveSettings();
             }
    text: Math.round(root.valuePillSize * 100) + "%"
    visible: !root.valueShowApplications
  }

  NComboBox {
    id: fontWeightCombo
    label: I18n.tr("bar.workspace.font-weight-label")
    description: I18n.tr("bar.workspace.font-weight-description")
    model: [
      {
        "key": "regular",
        "name": I18n.tr("common.font-weight-regular")
      },
      {
        "key": "medium",
        "name": I18n.tr("common.font-weight-medium")
      },
      {
        "key": "semibold",
        "name": I18n.tr("common.font-weight-semibold")
      },
      {
        "key": "bold",
        "name": I18n.tr("common.font-weight-bold")
      },
    ]
    currentKey: root.widgetData.fontWeight || root.widgetMetadata.fontWeight
    onSelected: key => {
                  root.valueFontWeight = key;
                  saveSettings();
                }
    minimumWidth: 200
  }

  NToggle {
    label: I18n.tr("bar.workspace.hide-unoccupied-label")
    description: I18n.tr("bar.workspace.hide-unoccupied-description")
    checked: root.valueHideUnoccupied
    onToggled: checked => {
                 root.valueHideUnoccupied = checked;
                 saveSettings();
               }
  }

  NToggle {
    label: I18n.tr("bar.workspace.show-labels-only-when-occupied-label")
    description: I18n.tr("bar.workspace.show-labels-only-when-occupied-description")
    checked: root.valueShowLabelsOnlyWhenOccupied
    onToggled: checked => {
                 root.valueShowLabelsOnlyWhenOccupied = checked;
                 saveSettings();
               }
  }

  NToggle {
    label: I18n.tr("bar.workspace.follow-focused-screen-label")
    description: I18n.tr("bar.workspace.follow-focused-screen-description")
    checked: root.valueFollowFocusedScreen
    onToggled: checked => {
                 root.valueFollowFocusedScreen = checked;
                 saveSettings();
               }
  }

  NToggle {
    label: I18n.tr("bar.workspace.enable-scrollwheel-label")
    description: I18n.tr("bar.workspace.enable-scrollwheel-description")
    checked: root.valueEnableScrollWheel
    onToggled: checked => {
                 root.valueEnableScrollWheel = checked;
                 saveSettings();
               }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    label: I18n.tr("bar.workspace.show-applications-label")
    description: I18n.tr("bar.workspace.show-applications-description")
    checked: root.valueShowApplications
    onToggled: checked => {
                 root.valueShowApplications = checked;
                 saveSettings();
               }
  }

  NToggle {
    label: I18n.tr("bar.workspace.show-applications-hover-label")
    description: I18n.tr("bar.workspace.show-applications-hover-description")
    checked: root.valueShowApplicationsHover
    onToggled: checked => {
                 root.valueShowApplicationsHover = checked;
                 saveSettings();
               }
    visible: root.valueShowApplications
  }

  NToggle {
    label: I18n.tr("bar.workspace.show-badge-label")
    description: I18n.tr("bar.workspace.show-badge-description")
    checked: root.valueShowBadge
    onToggled: checked => {
                 root.valueShowBadge = checked;
                 saveSettings();
               }
    visible: root.valueShowApplications
  }

  NToggle {
    label: I18n.tr("bar.tray.colorize-icons-label")
    description: I18n.tr("bar.active-window.colorize-icons-description")
    checked: root.valueColorizeIcons
    onToggled: checked => {
                 root.valueColorizeIcons = checked;
                 saveSettings();
               }
    visible: root.valueShowApplications
  }

  NValueSlider {
    label: I18n.tr("bar.workspace.unfocused-icons-opacity-label")
    description: I18n.tr("bar.workspace.unfocused-icons-opacity-description")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: root.valueUnfocusedIconsOpacity
    defaultValue: root.widgetMetadata.unfocusedIconsOpacity
    onMoved: value => {
               root.valueUnfocusedIconsOpacity = value;
               saveSettings();
             }
    text: Math.floor(root.valueUnfocusedIconsOpacity * 100) + "%"
    visible: root.valueShowApplications
  }

  NValueSlider {
    label: I18n.tr("bar.workspace.grouped-border-opacity-label")
    description: I18n.tr("bar.workspace.grouped-border-opacity-description")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: root.valueGroupedBorderOpacity
    defaultValue: root.widgetMetadata.groupedBorderOpacity
    onMoved: value => {
               root.valueGroupedBorderOpacity = value;
               saveSettings();
             }
    text: Math.floor(root.valueGroupedBorderOpacity * 100) + "%"
    visible: root.valueShowApplications
  }

  NValueSlider {
    label: I18n.tr("bar.taskbar.icon-scale-label")
    description: I18n.tr("bar.taskbar.icon-scale-description")
    from: 0.5
    to: 1
    stepSize: 0.01
    showReset: true
    value: root.valueIconScale
    defaultValue: root.widgetMetadata.iconScale
    onMoved: value => {
               root.valueIconScale = value;
               saveSettings();
             }
    text: Math.round(root.valueIconScale * 100) + "%"
    visible: root.valueShowApplications
  }

  NDivider {
    Layout.fillWidth: true
  }

  NColorChoice {
    label: I18n.tr("bar.workspace.focused-color-label")
    description: I18n.tr("bar.workspace.focused-color-description")
    currentKey: root.valueFocusedColor
    onSelected: key => {
                  root.valueFocusedColor = key;
                  saveSettings();
                }
  }

  NColorChoice {
    label: I18n.tr("bar.workspace.occupied-color-label")
    description: I18n.tr("bar.workspace.occupied-color-description")
    currentKey: root.valueOccupiedColor
    onSelected: key => {
                  root.valueOccupiedColor = key;
                  saveSettings();
                }
  }

  NColorChoice {
    label: I18n.tr("bar.workspace.empty-color-label")
    description: I18n.tr("bar.workspace.empty-color-description")
    currentKey: root.valueEmptyColor
    onSelected: key => {
                  root.valueEmptyColor = key;
                  saveSettings();
                }
  }
}
