import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 700

  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property bool valueShowBackground: widgetData.showBackground !== undefined ? widgetData.showBackground : widgetMetadata.showBackground
  property bool valueRoundedCorners: widgetData.roundedCorners !== undefined ? widgetData.roundedCorners : widgetMetadata.roundedCorners
  property string valueClockStyle: widgetData.clockStyle !== undefined ? widgetData.clockStyle : widgetMetadata.clockStyle
  property string valueClockColor: widgetData.clockColor !== undefined ? widgetData.clockColor : widgetMetadata.clockColor
  property bool valueUseCustomFont: widgetData.useCustomFont !== undefined ? widgetData.useCustomFont : widgetMetadata.useCustomFont
  property string valueCustomFont: widgetData.customFont !== undefined ? widgetData.customFont : widgetMetadata.custonFont
  property string valueFormat: widgetData.format !== undefined ? widgetData.format : widgetMetadata.format

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

  // Function to insert token at cursor position in the focused input
  function insertToken(token) {
    var currentText, cursorPos, input, newText;
    if (!focusedInput || !focusedInput.inputItem) {
      // If no input is focused, default to format input
      if (formatInput.inputItem) {
        formatInput.inputItem.focus = true;
        focusedInput = formatInput;
      }
    }

    if (focusedInput && focusedInput.inputItem) {
      input = focusedInput.inputItem;
      cursorPos = input.cursorPosition;
      currentText = input.text;

      // Insert token at cursor position
      newText = currentText.substring(0, cursorPos) + token + currentText.substring(cursorPos);
      input.text = newText + " ";

      // Move cursor after the inserted token
      input.cursorPosition = cursorPos + token.length + 1;

      // Ensure the input keeps focus
      input.focus = true;
      saveSettings();
    }
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
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.clockStyle
  }

  NColorChoice {
    label: I18n.tr("common.select-color")
    description: I18n.tr("common.select-color-description")
    currentKey: root.valueClockColor
    onSelected: key => {
                  root.valueClockColor = key;
                  saveSettings();
                }
    defaultValue: root.widgetMetadata.clockColor
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.clock.use-custom-font-label")
    description: I18n.tr("bar.clock.use-custom-font-description")
    checked: root.valueUseCustomFont
    onToggled: checked => {
                 root.valueUseCustomFont = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.useCustomFont
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
      saveSettings();
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
          settingsChanged(saveSettings());
        }
        Component.onCompleted: {
          if (inputItem) {
            inputItem.onActiveFocusChanged.connect(function () {
              if (inputItem.activeFocus) {
                root.focusedInput = formatInput;
              }
            });
          }
        }
        defaultValue: root.widgetMetadata.format
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
                visible: text !== ""
                text: modelData
                family: valueUseCustomFont && valueCustomFont ? valueCustomFont : Settings.data.ui.fontDefault
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: Color.resolveColorKey(valueClockColor)
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
    height: 200
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
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.showBackground
  }

  NToggle {
    Layout.fillWidth: true
    visible: root.valueShowBackground
    label: I18n.tr("panels.desktop-widgets.clock-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.clock-rounded-corners-description")
    checked: root.valueRoundedCorners
    onToggled: checked => {
                 root.valueRoundedCorners = checked;
                 saveSettings();
               }
    defaultValue: root.widgetMetadata.roundedCorners
  }
}
