import QtQuick 6.10
import QtQuick.Layouts
import QtQuick.Window
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

  // Bar orientation (per-screen)
  property bool barIsVertical: (Settings.getBarPositionForScreen(SettingsValue.optionalRead(screen, "name")) === "left" || Settings.getBarPositionForScreen(SettingsValue.optionalRead(screen, "name")) === "right")

  property string valueIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "icon")
  property string valueIconPosition: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconPosition")
  property bool valueTextStream: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "textStream")
  property bool valueParseJson: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "parseJson")
  property int valueMaxTextLengthHorizontal: SettingsValue.nestedNullishFallback(widgetData, widgetMetadata, "maxTextLength", "horizontal")
  property int valueMaxTextLengthVertical: SettingsValue.nestedNullishFallback(widgetData, widgetMetadata, "maxTextLength", "vertical")
  property string valueHideMode: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideMode")
  property bool valueShowIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showIcon")
  property string valueColorizeSystemIcon: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "colorizeSystemIcon")
  property string valueColorizeSystemText: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "colorizeSystemText")
  property string valueIpcIdentifier: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "ipcIdentifier")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.icon = valueIcon;
    settings.iconPosition = valueIconPosition;
    settings.leftClickExec = leftClickExecInput.text;
    settings.leftClickUpdateText = leftClickUpdateText.checked;
    settings.rightClickExec = rightClickExecInput.text;
    settings.rightClickUpdateText = rightClickUpdateText.checked;
    settings.middleClickExec = middleClickExecInput.text;
    settings.middleClickUpdateText = middleClickUpdateText.checked;
    settings.wheelMode = separateWheelToggle.internalChecked ? "separate" : "unified";
    settings.wheelExec = wheelExecInput.text;
    settings.wheelUpExec = wheelUpExecInput.text;
    settings.wheelDownExec = wheelDownExecInput.text;
    settings.wheelUpdateText = wheelUpdateText.checked;
    settings.wheelUpUpdateText = wheelUpUpdateText.checked;
    settings.wheelDownUpdateText = wheelDownUpdateText.checked;
    settings.textCommand = textCommandInput.text;
    settings.textCollapse = textCollapseInput.text;
    settings.textStream = valueTextStream;
    settings.parseJson = valueParseJson;
    settings.showIcon = valueShowIcon;
    settings.hideMode = valueHideMode;
    settings.maxTextLength = {
      "horizontal": valueMaxTextLengthHorizontal,
      "vertical": valueMaxTextLengthVertical
    };
    settings.textIntervalMs = parseInt(textIntervalInput.text || textIntervalInput.placeholderText, 10);
    settings.colorizeSystemIcon = valueColorizeSystemIcon;
    settings.colorizeSystemText = valueColorizeSystemText;
    settings.ipcIdentifier = valueIpcIdentifier;
    settingsChanged(settings);
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("bar.custom-button.tab-actions")
      tabIndex: 0
      checked: tabView.currentIndex === 0
      onClicked: tabView.currentIndex = 0
    }
    NTabButton {
      text: I18n.tr("bar.custom-button.tab-icon")
      tabIndex: 1
      checked: tabView.currentIndex === 1
      onClicked: tabView.currentIndex = 1
    }
    NTabButton {
      text: I18n.tr("bar.custom-button.tab-text")
      tabIndex: 2
      checked: tabView.currentIndex === 2
      onClicked: tabView.currentIndex = 2
    }
  }

  NTabView {
    id: tabView
    Layout.fillWidth: true

    // ============ Actions Tab ============
    ColumnLayout {
      spacing: Style.marginM

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: leftClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.custom-button.left-click-label")
          description: I18n.tr("bar.custom-button.left-click-description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "leftClickExec")
          onTextChanged: root.saveSettings()
          defaultValue: SettingsValue.read(root.widgetMetadata, "leftClickExec")
        }

        NToggle {
          id: leftClickUpdateText
          enabled: !root.valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          checked: SettingsValue.nullishFallback(root.widgetData, root.widgetMetadata, "leftClickUpdateText")
          onToggled: isChecked => {
                       checked = isChecked;
                       root.saveSettings();
                     }
          defaultValue: SettingsValue.read(root.widgetMetadata, "leftClickUpdateText")
        }
      }

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: rightClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.custom-button.right-click-label")
          description: I18n.tr("bar.custom-button.right-click-description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "rightClickExec")
          onTextChanged: root.saveSettings()
          defaultValue: SettingsValue.read(root.widgetMetadata, "rightClickExec")
        }

        NToggle {
          id: rightClickUpdateText
          enabled: !root.valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          checked: SettingsValue.nullishFallback(root.widgetData, root.widgetMetadata, "rightClickUpdateText")
          onToggled: isChecked => {
                       checked = isChecked;
                       root.saveSettings();
                     }
          defaultValue: SettingsValue.read(root.widgetMetadata, "rightClickUpdateText")
        }
      }

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: middleClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.custom-button.middle-click-label")
          description: I18n.tr("bar.custom-button.middle-click-description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "middleClickExec")
          onTextChanged: root.saveSettings()
          defaultValue: SettingsValue.read(root.widgetMetadata, "middleClickExec")
        }

        NToggle {
          id: middleClickUpdateText
          enabled: !root.valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          checked: SettingsValue.nullishFallback(root.widgetData, root.widgetMetadata, "middleClickUpdateText")
          onToggled: isChecked => {
                       checked = isChecked;
                       root.saveSettings();
                     }
          defaultValue: SettingsValue.read(root.widgetMetadata, "middleClickUpdateText")
        }
      }

      NToggle {
        id: separateWheelToggle
        Layout.fillWidth: true
        label: I18n.tr("bar.custom-button.wheel-mode-separate-label")
        description: I18n.tr("bar.custom-button.wheel-mode-separate-description")
        property bool internalChecked: (SettingsValue.truthyOptionalFallback(root.widgetData, root.widgetMetadata, "wheelMode")) === "separate"
        checked: internalChecked
        onToggled: checked => {
                     internalChecked = checked;
                     root.saveSettings();
                   }
        defaultValue: SettingsValue.read(root.widgetMetadata, "wheelMode") === "separate"
      }

      ColumnLayout {
        Layout.fillWidth: true

        RowLayout {
          id: unifiedWheelLayout
          visible: !separateWheelToggle.checked
          spacing: Style.marginM

          NTextInput {
            id: wheelExecInput
            Layout.fillWidth: true
            label: I18n.tr("bar.custom-button.wheel-label")
            description: I18n.tr("bar.custom-button.wheel-description")
            placeholderText: I18n.tr("placeholders.enter-command")
            text: SettingsValue.truthyOptionalFallback(root.widgetData, root.widgetMetadata, "wheelExec")
            onTextChanged: root.saveSettings()
            defaultValue: SettingsValue.read(root.widgetMetadata, "wheelExec")
          }

          NToggle {
            id: wheelUpdateText
            enabled: !root.valueTextStream
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.bottomMargin: Style.marginS
            checked: SettingsValue.nullishOptionalFallback(root.widgetData, root.widgetMetadata, "wheelUpdateText")
            onToggled: isChecked => {
                         checked = isChecked;
                         root.saveSettings();
                       }
            defaultValue: SettingsValue.read(root.widgetMetadata, "wheelUpdateText")
          }
        }

        ColumnLayout {
          id: separatedWheelLayout
          Layout.fillWidth: true
          visible: separateWheelToggle.checked

          RowLayout {
            spacing: Style.marginM

            NTextInput {
              id: wheelUpExecInput
              Layout.fillWidth: true
              label: I18n.tr("bar.custom-button.wheel-up-label")
              description: I18n.tr("bar.custom-button.wheel-up-description")
              placeholderText: I18n.tr("placeholders.enter-command")
              text: SettingsValue.truthyOptionalFallback(root.widgetData, root.widgetMetadata, "wheelUpExec")
              onTextChanged: root.saveSettings()
              defaultValue: SettingsValue.read(root.widgetMetadata, "wheelUpExec")
            }

            NToggle {
              id: wheelUpUpdateText
              enabled: !root.valueTextStream
              Layout.alignment: Qt.AlignRight | Qt.AlignBottom
              Layout.bottomMargin: Style.marginS
              checked: SettingsValue.nullishOptionalFallback(root.widgetData, root.widgetMetadata, "wheelUpUpdateText")
              onToggled: isChecked => {
                           checked = isChecked;
                           root.saveSettings();
                         }
              defaultValue: SettingsValue.read(root.widgetMetadata, "wheelUpUpdateText")
            }
          }

          RowLayout {
            spacing: Style.marginM

            NTextInput {
              id: wheelDownExecInput
              Layout.fillWidth: true
              label: I18n.tr("bar.custom-button.wheel-down-label")
              description: I18n.tr("bar.custom-button.wheel-down-description")
              placeholderText: I18n.tr("placeholders.enter-command")
              text: SettingsValue.truthyOptionalFallback(root.widgetData, root.widgetMetadata, "wheelDownExec")
              onTextChanged: root.saveSettings()
              defaultValue: SettingsValue.read(root.widgetMetadata, "wheelDownExec")
            }

            NToggle {
              id: wheelDownUpdateText
              enabled: !root.valueTextStream
              Layout.alignment: Qt.AlignRight | Qt.AlignBottom
              Layout.bottomMargin: Style.marginS
              checked: SettingsValue.nullishOptionalFallback(root.widgetData, root.widgetMetadata, "wheelDownUpdateText")
              onToggled: isChecked => {
                           checked = isChecked;
                           root.saveSettings();
                         }
              defaultValue: SettingsValue.read(root.widgetMetadata, "wheelDownUpdateText")
            }
          }
        }
      }
    }

    // ============ Icon Tab ============
    ColumnLayout {
      spacing: Style.marginM

      NToggle {
        id: showIconToggle
        label: I18n.tr("bar.custom-button.show-icon-label")
        description: I18n.tr("bar.custom-button.show-icon-description")
        checked: root.valueShowIcon
        onToggled: checked => {
                     root.valueShowIcon = checked;
                     root.saveSettings();
                   }
        visible: textCommandInput.text !== ""
        defaultValue: SettingsValue.read(root.widgetMetadata, "showIcon")
      }

      RowLayout {
        spacing: Style.marginM
        visible: root.valueShowIcon

        NLabel {
          label: I18n.tr("common.icon")
          description: I18n.tr("bar.custom-button.icon-description")
        }

        NIcon {
          Layout.alignment: Qt.AlignVCenter
          icon: root.valueIcon
          pointSize: Style.fontSizeXL
          visible: root.valueIcon !== ""
        }

        NButton {
          text: I18n.tr("common.browse")
          onClicked: iconPicker.open()
        }
      }

      NIconPicker {
        id: iconPicker
        initialIcon: root.valueIcon
        onIconSelected: function (iconName) {
          root.valueIcon = iconName;
          root.saveSettings();
        }
      }

      NComboBox {
        id: iconPositionComboBox
        visible: root.valueShowIcon
        label: I18n.tr("bar.custom-button.icon-position-label")
        description: I18n.tr("bar.custom-button.icon-position-description")
        model: root.barIsVertical ? [
                                 {
                                   name: I18n.tr("bar.custom-button.icon-position-top"),
                                   key: "left"
                                 },
                                 {
                                   name: I18n.tr("bar.custom-button.icon-position-bottom"),
                                   key: "right"
                                 }
                               ] : [
                                 {
                                   name: I18n.tr("bar.custom-button.icon-position-left"),
                                   key: "left"
                                 },
                                 {
                                   name: I18n.tr("bar.custom-button.icon-position-right"),
                                   key: "right"
                                 }
                               ]
        currentKey: root.valueIconPosition
        onSelected: key => {
                      root.valueIconPosition = key;
                      root.saveSettings();
                    }
        defaultValue: SettingsValue.read(root.widgetMetadata, "iconPosition")
      }

      NColorChoice {
        label: I18n.tr("common.select-icon-color")
        description: I18n.tr("bar.custom-button.icon-color-selection-description")
        currentKey: root.valueColorizeSystemIcon
        onSelected: key => {
                      root.valueColorizeSystemIcon = key;
                      root.saveSettings();
                    }
        defaultValue: SettingsValue.read(root.widgetMetadata, "colorizeSystemIcon")
      }

      NTextInput {
        Layout.fillWidth: true
        label: I18n.tr("bar.custom-button.ipc-identifier-label")
        description: I18n.tr("bar.custom-button.ipc-identifier-description")
        placeholderText: I18n.tr("placeholders.enter-ipc-identifier")
        text: root.valueIpcIdentifier
        onTextChanged: {
          root.valueIpcIdentifier = text;
          root.saveSettings();
        }
        defaultValue: SettingsValue.read(root.widgetMetadata, "ipcIdentifier")
      }
    }

    // ============ Text Tab ============
    ColumnLayout {
      spacing: Style.marginM

      NColorChoice {
        label: I18n.tr("common.select-text-color")
        description: I18n.tr("bar.custom-button.text-color-selection-description")
        currentKey: root.valueColorizeSystemText
        onSelected: key => {
                      root.valueColorizeSystemText = key;
                      root.saveSettings();
                    }
        defaultValue: SettingsValue.read(root.widgetMetadata, "colorizeSystemText")
      }

      NSpinBox {
        label: I18n.tr("bar.custom-button.max-text-length-horizontal-label")
        description: I18n.tr("bar.custom-button.max-text-length-horizontal-description")
        from: 0
        to: 100
        value: root.valueMaxTextLengthHorizontal
        onValueChanged: {
          root.valueMaxTextLengthHorizontal = value;
          root.saveSettings();
        }
        defaultValue: SettingsValue.readNested(root.widgetMetadata, "maxTextLength", "horizontal")
      }

      NSpinBox {
        label: I18n.tr("bar.custom-button.max-text-length-vertical-label")
        description: I18n.tr("bar.custom-button.max-text-length-vertical-description")
        from: 0
        to: 100
        value: root.valueMaxTextLengthVertical
        onValueChanged: {
          root.valueMaxTextLengthVertical = value;
          root.saveSettings();
        }
        defaultValue: SettingsValue.readNested(root.widgetMetadata, "maxTextLength", "vertical")
      }

      NToggle {
        id: textStreamInput
        label: I18n.tr("bar.custom-button.text-stream-label")
        description: I18n.tr("bar.custom-button.text-stream-description")
        checked: root.valueTextStream
        onToggled: checked => {
                     root.valueTextStream = checked;
                     root.saveSettings();
                   }
        defaultValue: SettingsValue.read(root.widgetMetadata, "textStream")
      }

      NToggle {
        id: parseJsonInput
        label: I18n.tr("bar.custom-button.parse-json-label")
        description: I18n.tr("bar.custom-button.parse-json-description")
        checked: root.valueParseJson
        onToggled: checked => {
                     root.valueParseJson = checked;
                     root.saveSettings();
                   }
        defaultValue: SettingsValue.read(root.widgetMetadata, "parseJson")
      }

      NTextInput {
        id: textCommandInput
        Layout.fillWidth: true
        label: I18n.tr("bar.custom-button.display-command-output-label")
        description: root.valueTextStream ? I18n.tr("bar.custom-button.display-command-output-stream-description") : I18n.tr("bar.custom-button.display-command-output-description")
        placeholderText: I18n.tr("placeholders.command-example")
        text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "textCommand")
        onTextChanged: root.saveSettings()
        defaultValue: SettingsValue.read(root.widgetMetadata, "textCommand")
      }

      NTextInput {
        id: textCollapseInput
        Layout.fillWidth: true
        visible: root.valueTextStream
        label: I18n.tr("bar.custom-button.collapse-condition-label")
        description: I18n.tr("bar.custom-button.collapse-condition-description")
        placeholderText: I18n.tr("placeholders.enter-text-to-collapse")
        text: SettingsValue.truthyFallback(root.widgetData, root.widgetMetadata, "textCollapse")
        onTextChanged: root.saveSettings()
        defaultValue: SettingsValue.read(root.widgetMetadata, "textCollapse")
      }

      NTextInput {
        id: textIntervalInput
        Layout.fillWidth: true
        visible: !root.valueTextStream
        label: I18n.tr("bar.custom-button.refresh-interval-label")
        description: I18n.tr("bar.custom-button.refresh-interval-description")
        placeholderText: String(SettingsValue.read(root.widgetMetadata, "textIntervalMs"))
        text: SettingsValue.stringWhenDefined(root.widgetData, "textIntervalMs")
        onTextChanged: root.saveSettings()
        defaultValue: String(SettingsValue.read(root.widgetMetadata, "textIntervalMs"))
      }

      NComboBox {
        id: hideModeComboBox
        label: I18n.tr("bar.custom-button.hide-mode-label")
        description: I18n.tr("bar.custom-button.hide-mode-description")
        model: [
          {
            name: I18n.tr("bar.custom-button.hide-mode-always-expanded"),
            key: "alwaysExpanded"
          },
          {
            name: I18n.tr("bar.custom-button.hide-mode-expand-with-output"),
            key: "expandWithOutput"
          },
          {
            name: I18n.tr("bar.custom-button.hide-mode-max-transparent"),
            key: "maxTransparent"
          }
        ]
        currentKey: root.valueHideMode
        onSelected: key => {
                      root.valueHideMode = key;
                      root.saveSettings();
                    }
        visible: textCommandInput.text !== "" && root.valueTextStream == true
        defaultValue: SettingsValue.read(root.widgetMetadata, "hideMode")
      }
    }
  }
}
