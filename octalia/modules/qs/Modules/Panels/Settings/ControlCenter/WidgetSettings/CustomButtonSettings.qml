pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "CustomButtonSettings.js" as CustomButtonData
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.preferredWidth: Math.round(600 * Style.uiScaleRatio)
  implicitWidth: Layout.preferredWidth

  property var widgetData: null
  property var widgetMetadata: null
  property var rootSettings: null

  signal settingsChanged(var settings)

  QtObject {
    id: _settings

    property string icon: SettingsValue.undefinedFallback(root.widgetData, root.widgetMetadata, "icon")
    property string onClicked: SettingsValue.undefinedFallback(root.widgetData, root.widgetMetadata, "onClicked")
    property string onRightClicked: SettingsValue.undefinedFallback(root.widgetData, root.widgetMetadata, "onRightClicked")
    property string onMiddleClicked: SettingsValue.undefinedFallback(root.widgetData, root.widgetMetadata, "onMiddleClicked")
    property ListModel _stateChecksListModel: ListModel {}
    property string stateChecksJson: "[]"
    property bool enableOnStateLogic: SettingsValue.undefinedFallback(root.widgetData, root.widgetMetadata, "enableOnStateLogic")

    function populateStateChecks(): void {
      CustomButtonData.populateStateChecks(stateChecksJson, _stateChecksListModel, Logger);
    }


    Component.onCompleted: {
      root.rootSettings = _settings;
      stateChecksJson = CustomButtonData.stateChecksJson(root.widgetData, root.widgetMetadata);
      Qt.callLater(populateStateChecks);
    }

    function saveSettings(): var {
_settings.stateChecksJson = CustomButtonData.serializeStateChecks(_settings._stateChecksListModel);

      return {
        "id": SettingsValue.read(root.widgetData, "id"),
        "icon": _settings.icon,
        "onClicked": _settings.onClicked,
        "onRightClicked": _settings.onRightClicked,
        "onMiddleClicked": _settings.onMiddleClicked,
        "stateChecksJson": _settings.stateChecksJson,
        "enableOnStateLogic": _settings.enableOnStateLogic
      };
    }
  }

  function saveSettings(): var {
    return _settings.saveSettings();
  }

  function updateStateCheck(index: int, command: string, icon: string): void {
    CustomButtonData.updateStateCheck(_settings._stateChecksListModel, index, command, icon);
    _settings.saveSettings();
  }

  function removeStateCheck(index: int): void {
    CustomButtonData.removeStateCheck(_settings._stateChecksListModel, index);
    _settings.saveSettings();
  }

  function addStateCheck(): void {
    CustomButtonData.addStateCheck(_settings._stateChecksListModel);
    _settings.saveSettings();
  }

  RowLayout {
    spacing: Style?.marginM ?? 8

    NLabel {
      label: I18n.tr("common.icon")
      description: I18n.tr("panels.control-center.shortcuts-custom-button-icon-description")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: _settings.icon || (SettingsValue.read(root.widgetMetadata, "icon") ? SettingsValue.read(root.widgetMetadata, "icon") : "")
      pointSize: Style?.fontSizeXL ?? 24
      visible: (_settings.icon || (SettingsValue.read(root.widgetMetadata, "icon") ? SettingsValue.read(root.widgetMetadata, "icon") : "")) !== ""
    }

    NButton {
      text: I18n.tr("common.browse")
      onClicked: iconPicker.open()
    }
  }

  NIconPicker {
    id: iconPicker
    initialIcon: _settings.icon
    onIconSelected: function (iconName) {
      _settings.icon = iconName;
      root.saveSettings();
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: I18n.tr("bar.custom-button.left-click-label")
    description: I18n.tr("bar.custom-button.left-click-description")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: _settings.onClicked
    onTextChanged: {
      _settings.onClicked = text;
      root.saveSettings();
    }
    defaultValue: SettingsValue.read(root.widgetMetadata, "onClicked")
  }

  NTextInput {
    Layout.fillWidth: true
    label: I18n.tr("bar.custom-button.right-click-label")
    description: I18n.tr("bar.custom-button.right-click-description")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: _settings.onRightClicked
    onTextChanged: {
      _settings.onRightClicked = text;
      root.saveSettings();
    }
    defaultValue: SettingsValue.read(root.widgetMetadata, "onRightClicked")
  }

  NTextInput {
    Layout.fillWidth: true
    label: I18n.tr("bar.custom-button.middle-click-label")
    description: I18n.tr("bar.custom-button.middle-click-description")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: _settings.onMiddleClicked
    onTextChanged: {
      _settings.onMiddleClicked = text;
      root.saveSettings();
    }
    defaultValue: SettingsValue.read(root.widgetMetadata, "onMiddleClicked")
  }

  NDivider {}

  NToggle {
    id: enableOnStateLogicToggle
    Layout.fillWidth: true
    label: I18n.tr("panels.control-center.shortcuts-custom-button-enable-on-state-logic-label")
    description: I18n.tr("panels.control-center.shortcuts-custom-button-enable-on-state-logic-description")
    checked: _settings.enableOnStateLogic
    onToggled: checked => {
                 _settings.enableOnStateLogic = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "enableOnStateLogic")
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.rootSettings && SettingsValue.read(root.rootSettings, "enableOnStateLogic")
    spacing: Style?.marginM ?? 8

    NLabel {
      label: I18n.tr("panels.control-center.shortcuts-custom-button-state-checks-label")
    }

    Repeater {
      model: root.rootSettings ? SettingsValue.read(root.rootSettings, "_stateChecksListModel") : null
      delegate: Item {
        id: stateCheck
        required property int index
        required property string command
        required property string icon
        property int currentIndex: stateCheck.index

        implicitHeight: contentRow.implicitHeight
        Layout.fillWidth: true

        RowLayout {
          id: contentRow
          anchors.fill: parent
          spacing: Style?.marginM ?? 8

          NTextInput {
            Layout.fillWidth: true
            placeholderText: I18n.tr("panels.control-center.shortcuts-custom-button-state-checks-command")
            text: stateCheck.command
            onTextChanged: {
              root.updateStateCheck(stateCheck.currentIndex, text, stateCheck.icon);
            }
          }

          RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Style?.marginS ?? 4

            NIcon {
              icon: stateCheck.icon
              pointSize: Style?.fontSizeL ?? 20
              visible: stateCheck.icon !== undefined && stateCheck.icon !== ""
            }

            NIconButton {
              icon: "folder"
              baseSize: SettingsValue.valueOrDefault(Style, "buttonSizeS", 24)
              onClicked: iconPickerDelegate.open()
            }

            NIconButton {
              icon: "close"
              baseSize: SettingsValue.valueOrDefault(Style, "buttonSizeS", 24)
              colorBorder: Qt.alpha(Color.mOutline, Style.opacityLight)
              colorBg: Color.mError
              colorFg: Color.mOnError
              colorBgHover: Qt.alpha(Color.mError, Style.opacityMedium)
              colorFgHover: Color.mOnError
              onClicked: {
                root.removeStateCheck(stateCheck.currentIndex);
              }
            }
          }
        }

        NIconPicker {
          id: iconPickerDelegate
          initialIcon: stateCheck.icon
          onIconSelected: function (iconName) {
            root.updateStateCheck(stateCheck.currentIndex, stateCheck.command, iconName);
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style?.marginM ?? 8

      NButton {
        text: I18n.tr("panels.control-center.shortcuts-custom-button-state-checks-add")
        onClicked: root.addStateCheck()
      }
    }
  }
}
