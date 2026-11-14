pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  // Local state
  property var localBlacklist: SettingsValue.read(widgetData, "blacklist") || []
  property bool valueColorizeIcons: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "colorizeIcons")
  property string valueChevronColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "chevronColor")
  property bool valueDrawerEnabled: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "drawerEnabled")
  property bool valueHidePassive: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hidePassive")

  ListModel {
    id: blacklistModel
  }

  function populateBlacklist(): void {
    SettingsValue.populateModel(localBlacklist, blacklistModel);
  }

  Component.onCompleted: {
    Qt.callLater(populateBlacklist);
  }

  spacing: Style.marginM

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.tray.drawer-enabled-label")
    description: I18n.tr("bar.tray.drawer-enabled-description")
    checked: root.valueDrawerEnabled
    onToggled: checked => {
                 root.valueDrawerEnabled = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "drawerEnabled")
  }

  NColorChoice {
    label: I18n.tr("bar.tray.chevron-color-label")
    description: I18n.tr("bar.tray.chevron-color-description")
    currentKey: root.valueChevronColor
    onSelected: key => {
                  root.valueChevronColor = key;
                  root.saveSettings();
                }
    visible: root.valueDrawerEnabled
    defaultValue: SettingsValue.read(root.widgetMetadata, "chevronColor")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.tray.colorize-icons-label")
    description: I18n.tr("bar.tray.colorize-icons-description")
    checked: root.valueColorizeIcons
    onToggled: checked => {
                 root.valueColorizeIcons = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "colorizeIcons")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.tray.hide-passive-label")
    description: I18n.tr("bar.tray.hide-passive-description")
    checked: root.valueHidePassive
    onToggled: checked => {
                 root.valueHidePassive = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hidePassive")
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: I18n.tr("panels.bar.tray-blacklist-label")
      description: I18n.tr("panels.bar.tray-blacklist-description")
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInputButton {
        id: newRuleInput
        Layout.fillWidth: true
        placeholderText: I18n.tr("panels.bar.tray-blacklist-placeholder")
        buttonIcon: "add"
        onButtonClicked: {
          var exists, i, newRule;
          if (newRuleInput.text.length > 0) {
            newRule = newRuleInput.text.trim();
            exists = false;
            for (i = 0; i < blacklistModel.count; i++) {
              if (blacklistModel.get(i).rule === newRule) {
                exists = true;
                break;
              }
            }
            if (!exists) {
              blacklistModel.append({
                                      "rule": newRule
                                    });
              newRuleInput.text = "";
              root.saveSettings();
            }
          }
        }
      }
    }
  }

  // List of current blacklist items
  NListView {
    id: blacklistView
    Layout.fillWidth: true
    Layout.preferredHeight: 150
    Layout.topMargin: Style.marginL // Increased top margin
    gradientColor: Color.mSurface

    model: blacklistModel
    delegate: Item {
      id: blacklistItem
      required property int index
      required property string rule
      width: blacklistView.width
      height: 40

      Rectangle {
        id: itemBackground
        anchors.fill: parent
        anchors.margins: Style.marginXS
        color: "transparent" // Make background transparent
        border.color: Color.mOutline
        border.width: Style.borderS
        radius: Style.radiusS
        visible: blacklistItem.rule !== undefined && blacklistItem.rule !== "" // Only visible if rule exists
      }

      Row {
        anchors.fill: parent
        anchors.leftMargin: Style.marginS
        anchors.rightMargin: Style.marginS
        spacing: Style.marginS

        NText {
          anchors.verticalCenter: parent.verticalCenter
          text: blacklistItem.rule
          elide: Text.ElideRight
        }

        NIconButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "close"
          baseSize: 12 * Style.uiScaleRatio
          colorBg: Color.mSurfaceVariant
          colorFg: Color.mOnSurfaceVariant
          colorBgHover: Color.mError
          colorFgHover: Color.mOnError
          onClicked: {
            blacklistModel.remove(blacklistItem.index);
            root.saveSettings();
          }
        }
      }
    }
  }

  // This function will be called by the dialog to get the new settings
  function saveSettings() {
    var i;
    var newBlacklist = [];
    for (i = 0; i < blacklistModel.count; i++) {
      newBlacklist.push(blacklistModel.get(i).rule);
    }

    // Return the updated settings for this widget instance
    var settings = Object.assign({}, widgetData || {});
    settings.blacklist = newBlacklist;
    settings.colorizeIcons = root.valueColorizeIcons;
    settings.chevronColor = root.valueChevronColor;
    settings.drawerEnabled = root.valueDrawerEnabled;
    settings.hidePassive = root.valueHidePassive;
    settingsChanged(settings);
  }
}
