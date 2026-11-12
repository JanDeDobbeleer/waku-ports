pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "ClockSettings.js" as ClockSettingsData
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 700

  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property bool valueShowBackground: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showBackground", "showBackground")
  property bool valueRoundedCorners: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "roundedCorners", "roundedCorners")
  property string valueClockStyle: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "clockStyle", "clockStyle")
  property string valueClockColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "clockColor", "clockColor")
  property bool valueUseCustomFont: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "useCustomFont", "useCustomFont")
  property string valueCustomFont: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "customFont", "custonFont")
  property string valueFormat: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "format", "format")

  // Track the currently focused input field
  property var focusedInput: null

  readonly property bool isMinimalMode: valueClockStyle === "minimal"
  readonly property var now: Time.now

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.showBackground = valueShowBackground;
    settings.roundedCorners = valueRoundedCorners;
    settings.clockStyle = valueClockStyle;
    settings.clockColor = valueClockColor;
    settings.useCustomFont = valueUseCustomFont;
    settings.customFont = valueCustomFont;
    settings.format = valueFormat.trim();
    settingsChanged(settings);
  }

  function insertToken(token: string): void {
    ClockSettingsData.insertToken(root, formatInput, token);
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-style-label")
    description: I18n.tr("panels.desktop-widgets.clock-style-description")
    currentKey: root.valueClockStyle
    minimumWidth: 260 * Style.uiScaleRatio
    model: [
      {
        "key": "minimal",
        "name": I18n.tr("panels.desktop-widgets.clock-style-minimal")
      },
      {
        "key": "digital",
        "name": I18n.tr("panels.desktop-widgets.clock-style-digital")
      },
      {
        "key": "analog",
        "name": I18n.tr("panels.desktop-widgets.clock-style-analog")
      },
      {
        "key": "binary",
        "name": I18n.tr("panels.desktop-widgets.clock-style-binary")
      }
    ]
    onSelected: key => {
                  root.valueClockStyle = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "clockStyle")
  }

  NColorChoice {
    label: I18n.tr("common.select-color")
    description: I18n.tr("common.select-color-description")
    currentKey: root.valueClockColor
    onSelected: key => {
                  root.valueClockColor = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "clockColor")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.clock.use-custom-font-label")
    description: I18n.tr("bar.clock.use-custom-font-description")
    checked: root.valueUseCustomFont
    onToggled: checked => {
                 root.valueUseCustomFont = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "useCustomFont")
  }

  NSearchableComboBox {
    Layout.fillWidth: true
    visible: root.valueUseCustomFont
    label: I18n.tr("bar.clock.custom-font-label")
    description: I18n.tr("bar.clock.custom-font-description")
    model: FontService.availableFonts
    currentKey: root.valueCustomFont
    placeholder: I18n.tr("bar.clock.custom-font-placeholder")
    searchPlaceholder: I18n.tr("bar.clock.custom-font-search-placeholder")
    popupHeight: 420
    minimumWidth: 300
    onSelected: function (key) {
      root.valueCustomFont = key;
      root.saveSettings();
    }
    enabled: root.valueClockStyle === "minimal"
    defaultValue: Settings.data.ui.fontDefault
  }

  NDivider {
    Layout.fillWidth: true
    visible: root.isMinimalMode
  }

  NHeader {
    visible: root.isMinimalMode
    label: I18n.tr("bar.clock.clock-display-label")
    description: I18n.tr("bar.clock.clock-display-description")
  }

  // Format editor - only visible in minimal mode
  RowLayout {
    id: main
    visible: root.isMinimalMode
    spacing: Style.marginL
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

    ColumnLayout {
      spacing: Style.marginM
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

      NTextInput {
        id: formatInput
        Layout.fillWidth: true
        label: I18n.tr("panels.desktop-widgets.clock-format-label")
        description: I18n.tr("bar.clock.horizontal-bar-description")
        placeholderText: "HH:mm\\nd MMMM yyyy"
        text: root.valueFormat
        onTextChanged: {
          root.valueFormat = text;
          root.settingsChanged(root.saveSettings());
        }
        Component.onCompleted: ClockSettingsData.watchInput(inputItem, root, formatInput)
        defaultValue: SettingsValue.read(root.widgetMetadata, "format")
      }
    }

    // Preview
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
      Layout.fillWidth: false

      NLabel {
        label: I18n.tr("bar.clock.preview")
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
      }

      Rectangle {
        Layout.preferredWidth: 320
        Layout.preferredHeight: 160
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mSecondary
        border.width: Style.borderS

        Behavior on border.color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }

        ColumnLayout {
          spacing: Style.marginM
          anchors.centerIn: parent

          ColumnLayout {
            spacing: -2
            Layout.alignment: Qt.AlignHCenter

            Repeater {
              Layout.topMargin: Style.marginM
              model: I18n.locale.toString(root.now, root.valueFormat.trim()).split("\\n")
              delegate: NText {
                required property var modelData
                visible: text !== ""
                text: modelData
                family: root.valueUseCustomFont && root.valueCustomFont ? root.valueCustomFont : Settings.data.ui.fontDefault
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: Color.resolveColorKey(root.valueClockColor)
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationFast
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  NDivider {
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
    visible: root.isMinimalMode
  }

  NDateTimeTokens {
    Layout.fillWidth: true
    Layout.preferredHeight: 200
    visible: root.isMinimalMode
    onTokenClicked: token => root.insertToken(token)
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-show-background-label")
    description: I18n.tr("panels.desktop-widgets.clock-show-background-description")
    checked: root.valueShowBackground
    onToggled: checked => {
                 root.valueShowBackground = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showBackground")
  }

  NToggle {
    Layout.fillWidth: true
    visible: root.valueShowBackground
    label: I18n.tr("panels.desktop-widgets.clock-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.clock-rounded-corners-description")
    checked: root.valueRoundedCorners
    onToggled: checked => {
                 root.valueRoundedCorners = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "roundedCorners")
  }
}
